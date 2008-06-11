/* $Id: HalPXA27xSpiDMAM.nc,v 1.5 2008-06-11 00:42:13 razvanm Exp $ */
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
 * It assumes the Motorola Serial Peripheral Interface format.
 * Uses DMA for the packet based transfers.
 * 
 * @param valSCR The value for the SCR field in the SSCR0 register of the 
 * associated SSP peripheral.
 *
 * @param valDSS The value for the DSS field in the SSCR0 register of the
 * associated SSP peripheral.
 * 
 * @author Phil Buonadonna
 */

generic module HalPXA27xSpiDMAM(uint8_t valFRF, uint8_t valSCR, uint8_t valDSS, bool enableRWOT) 
{
  provides {
    interface Init;
    interface SpiByte;
    interface SpiPacket[uint8_t instance];
  }
  uses {
    interface HplPXA27xSSP as SSP;
    interface HplPXA27xDMAChnl as RxDMA;
    interface HplPXA27xDMAChnl as TxDMA;
    interface HplPXA27xDMAInfo as SSPRxDMAInfo;
    interface HplPXA27xDMAInfo as SSPTxDMAInfo;
  }
}

implementation
{
  // The BitBuckets need to be 8 bytes. 
  norace unsigned long long txBitBucket, rxBitBucket;
  //norace uint8_t ucBitBucket[0x10000];
  //norace uint32_t txBitBucket, rxBitBucket;
  uint8_t *txCurrentBuf, *rxCurrentBuf;
  uint8_t instanceCurrent;
  uint32_t lenCurrent;

  command error_t Init.init() {

    //txBitBucket = (uint32_t)((uint32_t)&ullBitBucket[1] * ~0x7);
    //rxBitBucket = txBitBucket + 8;
    //rxBitBucket = txBitBucket = (uint32_t)&ucBitBucket[0];
    txCurrentBuf = rxCurrentBuf = NULL;
    lenCurrent = 0 ;
    instanceCurrent = 0;

    call SSP.setSSCR1((SSCR1_TRAIL | SSCR1_RFT(8) | SSCR1_TFT(8)));
    call SSP.setSSTO(3500);
    call SSP.setSSCR0(SSCR0_SCR(valSCR) | SSCR0_SSE | SSCR0_FRF(valFRF) | SSCR0_DSS(valDSS) );

    call TxDMA.setMap(call SSPTxDMAInfo.getMapIndex());
    call RxDMA.setMap(call SSPRxDMAInfo.getMapIndex());
    call TxDMA.setDALGNbit(TRUE);
    call RxDMA.setDALGNbit(TRUE);

    return SUCCESS;
  }

  async command uint8_t SpiByte.write(uint8_t tx) {
    volatile uint32_t tmp;
    volatile uint8_t val;
#if 1
    while ((call SSP.getSSSR()) & SSSR_RNE) {
      tmp = call SSP.getSSDR();
    } 
#endif
    call SSP.setSSDR(tx); 

    while ((call SSP.getSSSR()) & SSSR_BSY);

    val = call SSP.getSSDR();

    return val;
  }

  async command error_t SpiPacket.send[uint8_t instance](uint8_t* txBuf, uint8_t* rxBuf, uint16_t len) {
    uint32_t tmp;
    uint32_t txAddr,rxAddr;
    uint32_t txDMAFlags, rxDMAFlags;
    error_t error = FAIL;

#if 1
    while ((call SSP.getSSSR()) & SSSR_RNE) {
      tmp = call SSP.getSSDR();
    }
#endif 

    atomic {
      txCurrentBuf = txBuf;
      rxCurrentBuf = rxBuf;
      lenCurrent = len;
      instanceCurrent = instance;
    }

    txDMAFlags = (DCMD_FLOWTRG | DCMD_BURST8 | DCMD_WIDTH1 
		  | DCMD_LEN(len));
    rxDMAFlags = (DCMD_FLOWSRC | DCMD_ENDIRQEN | DCMD_BURST8 | DCMD_WIDTH1 
		  | DCMD_LEN(len));

    if (rxBuf == NULL) { 
      rxAddr = (uint32_t)&rxBitBucket; 
    }
    else {
      rxAddr = (uint32_t)rxBuf; 
      rxDMAFlags |= DCMD_INCTRGADDR; 
    }

    if (txBuf == NULL) {
      txAddr = (uint32_t)&txBitBucket; 
    }
    else {
      txAddr = (uint32_t)txBuf;
      txDMAFlags |= DCMD_INCSRCADDR;
    }

    call RxDMA.setDCSR(DCSR_NODESCFETCH | DCSR_EORIRQEN | DCSR_EORINT);
    call RxDMA.setDSADR(call SSPRxDMAInfo.getAddr());
    call RxDMA.setDTADR(rxAddr);
    call RxDMA.setDCMD(rxDMAFlags);

    call TxDMA.setDCSR(DCSR_NODESCFETCH);
    call TxDMA.setDSADR(txAddr);
    call TxDMA.setDTADR(call SSPTxDMAInfo.getAddr());
    call TxDMA.setDCMD(txDMAFlags);
    
    call SSP.setSSSR(SSSR_TINT);
    call SSP.setSSCR1((call SSP.getSSCR1()) | SSCR1_RSRE | SSCR1_TSRE);

    call RxDMA.setDCSR(DCSR_RUN | DCSR_NODESCFETCH | DCSR_EORIRQEN);
    call TxDMA.setDCSR(DCSR_RUN | DCSR_NODESCFETCH);
    
    error = SUCCESS;
    
    return error;
  }
  
  async event void RxDMA.interruptDMA() {
    uint8_t *txBuf,*rxBuf;
    uint8_t instance;
    uint32_t len;
    
    atomic {
      instance = instanceCurrent;
      len = lenCurrent;
      txBuf = txCurrentBuf;
      rxBuf = rxCurrentBuf;
      lenCurrent = 0;
    }
    call RxDMA.setDCMD(0);
    call RxDMA.setDCSR(DCSR_EORINT | DCSR_ENDINTR | DCSR_STARTINTR | DCSR_BUSERRINTR);

    signal SpiPacket.sendDone[instance](txBuf,rxBuf,len,SUCCESS);

    return;
  }

  async event void TxDMA.interruptDMA() {
    // The transmit side should NOT generate an interrupt. 
    call TxDMA.setDCMD(0);
    call TxDMA.setDCSR(DCSR_EORINT | DCSR_ENDINTR | DCSR_STARTINTR | DCSR_BUSERRINTR);
    return;
  }

  async event void SSP.interruptSSP() {
    // For this Hal, we should never get here normally
    // Perhaps we should signal any weird errors? For now, just clear the interrupts
    call SSP.setSSSR(SSSR_BCE | SSSR_TUR | SSSR_EOC | SSSR_TINT | 
			       SSSR_PINT | SSSR_ROR );
    return;
  }

  default async event void SpiPacket.sendDone[uint8_t instance](uint8_t* txBuf, uint8_t* rxBuf, 
					      uint16_t len, error_t error) {
    return;
  }
  
}
