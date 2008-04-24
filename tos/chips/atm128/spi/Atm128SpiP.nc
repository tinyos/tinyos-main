/// $Id: Atm128SpiP.nc,v 1.7 2008-04-24 22:31:25 mmaroti Exp $

/*
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 *
 *  Copyright (c) 2004-2005 Crossbow Technology, Inc.
 *  Copyright (c) 2000-2005 The Regents of the University  of California.
 *  All rights reserved.
 *
 *  Permission to use, copy, modify, and distribute this software and its
 *  documentation for any purpose, without fee, and without written
 *  agreement is hereby granted, provided that the above copyright
 *  notice, the (updated) modification history and the author appear in
 *  all copies of this source code.
 *
 *  Permission is also granted to distribute this software under the
 *  standard BSD license as contained in the TinyOS distribution.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 */

/**
 * Primitives for accessing the SPI module on ATmega128
 * microcontroller.  This module assumes the bus has been reserved and
 * checks that the bus owner is in fact the person using the bus.
 * SpiPacket provides an asynchronous send interface where the
 * transmit data length is equal to the receive data length, while
 * SpiByte provides an interface for sending a single byte
 * synchronously. SpiByte allows a component to send a few bytes
 * in a simple fashion: if more than a handful need to be sent,
 * SpiPacket should be used.
 *
 *
 * <pre>
 *  $Id: Atm128SpiP.nc,v 1.7 2008-04-24 22:31:25 mmaroti Exp $
 * </pre>
 *
 * @author Philip Levis
 * @author Joe Polastre
 * @author Martin Turon <mturon@xbow.com>
 *
 */

