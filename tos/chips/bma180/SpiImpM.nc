/*
* Copyright (c) 2011, University of Szeged
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Author: Zsolt Szabo
*/


module SpiImpM {
  provides {
    interface Init;
    interface SpiByte;
    interface FastSpiByte;
    interface SpiPacket;
    interface Resource[uint8_t id];
  }
  uses {
    interface Atm128Spi as Spi;
    interface Resource as ResArb[uint8_t id];
    interface ArbiterInfo;
    interface McuPowerState;
    interface DiagMsg;
  }
}
implementation {
  uint16_t len;
  uint8_t* COUNT_NOK(len) txBuffer;
  uint8_t* COUNT_NOK(len) rxBuffer;
  uint16_t pos;
  
  enum {
    SPI_IDLE,
    SPI_BUSY,
    SPI_ATOMIC_SIZE = 10,
  };

  command error_t Init.init() {
    return SUCCESS;
  }

  void startSpi()
	{
		/*UBRR0 = 0;
		DDRE |= (1 << PE2);
		UCSR0C = (1 << UMSEL01) | (1 << UMSEL00) | (0 << UCPHA0) | (0 << UCPOL0);
		UCSR0B = (1 << RXEN0) | (1 << TXEN0);
		UBRR0 = ((PLATFORM_MHZ*1000000) / (2* 0xFFF))-1;//100;	// baudrate*/
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

  async command uint8_t SpiByte.write( uint8_t data ) {
    uint8_t rcvd=0xFF;
		//while ( !( UCSR0A & (1<<UDRE0)) )
			;

		//UDR0 = data;
    call Spi.write(data);

		while ( !(UCSR0A & (1<<RXC0)) )
			;
    //rcvd = UDR0;
    rcvd = call Spi.read();
    #ifdef DEBUG_BMA
    if(call DiagMsg.record()) {
      call DiagMsg.str("write");
      call DiagMsg.hex8(data);
      call DiagMsg.hex8(rcvd);
      call DiagMsg.send();
    }
    #endif
		return rcvd;
  }

  inline async command void FastSpiByte.splitWrite(uint8_t data) {
    call Spi.write(data);
  }

  inline async command uint8_t FastSpiByte.splitRead() {
    while( ! call Spi.isInterruptPending() )
      ;
    return call Spi.read();
  }

  inline async command uint8_t FastSpiByte.splitReadWrite(uint8_t data) {
    uint8_t b;

    while( ! call Spi.isInterruptPending() )
	;

    b = call Spi.read();
    call Spi.write(data);

    return b;
  }

  inline async command uint8_t FastSpiByte.write(uint8_t data) {
    call Spi.write(data);

    while( ! call Spi.isInterruptPending() )
      ;
    return call Spi.read();
  }

  async command error_t Resource.request[uint8_t id]() {
    atomic{
      if(!call ArbiterInfo.inUse()) {
        startSpi();
      }
    }
    
    return call ResArb.request[ id ]();
  }

  async command error_t Resource.immediateRequest[uint8_t id]() {
    error_t result = call ResArb.immediateRequest[ id ]();
   if ( result == SUCCESS ) {
     startSpi();
   }
   return result;
  }

  async command bool Resource.isOwner[uint8_t id]() {
     return call ResArb.isOwner[id]();
  }

  async command error_t Resource.release[uint8_t id]() {
    error_t error = call ResArb.release[ id ]();
   atomic {
     if (!call ArbiterInfo.inUse()) {
       //stopSpi();
     }
   }
   return error;
  }

  event void ResArb.granted[ uint8_t id ]() {
   signal Resource.granted[ id ]();
 }

//  async event void Spi.dataReady(uint8_t data) {
//  }

   default event void Resource.granted[ uint8_t id ]() {}

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
    uint16_t myLen;
    uint8_t* COUNT_NOK(myLen) tx;
    uint8_t* COUNT_NOK(myLen) rx;
    
    atomic {
      myLen = len;
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
     uint16_t  myLen;
     uint8_t* COUNT_NOK(myLen) rx;
     uint8_t* COUNT_NOK(myLen) tx;

     atomic {
       myLen = len;
       rx = rxBuffer;
       tx = txBuffer;
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
      len = bufLen;
      txBuffer = writeBuf;
      rxBuffer = readBuf;
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
     uint8_t discard;
     uint16_t  myLen;
     uint8_t* COUNT_NOK(myLen) rx;
     uint8_t* COUNT_NOK(myLen) tx;
     
     atomic {
       myLen = len;
       rx = rxBuffer;
       tx = txBuffer;
       rxBuffer = NULL;
       txBuffer = NULL;
       len = 0;
       pos = 0;
     }
     discard = call Spi.read();

     signal SpiPacket.sendDone(tx, rx, myLen, SUCCESS);
   }
 }

}
