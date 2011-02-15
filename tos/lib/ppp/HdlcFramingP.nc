/* Copyright (c) 2010 People Power Co.
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

#include "HdlcFraming.h"

/** Implement HDLC framing.
 *
 * @param RX_FRAME_LIMIT The maximum number of frames that can be held
 * waiting for the receiver to process them. */
generic module HdlcFramingP (uint8_t RX_FRAME_LIMIT) {
  uses {
    interface HdlcUart;
    interface StdControl as UartControl;
    interface FragmentPool as InputFramePool;
  }
  provides {
    interface Init;
    interface StdControl;
    interface HdlcFraming;
    interface GetSetOptions<HdlcFramingOptions_t> as HdlcFramingOptions;
#if DEBUG_HDLC_FRAMING
    interface DebugHdlcFraming;
#endif /* DEBUG_HDLC_FRAMING */
  }
} implementation {

#include "HdlcFraming_.h"

  uint16_t txCount__;
  uint16_t rxCount__;

  command error_t Init.init ()
  {
    return SUCCESS;
  }

  /** Options that control the behavior of the framing.  Access must
   * be atomic; this is read within the receive interrupt routines,
   * but may be updated from synchronous context. */
  HdlcFramingOptions_t options__ = { txSuppressAddressControl: FALSE,
                                     rxSuppressAddressControl: FALSE,
                                     txAsyncControlCharacterMap: ~0UL,
                                     rxAsyncControlCharacterMap: ~0UL };

  /** The current state of the reception machine */
  uint8_t rxState__;
  /** The state to which the reception machine should return upon
   * receipt of an escaped data byte.  Only valid when state is
   * RX_escaped. */
  uint8_t rxEscapedState_;

  /** Where the caller wants us to put the next frame.  Set to null on
   * startup and upon completion of frame reception.  Reset to a
   * non-null value by HdlcFraming.setReceiveBuffer. */
  uint8_t* rxBuffer__;
  /** The number of octets available for an incoming frame */
  int rxBufferLength__;
  /** An index into the current rxBuffer__ at which the next frame
   * character is to be written. */
  int rxIndex__;

  uint8_t txState_;

  /** A buffer for outgoing data.  This is used for escape sequence
   * constructed from control characters in an outgoing buffer, so
   * must be at least two octets in length.  It also must be long enough to store:
   *  - the flag sequence (1 octet)
   *  - the address field (1 octet)
   *  - the control field (2 octets, if escaped)
   * on transmission start, and:
   *  - the CRC field (4 octets, if both bytes escaped)
   *  - the flag sequence (1 octet)
   * on transmission end.  We'll use twice the CRC length plus the flag sequence. */
  uint8_t txTemporary_[2 * FCS_LENGTH + 1];

  /** A pointer to the start of a frame being transmitted.  Is null
   * when there is no active frame transmission. */
  const uint8_t* txStart_;
  /** A pointer to the next character to transmit from in txStart_.
   * Valid only while txStart_ is not null.  When equal to txEnd_, the
   * payload portion of the frame has been transmitted, though
   * transmission of the CRC may still be active. */
  const uint8_t* txPtr_;
  /** A pointer to just past the end of the frame to be transmitted.
   * Valid only while txStart_ is not null. */
  const uint8_t* txEnd_;

  /** Cached result from most recent HdlcUart.sendDone event, used
   * for task handoff.   Access under mutex. */
  error_t sendDoneError__;

  /** A set of reception frames permitting simultaneous reception of a
   * PPP frame and processing of a previously received frame. */
  HdlcRxFrame_t rxFrames_[RX_FRAME_LIMIT];
  static const HdlcRxFrame_t* rxFramesEnd_ = rxFrames_ + RX_FRAME_LIMIT;

  /** Points to the rxFrame_ that is currently being used to receive
   * data.  Null if no input buffer is currently available. */
  HdlcRxFrame_t* rxActiveFrame__;

  /** A queue of frames that have received data, in the order they are
   * to be worked off. */
  HdlcRxFrame_t* readyFrame__[RX_FRAME_LIMIT];
  uint8_t readyFrameIdx__;

  task void inputEngine_task ();

  /** Update a HDLC default CRC with a new data byte.  
   *
   * Although both TinyOS and HDLC/PPP use the same CRC polynomial,
   * they shift from different ends or something; at any rate, the
   * standard implementation doesn't work.  Found this one which does
   * at
   * http://www.nongnu.org/avr-libc/user-manual/group__util__crc.html. */
  uint16_t fcs16_update (uint16_t crc, uint8_t data)
  {
    data ^= 0xff & crc;
    data ^= data << 4;
    return ((((uint16_t)data << 8) | (0xff & (crc >> 8)))
            ^ (uint8_t)(data >> 4) 
            ^ ((uint16_t)data << 3));
  }

  enum {
    /** The initial value for the CRC algorithm */
    FCS16_Initial = 0xFFFF,
    /** The expected value when calculating a CRC over a frame which
     * ends with an encoded CRC. */
    FCS16_Good = 0xF0B8,
  };
  /** The running CRC for a frame being received. */
  uint16_t rxCrc__;
  /** The running CRC for a frame being transmitted. */
  uint16_t txCrc_;
  
  /** Return TRUE iff character c must be escaped given this ACCM */
  bool mustEscape (uint8_t c, uint32_t accm)
  {
    return ((HDLC_FlagSequence == c)
            || (HDLC_ControlEscape == c)
            || ((0x20 > c) && (accm & (1UL << c))));
  }

  command error_t HdlcFramingOptions.set (const HdlcFramingOptions_t* new_options)
  {
    atomic {
      if (new_options) {
        options__ = *new_options;
      } else {
        options__.txSuppressAddressControl = options__.rxSuppressAddressControl = FALSE;
        options__.txAsyncControlCharacterMap = options__.rxAsyncControlCharacterMap = ~0UL;
      }
    }
#if 0
    printf("HDLC Opt: ACCOMP tx=%d rx=%d; ACCM tx=%08lx rx=%08lx\r\n",
           options__.txSuppressAddressControl, options__.rxSuppressAddressControl,
           options__.txAsyncControlCharacterMap, options__.rxAsyncControlCharacterMap);
#endif
    return SUCCESS;
  }

  command HdlcFramingOptions_t HdlcFramingOptions.get () { atomic return options__; }

  command error_t HdlcFraming.sendFrame (const uint8_t* data,
                                         unsigned int len,
                                         bool inhibit_accomp)
  {
    error_t rc;
    uint8_t* tp;

    if (TX_idle != txState_) {
      return EBUSY;
    }

    txState_ = TX_active;
    txCrc_ = FCS16_Initial;
    txStart_ = txPtr_ = data;
    txEnd_ = txStart_ + len;
    tp = txTemporary_;
    *tp++ = HDLC_FlagSequence;
    if (inhibit_accomp || (! options__.txSuppressAddressControl)) {
      txCrc_ = fcs16_update(txCrc_, HDLC_AllStationsAddress);
      txCrc_ = fcs16_update(txCrc_, HDLC_ControlFieldValue);
      *tp++ = HDLC_AllStationsAddress;
      if (mustEscape(HDLC_ControlFieldValue, options__.txAsyncControlCharacterMap)) {
        *tp++ = HDLC_ControlEscape;
        *tp++ = HDLC_ControlFieldValue ^ HDLC_ControlModifier;
      } else {
        *tp++ = HDLC_ControlFieldValue;
      }
    }
    rc = call HdlcUart.send(txTemporary_, tp - txTemporary_);
    if (SUCCESS != rc) {
      txState_ = TX_idle;
    }
    return rc;
  }

  error_t startNewFrame_async__ ()
  {
    error_t rc;
    HdlcRxFrame_t* fp;

    /* Find an open frame */
    fp = rxFrames_;
    while ((fp < rxFramesEnd_) && (RFS_unused != fp->frame_state)) {
      ++fp;
    }
    if (rxFramesEnd_ <= fp) {
      return ENOMEM;
    }

    /* Get a fragment, if any */
    rc = call InputFramePool.request(&fp->start, &fp->end, MinimumUsefulBufferLength);
    if (SUCCESS != rc) {
      return rc;
    }

    rxBuffer__ = fp->start;
    rxBufferLength__ = fp->end - fp->start;
    rxActiveFrame__ = fp;
    rxActiveFrame__->frame_state = RFS_receiving;
    return SUCCESS;
  }

  /* We don't need to do anything when space becomes available in the
   * input pool.  Only inputEngine_task causes changes to the input
   * pool, and it knows that it's done so. */
  async event void InputFramePool.available (unsigned int length)
  {
    atomic {
      if (! rxActiveFrame__) {
        startNewFrame_async__();
      }
    }
  }

  void completeFrame_async__ ()
  {
    HdlcRxFrame_t* fp = rxActiveFrame__;
    uint8_t* fpe;

    /* Graduate the frame to "received", set its length, and notify
     * the engine. */
    fp->frame_state = RFS_received;
    fp->end = fp->start + rxIndex__ - FCS_LENGTH;
    post inputEngine_task();

    /* Stuff the active frame on the ready queue */
    readyFrame__[readyFrameIdx__++] = rxActiveFrame__;

    /* Mark that we have no active input buffer. */
    rxActiveFrame__ = 0;
    rxBuffer__ = 0;

    /* Freeze the payload of the frame.  Note that if the frame has no
     * data, we want to pretend it has at least one octet in it,
     * otherwise we're likely to get the same address for the next
     * frame confusing the bookkeeping.
     *
     * During the freeze call, the InputFramePool.available() event
     * will be signalled, which will cause us to be assigned a new
     * buffer if the pool has space for another frame. */
    fpe = fp->end;
    if (fp->start == fpe) {
      ++fpe;
    }
    (void)call InputFramePool.freeze(fp->start, fpe);
  }

  command error_t HdlcFraming.releaseReceivedFrame (const uint8_t* buffer)
  {
    HdlcRxFrame_t* fp = rxFrames_;

    /* Find the frame data for the input buffer */
    atomic {
      while ((fp < rxFramesEnd_) && (fp->start != buffer)) {
        ++fp;
      }
      if (fp >= rxFramesEnd_) {
        return EINVAL;
      }
      fp->frame_state = RFS_releasable;
    }
    post inputEngine_task();
    return SUCCESS;
  }

  task void inputEngine_task ()
  {
    bool did_something = FALSE;
    uint8_t* releasable_fragment = 0;
    const uint8_t* frame_start = 0;
    unsigned int frame_length = 0;
    
    atomic {
      HdlcRxFrame_t* fp;
      
      if (0 < readyFrameIdx__) {
        fp = readyFrame__[0];
        if (0 < --readyFrameIdx__) {
          memmove(readyFrame__, readyFrame__ + 1, readyFrameIdx__ * sizeof(*readyFrame__));
        }
        fp->frame_state = RFS_processing;
        frame_start = fp->start;
        frame_length = fp->end - fp->start;
      } else {
        fp = rxFrames_;
        while (fp < rxFramesEnd_) {
          if (RFS_releasable == fp->frame_state) {
            releasable_fragment = fp->start;
            fp->frame_state = RFS_unused;
            fp->start = fp->end = 0;
            break;
          }
          ++fp;
        }
      }
    }

    if (frame_start) {
      signal HdlcFraming.receivedFrame(frame_start, frame_length);
      did_something = TRUE;
    }
    
    if (releasable_fragment) {
      (void)call InputFramePool.release(releasable_fragment);
      did_something = TRUE;
    }

    if (did_something) {
      post inputEngine_task();
    }
  }

  event void HdlcUart.receivedByte (uint8_t byte)
  {
    uint8_t in_byte = byte;
    int rx_error = HdlcError_None;
    bool post_rx_delim = FALSE;
    
    /* @note This event runs in interrupt context */
    
    atomic {
      /* Characters in the ACCM are to be silently dropped. */
      if ((0x20 > byte) && (options__.rxAsyncControlCharacterMap & (1UL << byte))) {
        return;
      }

      /* If we've been waiting for a byte that had to be modified for
       * transparency, convert it. */
      if (RX_escaped == rxState__) {
        if ((HDLC_FlagSequence == byte) || (HDLC_ControlEscape == byte)) {
          /* These characters are not valid in escaped state.  Go
           * unsynchronized, but process the byte in that state so we
           * can resync if necessary. */
          rxState__ = RX_unsynchronized;
        } else {
          /* Unescape the byte and drop back to the unescaped state
           * for processing. */
          byte ^= HDLC_ControlModifier;
          rxState__ = rxEscapedState_;
        }
      }
      if ((RX_unsynchronized != rxState__) && (HDLC_ControlEscape == in_byte)) {
        /* We're synchronized and the next byte had to be escaped, so
         * prepare for it, saving the current state so we can return
         * to it. */
        rxEscapedState_ = rxState__;
        rxState__ = RX_escaped;
      } else {
        /* Process the byte. */
        switch (rxState__) {
          default:
          reprocess_unsynchronized:
            rxState__ = RX_unsynchronized;
            /*FALLTHRU*/
          case RX_unsynchronized:
            /* If we're not synchronized, we have no valid data.  Clear the index
             * so we can safely update the receive buffer. */
            rxIndex__ = 0;
            rxCrc__ = FCS16_Initial;
            /* The only way to get out of the unsynchronized state is to
             * receive a flag sequence, which starts a new receive
             * operation.  Note we check the unconverted byte. */
            if (HDLC_FlagSequence == in_byte) {
              rxState__ = RX_atAddress;
              post_rx_delim = TRUE;
            }
            break;
          case RX_atAddress:
            if (HDLC_FlagSequence == in_byte) {
              /* Never mind: not starting yet after all */
              goto reprocess_unsynchronized;
            }
            if (HDLC_AllStationsAddress != byte) {
              /* If accomp is enabled, it's ok to not get the address;
               * in that case jump straight to receive.  (It's also ok
               * to get the address, which is why we didn't skip over
               * this state.  If we did, though, we must also get the
               * control field. */
#if 0
              /* Technically, we shouldn't get here if the other side
               * hasn't agreed to compress address and control fields.
               * @TODO@ This is temporarily disabled since we don't set
               * the local options yet. */
              if (! options__.rxSuppressAddressControl) {
                rx_error = HdlcError_InvalidAddressField;
                goto reprocess_unsynchronized;
              }
#endif
              rxState__ = RX_receive;
              goto receive;
            }
            rxCrc__ = fcs16_update(rxCrc__, byte);
            rxState__ = RX_atControlField;
            break;
          case RX_atControlField:
            /* If we got to this state, we have to match the control
             * field, or resynchronize. */
            if (HDLC_ControlFieldValue != byte) {
              if (HDLC_FlagSequence != in_byte) {
                rx_error = HdlcError_InvalidControlField;
              }
              goto reprocess_unsynchronized;
            }
            rxCrc__ = fcs16_update(rxCrc__, byte);
            rxState__ = RX_receive;
            break;
          case RX_receive:
          receive:
            if (HDLC_FlagSequence == in_byte) {
              /* Probable end of the frame.  If the content is long enough to be valid,
               * check the CRC and push the frame upstream if it's valid */
              if (FCS_LENGTH <= rxIndex__) {
                if (FCS16_Good == rxCrc__) {
                  completeFrame_async__();
                } else {
                  rx_error = HdlcError_BadCrc;
                }
              } else {
                rx_error = HdlcError_ShortFrame;
              }
              /* Reprocess the character to resynchronize */
              goto reprocess_unsynchronized;
            }

            /* Valid decoded character.  If there's a buffer with
             * available room, update the CRC and store it.
             * Otherwise, abort the reception. */
            if (rxBuffer__) {
              if (rxIndex__ < rxBufferLength__) {
                rxCrc__ = fcs16_update(rxCrc__, byte);
                rxBuffer__[rxIndex__++] = byte;
              } else {
                rx_error = HdlcError_BufferOverflow;
              }
            } else {
              rx_error = HdlcError_NoBufferAvailable;
            }
            if (HdlcError_None != rx_error) {
              rxState__ = RX_unsynchronized;
            }
            break;
          case RX_escaped:
            /*NOTREACHED*/
            break;
        }
      }
    } // atomic

    /* Error notifications first */
    if (HdlcError_None != rx_error) {
      signal HdlcFraming.receptionError(rx_error);
    }
    /* Delimiter reception after errors but before frame completion */
    if (post_rx_delim) {
      signal HdlcFraming.receivedDelimiter();
    }
  }

  /* To avoid loss of incoming data during full duplex communications,
   * we need to prepare for the next transmission block in a task that
   * does not run in the interrupt context in which we're notified of
   * completion of the previous transmission. */
  task void uartStreamSendDone ()
  {
    error_t error;
    const uint8_t* tp = txPtr_;
    const uint8_t* uart_tx_ptr = 0;
    uint8_t next_state;
    unsigned int uart_tx_len = 0;
    bool send_done = FALSE;
    uint32_t tx_accm;

    atomic {
      error = sendDoneError__;
      tx_accm = options__.txAsyncControlCharacterMap;
    }
    next_state = txState_;
    send_done = ((SUCCESS == error) && (TX_sendCrc == txState_));

    if (! send_done) {
      if (SUCCESS == error) {
        /* The last operation succeeded, so start the next one.
         * Beginning where we left off, look for an outbound character
         * that needs to be escaped. */
        while ((tp < txEnd_) && (! mustEscape(*tp, tx_accm))) {
          ++tp;
        }
        if ((tp == txPtr_) && (txPtr_ < txEnd_)) {
          /* There are characters to transmit, and the first one has to
           * be escaped.  Add it to the CRC, escape it, and send it on
           * its way. */
          uint8_t* bp = txTemporary_;
          txCrc_ = fcs16_update(txCrc_, *txPtr_);
          *bp++ = HDLC_ControlEscape;
          *bp++ = HDLC_ControlModifier ^ *txPtr_;
          uart_tx_ptr = txTemporary_;
          uart_tx_len = bp - txTemporary_;
          ++txPtr_;
        } else if (txPtr_ < txEnd_) {
          /* There are unescaped characters to be sent.  Send them, then
           * add them to the CRC.  Note need to remove const qualifier
           * from transmit buffer to satisfy the TinyOS interface
           * definition: one hopes nobody's implementation actually
           * mucks with the content. */
          uart_tx_ptr = txPtr_;
          uart_tx_len = tp - txPtr_;
          while (txPtr_ < tp) {
            txCrc_ = fcs16_update(txCrc_, *txPtr_++);
          }
        } else {
          uint8_t shift = 0;
          uint8_t* bp = txTemporary_;
          
          /* All frame characters have been sent.  Pack up the CRC to
           * follow: xor with initial, low byte first, escaping the
           * bytes as necessary. */
          next_state = TX_sendCrc;
          txCrc_ = txCrc_ ^ FCS16_Initial;
          while (16 > shift) {
            uint8_t crcb = (txCrc_ >> shift) & 0xff;
            if (mustEscape(crcb, tx_accm)) {
              *bp++ = HDLC_ControlEscape;
              *bp++ = crcb ^ HDLC_ControlModifier;
            } else {
              *bp++ = crcb;
            }
            shift += 8;
          }
          /* Tack on the closing flag sequence. */
          *bp++ = HDLC_FlagSequence;
          uart_tx_ptr = txTemporary_;
          uart_tx_len = bp - txTemporary_;
        }
      }
    }
    /* If we have more to send, try to send it. */
    if (uart_tx_ptr) {
      error = call HdlcUart.send((uint8_t*)uart_tx_ptr, uart_tx_len);
    }
    /* If whatever we tried to send failed (delayed result from last
     * time, or immediate result from this time), forward the
     * error. */
    if (SUCCESS != error) {
      send_done = TRUE;
    }
    /* If we finished, we'll update the state to be idle. */
    if (send_done) {
      next_state = TX_idle;
    }
    /* Update the machine state. */
    txState_ = next_state;
    /* Notify the user that the transfer has completed, whether it
     * succeeded or failed. */
    if (send_done) {
      signal HdlcFraming.sendDone(txStart_, txEnd_ - txStart_, error);
    }
  }

  async event void HdlcUart.uartError (error_t error)
  {
  }

  async event void HdlcUart.sendDone (error_t error)
  {
    /* @note This event runs in interrupt context */
    atomic {
      sendDoneError__ = error;
    }
    post uartStreamSendDone();
  }

  default async event void HdlcFraming.receivedDelimiter () { }
  default async event void HdlcFraming.receptionError (HdlcError_e code) { }

  command error_t StdControl.start ()
  {
    error_t rc = SUCCESS;

    /* NB: Ignore the return from this.  It may fail if the UART is
     * being used by the SerialPrintfC component, and that's OK. */
    (void)call UartControl.start();
    if (SUCCESS == rc) {
      atomic rc = startNewFrame_async__();
    }
    return rc;
  }

  command error_t StdControl.stop ()
  {
    /* Need to inhibit any new transmissions.
     * Need to shut down any in-progress transmission.
     * Need to inhibit any new receptions
     * Need to wait for completed frames to be released. */
    return call UartControl.stop();
  }

#if DEBUG_HDLC_FRAMING
  async command unsigned int DebugHdlcFraming.rxState () { atomic return rxState__; }
  async command unsigned int DebugHdlcFraming.txState () { return txState_; }
  async command unsigned int DebugHdlcFraming.numRxFrames () { return RX_FRAME_LIMIT; }
  async command const HdlcRxFrame_t* DebugHdlcFraming.rxFrames () { return rxFrames_; }
#endif /* DEBUG_HDLC_FRAMING */
  
}

