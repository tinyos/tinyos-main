/* Copyright (c) 2011 People Power Co.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the People Power Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * PEOPLE POWER CO. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 *
 */

module DefaultHdlcUartP {
  provides {
    interface StdControl;
    interface HdlcUart;
#if DEBUG_PLATFORM_SERIAL_HDLC_UART
    interface DebugDefaultHdlcUart;
#endif /* DEBUG_PLATFORM_SERIAL_HDLC_UART */
  }
  uses {
    interface StdControl as SerialControl;
    interface UartStream;
#if PLATFORM_SURF
    interface Msp430UsciError;
#endif
  }
} implementation {

#ifndef PLATFORM_SERIAL_RX_BUFFER_SIZE
/** Number of bytes in the ring buffer of received but unprocessed
 * characters. */
#define PLATFORM_SERIAL_RX_BUFFER_SIZE 256
#endif /* PLATFORM_SERIAL_RX_BUFFER_SIZE */

  /** Circular buffer holding received data not yet processed.
   *
   * To simplify management, the buffer is considered empty if the
   * rbStore_ and rbLoad_ pointers are equal.
   *
   * If reception of a character increments rbStore_ to be equal to
   * rbLoad_, a buffer overflow is assumed, and incoming data is
   * dropped until the feeder task catches up. */
  uint8_t ringBuffer[PLATFORM_SERIAL_RX_BUFFER_SIZE];

  /** Pointer to the ring buffer slot into which the next received
   * character will be written.
   *
   * When rbStore_ is null reception is administratively disabled. */
  uint8_t *rbStore_;

  /** Pointer to the ring buffer slot containing oldest received
   * character not yet processed.
   *
   * The slot indicated by rbLoad_ contains an unprocessed character
   * only when the rbLoad_ pointer is non-null and unequal to
   * rbStore_.
   *
   * When rbLoad_ is null reception has been disabled due to ring
   * buffer overrun or an underlying UART error.  Such errors inhibit
   * further reception, and are sticky until the streamFeeder task
   * clears them.
   */
  uint8_t *rbLoad_;

#if DEBUG_PLATFORM_SERIAL_HDLC_UART
  async command unsigned int DebugDefaultHdlcUart.ringBufferLength () { return sizeof(ringBuffer); }
  async command uint8_t* DebugDefaultHdlcUart.ringBuffer () { return ringBuffer; }
  async command uint8_t* DebugDefaultHdlcUart.rbStore () { atomic return rbStore_; }
  async command uint8_t* DebugDefaultHdlcUart.rbLoad () { atomic return rbLoad_; }
#endif /* DEBUG_PLATFORM_SERIAL_HDLC_UART */

  command error_t StdControl.start ()
  {
    /* Ignore the return value; if SerialPrintfC is active, it might
     * fail but things are still good. */
    (void)call SerialControl.start();
    atomic rbStore_ = rbLoad_ = ringBuffer;
    return SUCCESS;
  }

  command error_t StdControl.stop ()
  {
    atomic rbStore_ = rbLoad_ = 0;
    return call SerialControl.stop();
  }

  command error_t HdlcUart.send (uint8_t* buf,
				 uint16_t len)
  {
    return call UartStream.send(buf, len);
  }
  
  async event void UartStream.sendDone( uint8_t* buf, uint16_t len, error_t error )
  {
    signal HdlcUart.sendDone(error);
  }

  task void streamFeeder_task ()
  {
    uint8_t* loadable_endp;
    uint8_t* loadablep = 0;
    uint8_t* new_load = 0;
    bool signal_recovery = FALSE;
    
    atomic {
      if (! rbStore_) {
	/* Infrastructure disabled */
	return;
      }
      if (! rbLoad_) {
	/* Buffer overrun or UART error.  Throw away anything we
	 * haven't processed and signal recovery. */
	signal_recovery = TRUE;
	rbLoad_ = rbStore_;
      } else {
	/* Might have something.  Grab whatever contiguous region of
	 * unprocessed characters is available.  Cache where we
	 * stopped, to use to update rbLoad_ after we're done
	 * processing.
	 *
	 * @TODO: Consider putting an upper bound on the number of
	 * characters processed, to let the HDLC infrastructure post
	 * other tasks that might relieve frame buffer memory
	 * pressure. */
	loadablep = rbLoad_;
	if (rbLoad_ <= rbStore_) {
	  loadable_endp = rbStore_;
	  new_load = rbStore_;
	} else {
	  loadable_endp = ringBuffer + sizeof(ringBuffer);
	  new_load = ringBuffer;
	}
      }
    } /* atomic */

    if (loadablep && (loadablep < loadable_endp)) {
      /* There's characters to be processed, but we might not have
       * grabbed them all.  Post the task again so any leftovers can
       * be processed. */
      post streamFeeder_task();
      
      /* Notify of each received character, in order */
      while (loadablep < loadable_endp) {
	signal HdlcUart.receivedByte(*loadablep++);
      }
      atomic {
	/* Consume the characters we've just processed, unless the
	 * ring buffer overran while we were working, in which case
	 * keep the error marker and we'll resync on the next
	 * invocation. */
	if (rbLoad_) {
	  rbLoad_ = new_load;
	}
      }
    }

    if (signal_recovery) {
      signal HdlcUart.uartError(SUCCESS);
    }
  }

  async event void UartStream.receivedByte (uint8_t rx_byte)
  {
    bool wake_feeder;
    bool signal_drop;

    atomic {
      /* Signal loss of data if we were supposed to store data but
       * couldn't because of an existing or new overflow or error
       * condition.  (Here assume we'll fail to store; we'll clear the
       * signal if we do store the data.)
       *
       * Wake the feeder if we're supposed to store data.  If we do
       * store, it'll have work to do; if we don't, there's an error
       * condition it needs to clean up.
       */
      wake_feeder = signal_drop = !!rbStore_;
      if (rbStore_ && rbLoad_) {
	uint8_t* rb_dest = rbStore_;
	if (++rbStore_ >= (ringBuffer + sizeof(ringBuffer))) {
	  rbStore_ = ringBuffer;
	}
	if (rbStore_ == rbLoad_) {
	  /* Store would cause an overrun.  Leave the old value in
	   * place, in case it's being processed, but mark an
	   * error. */
	  rbLoad_ = 0;
	} else {
	  /* Store is valid.  Do so, and clear the drop signal. */
	  *rb_dest = rx_byte;
	  signal_drop = FALSE;
	}
      }
    }
    if (wake_feeder) {
      post streamFeeder_task();
    }
    if (signal_drop) {
      signal HdlcUart.uartError(ENOMEM);
    }
  }

  async event void UartStream.receiveDone( uint8_t* buf, uint16_t len, error_t error ) { }

#if PLATFORM_SURF
  async event void Msp430UsciError.condition (unsigned int errors)
  {
    /* On any underlying UART error, mark the error to inhibit
     * reception until we can do cleanup, notify the consumer, and
     * wake the stream feeder task to recover. */
    atomic {
      rbLoad_ = 0;
    }
    signal HdlcUart.uartError(FAIL);
    post streamFeeder_task();
  }
#endif

  default async event void HdlcUart.uartError (error_t error) { }

}