module Atm128SpiP {
  provides {
    interface Init;
    interface SpiByte;
    interface SpiPacket;
    interface Resource[uint8_t id];
  }
  uses {
    interface Atm128Spi as Spi;
    interface Resource as ResourceArbiter[uint8_t id];
    interface ArbiterInfo;
    interface McuPowerState;
  }
}
implementation {
  uint8_t* txBuffer;
  uint8_t* rxBuffer;
  uint16_t len;
  uint16_t pos;
  
  enum {
    SPI_IDLE,
    SPI_BUSY,
    SPI_ATOMIC_SIZE = 10,
  };

  command error_t Init.init() {
    return SUCCESS;
  }
  
  void startSpi() {
    call Spi.enableSpi(FALSE);
    atomic {
      call Spi.initMaster();
      call Spi.enableInterrupt(FALSE);
      call Spi.setMasterDoubleSpeed(TRUE);
      call Spi.setClockPolarity(FALSE);
      call Spi.setClockPhase(FALSE);
      call Spi.setClock(0);
      call Spi.enableSpi(TRUE);
    }
    call McuPowerState.update();
  }

  void stopSpi() {
    call Spi.enableSpi(FALSE);
    atomic {
      call Spi.sleep();
    }
    call McuPowerState.update();
  }

  async command uint8_t SpiByte.write( uint8_t tx ) {
    call Spi.enableSpi(TRUE);
    call McuPowerState.update();
    call Spi.write( tx );
    while ( !( SPSR & 0x80 ) );
    return call Spi.read();
  }


  /**
   * This component sends SPI packets in chunks of size SPI_ATOMIC_SIZE
   * (which is normally 5). The tradeoff is between SPI performance
   * (throughput) and how much the component limits concurrency in the
   * rest of the system. Handling an interrupt on each byte is
   * very expensive: the context saving/register spilling constrains
   * the rate at which one can write out bytes. A more efficient
   * approach is to write out a byte and wait for a few cycles until
   * the byte is written (a tiny spin loop). This leads to greater
   * throughput, but blocks the system and prevents it from doing
   * useful work.
   *
   * This component takes a middle ground. When asked to transmit X
   * bytes in a packet, it transmits those X bytes in 10-byte parts.
   * <tt>sendNextPart()</tt> is responsible for sending one such
   * part. It transmits bytes with the SpiByte interface, which
   * disables interrupts and spins on the SPI control register for
   * completion. On the last byte, however, <tt>sendNextPart</tt>
   * re-enables SPI interrupts and sends the byte through the
   * underlying split-phase SPI interface. When this component handles
   * the SPI transmit completion event (handles the SPI interrupt),
   * it calls sendNextPart() again. As the SPI interrupt does
   * not disable interrupts, this allows processing in the rest of the
   * system to continue.
   */
   
  error_t sendNextPart() {
    uint16_t end;
    uint16_t tmpPos;
    uint8_t* tx;
    uint8_t* rx;
    
    atomic {
      tx = txBuffer;
      rx = rxBuffer;
      tmpPos = pos;
      end = pos + SPI_ATOMIC_SIZE;
      end = (end > len)? len:end;
    }

    for (;tmpPos < (end - 1) ; tmpPos++) {
      uint8_t val;
      if (tx != NULL) 
	val = call SpiByte.write( tx[tmpPos] );
      else
	val = call SpiByte.write( 0 );
    
      if (rx != NULL) {
	rx[tmpPos] = val;
      }
    }

    // For the last byte, we re-enable interrupts.

   call Spi.enableInterrupt(TRUE);
   atomic {
     if (tx != NULL)
       call Spi.write(tx[tmpPos]);
     else
       call Spi.write(0);
     
     pos = tmpPos;
      // The final increment will be in the interrupt
      // handler.
    }
    return SUCCESS;
  }


  task void zeroTask() {
     uint8_t* rx;
     uint8_t* tx;
     uint16_t  myLen;
     atomic {
       rx = rxBuffer;
       tx = txBuffer;
       myLen = len;
       rxBuffer = NULL;
       txBuffer = NULL;
       len = 0;
       pos = 0;
       signal SpiPacket.sendDone(tx, rx, myLen, SUCCESS);
     }
  }

  /**
   * Send bufLen bytes in <tt>writeBuf</tt> and receive bufLen bytes
   * into <tt>readBuf</tt>. If <tt>readBuf</tt> is NULL, bytes will be
   * read out of the SPI, but they will be discarded. A byte is read
   * from the SPI before writing and discarded (to clear any buffered
   * bytes that might have been left around).
   *
   * This command only sets up the state variables and clears the SPI:
   * <tt>sendNextPart()</tt> does the real work.
   * 
   * If there's a send of zero bytes, short-circuit and just post
   * a task to signal the sendDone. This generally occurs due to an
   * error in the caler, but signaling an event will hopefully let
   * it recover better than returning FAIL.
   */

  
  async command error_t SpiPacket.send(uint8_t* writeBuf, 
				       uint8_t* readBuf, 
				       uint16_t  bufLen) {
    uint8_t discard;
    atomic {
      txBuffer = writeBuf;
      rxBuffer = readBuf;
      len = bufLen;
      pos = 0;
    }
    if (bufLen > 0) {
      discard = call Spi.read();
      return sendNextPart();
    }
    else {
      post zeroTask();
      return SUCCESS;
    }
  }

 default async event void SpiPacket.sendDone
      (uint8_t* _txbuffer, uint8_t* _rxbuffer, 
       uint16_t _length, error_t _success) { }

 async event void Spi.dataReady(uint8_t data) {
   bool again;
   
   atomic {
     if (rxBuffer != NULL) {
       rxBuffer[pos] = data;
       // Increment position
     }
     pos++;
   }
   call Spi.enableInterrupt(FALSE);
   
   atomic {
     again = (pos < len);
   }
   
   if (again) {
     sendNextPart();
   }
   else {
     uint8_t* rx;
     uint8_t* tx;
     uint16_t  myLen;
     uint8_t discard;
     
     atomic {
       rx = rxBuffer;
       tx = txBuffer;
       myLen = len;
       rxBuffer = NULL;
       txBuffer = NULL;
       len = 0;
       pos = 0;
     }
     discard = call Spi.read();

     signal SpiPacket.sendDone(tx, rx, myLen, SUCCESS);
   }
 }

 async command error_t Resource.immediateRequest[ uint8_t id ]() {
   error_t result = call ResourceArbiter.immediateRequest[ id ]();
   if ( result == SUCCESS ) {
     startSpi();
   }
   return result;
 }
 
 async command error_t Resource.request[ uint8_t id ]() {
   atomic {
     if (!call ArbiterInfo.inUse()) {
       startSpi();
     }
   }
   return call ResourceArbiter.request[ id ]();
 }

 async command error_t Resource.release[ uint8_t id ]() {
   error_t error = call ResourceArbiter.release[ id ]();
   atomic {
     if (!call ArbiterInfo.inUse()) {
       stopSpi();
     }
   }
   return error;
 }

 async command uint8_t Resource.isOwner[uint8_t id]() {
   return call ResourceArbiter.isOwner[id]();
 }
 
 event void ResourceArbiter.granted[ uint8_t id ]() {
   signal Resource.granted[ id ]();
 }
 
 default event void Resource.granted[ uint8_t id ]() {}
 
}
