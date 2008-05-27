/* $Id: HalPXA27xSpiPioM.nc,v 1.5 2008-05-27 17:28:32 kusy Exp $ */
/*
 * Copyright (c) 2005 Arched Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arched Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/**
 * Implements the TOS 2.0 SpiByte and SpiPacket interfaces for the PXA27x.
 * Provides master mode communication for a variety of frame formats, speeds
 * and data sizes.
 * 
 * @param valFRF The frame format to use. 
 * 
 * @param valSCR The value for the SSP clock rate.
 *
 * @param valDSS The value for the DSS field in the SSCR0 register of the
 * associated SSP peripheral.
 * 
 * @param enableRWOT Enables Receive without transmit mode. Used only for 
 * the SpiPacket interface. If the txBuf parameter of SpiPacket.send is null
 * the implementation will continuously clock in data without regard to the 
 * contents of the TX FIFO.  This is different from the spec for the interface
 * which requires that the transmitter send zeros (0) for this case.
 * 
 * @author Phil Buonadonna
 * @author Miklos Maroti, Brano Kusy
 */

generic module HalPXA27xSpiPioM(uint8_t valFRF, uint8_t valSCR, uint8_t valDSS, bool enableRWOT) 
{
  provides {
    interface Init;
    interface SpiByte;
    interface SpiPacket[uint8_t instance];
  }
  uses {
    interface HplPXA27xSSP as SSP;
  }
}

implementation
{
  enum{
    FLAGS_SSCR0 = SSCR0_SCR(valSCR) | SSCR0_FRF(/*0*/valFRF) | SSCR0_DSS(valDSS),
    FLAGS_SSCR1 = 0
  };

  // The BitBuckets need to be 8 bytes.
  norace unsigned long long txBitBucket, rxBitBucket;
  norace uint8_t *txCurrentBuf, *rxCurrentBuf, *txPtr, *rxPtr;
  norace uint8_t txInc, rxInc;
  norace uint8_t instanceCurrent;
  uint32_t lenCurrent, lenRemain;

  command error_t Init.init() {

    txBitBucket = 0, rxBitBucket = 0;
    txCurrentBuf = rxCurrentBuf = NULL;
    lenCurrent = 0 ;
    instanceCurrent = 0;
    atomic lenRemain = 0;

    call SSP.setSSCR1(FLAGS_SSCR1);
    call SSP.setSSTO(3500 /*96*8*/);
    call SSP.setSSCR0(FLAGS_SSCR0);
    call SSP.setSSCR0(FLAGS_SSCR0 | SSCR0_SSE);

    return SUCCESS;
  }

  async command uint8_t SpiByte.write(uint8_t tx) {
    volatile uint8_t val;
#if 1
    while ((call SSP.getSSSR()) & SSSR_RNE) {
      call SSP.getSSDR();
    } 
#endif
    call SSP.setSSDR(tx); 

    while ((call SSP.getSSSR()) & SSSR_BSY);

    val = call SSP.getSSDR();
    
    return val;
  }

  async command error_t SpiPacket.send[uint8_t instance](uint8_t* txBuf, uint8_t* rxBuf, uint16_t len) {
    uint32_t i;

#if 1
    while ((call SSP.getSSSR()) & SSSR_RNE) {
      call SSP.getSSDR();
    }
#endif 

    txCurrentBuf = txBuf;
    rxCurrentBuf = rxBuf;
    atomic lenCurrent = lenRemain = len;
    instanceCurrent = instance;
  
    if (rxBuf == NULL) { 
    	rxPtr = (uint8_t *)&rxBitBucket;
    	rxInc = 0;
    }
    else {
    	rxPtr = rxBuf;
    	rxInc = 1;
    }
    
    if (txBuf == NULL) {
    	txPtr = (uint8_t *)&txBitBucket;
    	txInc = 0;
    }
    else {
    	txPtr = txBuf;
    	txInc = 1;
    }

    if ((txBuf == NULL) && (enableRWOT == TRUE)) {
    	call SSP.setSSCR0(FLAGS_SSCR0);
    	call SSP.setSSCR1(FLAGS_SSCR1 | SSCR1_RWOT);
    	call SSP.setSSCR0(FLAGS_SSCR0 | SSCR0_SSE);
    	while (len > 0) {
    	  while (!(call SSP.getSSSR() & SSSR_RNE));
    	  *rxPtr = call SSP.getSSDR();
    	  rxPtr += rxInc;
    	  len--;
    	}
    	call SSP.setSSCR0(FLAGS_SSCR0);
    	call SSP.setSSCR1(FLAGS_SSCR1);
    	call SSP.setSSCR0(FLAGS_SSCR0 | SSCR0_SSE);
    }
    else {
    	uint8_t burst = (len < 16) ? len : 16;
    	for (i = 0;i < burst; i++) {
    	  call SSP.setSSDR(*txPtr);
    	  txPtr += txInc;
    	}
    	call SSP.setSSCR1(FLAGS_SSCR1 | SSCR1_TINTE | SSCR1_RIE);
    }
    
    return SUCCESS;
  }
  
  async event void SSP.interruptSSP() {
    uint32_t i, uiStatus, uiFifoLevel;
    uint32_t burst;

    uiStatus = call SSP.getSSSR();
    call SSP.setSSSR(SSSR_TINT);

    uiFifoLevel = (((uiStatus & SSSR_RFL) >> 12) | 0xF) + 1;
    uiFifoLevel = (uiFifoLevel > lenRemain) ? lenRemain : uiFifoLevel;

    if( !(uiStatus & SSSR_RNE))
      return;

    for (i = 0; i < uiFifoLevel; i++) {
      *rxPtr = call SSP.getSSDR();
      rxPtr += rxInc;
    }

    atomic {
      lenRemain -= uiFifoLevel;
      burst = (lenRemain < 16) ? lenRemain : 16;
    }

    if (burst > 0) {
      for (i = 0;i < burst;i++) {
        call SSP.setSSDR(*txPtr);
        txPtr += txInc;
      }
    }
    else {
      uint32_t len = lenCurrent;
      call SSP.setSSCR1(FLAGS_SSCR1);
      lenCurrent = 0;
      signal SpiPacket.sendDone[instanceCurrent](txCurrentBuf, rxCurrentBuf,len,SUCCESS);
    }

    return;
  }

  default async event void SpiPacket.sendDone[uint8_t instance](uint8_t* txBuf, uint8_t* rxBuf, 
					      uint16_t len, error_t error) {
    return;
  }
  
}
