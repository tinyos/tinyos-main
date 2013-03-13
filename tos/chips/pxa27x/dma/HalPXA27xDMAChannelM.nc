/*
 * Copyright (c) 2005 Arch Rock Corporation 
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
 *   Neither the name of the Arch Rock Corporation nor the names of its
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
 *
 *
 * @author Kaisen Lin
 * @author Phil Buonadonna
 */

#include "DMA.h"

module HalPXA27xDMAChannelM {
  provides interface HalPXA27xDMAChannel[uint8_t chnl];

  uses interface HplPXA27xDMACntl;
  uses interface HplPXA27xDMAChnl[uint8_t chnl];
}

implementation {
	uint8_t requestedChannel;
  task void reqCompleteTask() {
    signal HalPXA27xDMAChannel.requestChannelDone[requestedChannel]();
  }
  
  command error_t HalPXA27xDMAChannel.requestChannel[uint8_t chnl](DMAPeripheralID_t peripheralID, DMAPriority_t priority, bool permanent) {
    // priority is decided based on which channel you pick (PXADEV 5-4)
    // permanent? nothing lasts forever my friend

    uint32_t valDRCMR, valDCSR;
    valDRCMR = call HplPXA27xDMACntl.getDRCMR(peripheralID) | DRCMR_MAPVLD;
    valDRCMR = valDRCMR & ~DRCMR_CHLNUM(0x1F);
    valDRCMR |= DRCMR_CHLNUM(chnl);
    call HplPXA27xDMACntl.setDRCMR(peripheralID, valDRCMR);
    requestedChannel = chnl;
    
    valDCSR = call HplPXA27xDMAChnl.getDCSR[chnl]();
    valDCSR &= ~(DCSR_RUN);
    call HplPXA27xDMAChnl.setDCSR[chnl](valDCSR | DCSR_NODESCFETCH);
    
    post reqCompleteTask();
    return SUCCESS;
  }

  command error_t HalPXA27xDMAChannel.returnChannel[uint8_t chnl](DMAPeripheralID_t peripheralID) {
    // modified interface to require peripheralID, this isn't virtualized
    uint32_t valDRCMR;
    valDRCMR = call HplPXA27xDMACntl.getDRCMR(peripheralID) & ~DRCMR_MAPVLD;
    call HplPXA27xDMACntl.setDRCMR(peripheralID, valDRCMR);
    return SUCCESS;
  }
  
  command error_t HalPXA27xDMAChannel.setSourceAddr[uint8_t chnl](uint32_t val) {
    call HplPXA27xDMAChnl.setDSADR[chnl](val);
    return SUCCESS;
  }

  command error_t HalPXA27xDMAChannel.setTargetAddr[uint8_t chnl](uint32_t val) {
    call HplPXA27xDMAChnl.setDTADR[chnl](val);
    return SUCCESS;
  }

  command error_t HalPXA27xDMAChannel.enableSourceAddrIncrement[uint8_t chnl](bool enable) {
    uint32_t valDCMD;
    valDCMD = call HplPXA27xDMAChnl.getDCMD[chnl]();
    
    valDCMD = (enable) ? (valDCMD | DCMD_INCSRCADDR) : (valDCMD & ~DCMD_INCSRCADDR);

    call HplPXA27xDMAChnl.setDCMD[chnl](valDCMD);
    return SUCCESS;
  }

  command error_t HalPXA27xDMAChannel.enableTargetAddrIncrement[uint8_t chnl](bool enable) {
    uint32_t valDCMD;
    valDCMD = call HplPXA27xDMAChnl.getDCMD[chnl]();
    
    valDCMD = (enable) ? (valDCMD | DCMD_INCTRGADDR) : (valDCMD & ~DCMD_INCTRGADDR);

    call HplPXA27xDMAChnl.setDCMD[chnl](valDCMD);
    return SUCCESS; 
  }

  command error_t HalPXA27xDMAChannel.enableSourceFlowControl[uint8_t chnl](bool enable) {
    uint32_t valDCMD;
    valDCMD = call HplPXA27xDMAChnl.getDCMD[chnl]();
    
    valDCMD = (enable) ? (valDCMD | DCMD_FLOWSRC) : (valDCMD & ~DCMD_FLOWSRC);

    call HplPXA27xDMAChnl.setDCMD[chnl](valDCMD);
    return SUCCESS; 
  }

  command error_t HalPXA27xDMAChannel.enableTargetFlowControl[uint8_t chnl](bool enable) {
    uint32_t valDCMD;
    valDCMD = call HplPXA27xDMAChnl.getDCMD[chnl]();
    
    valDCMD = (enable) ? (valDCMD | DCMD_FLOWTRG) : (valDCMD & ~DCMD_FLOWTRG);

    call HplPXA27xDMAChnl.setDCMD[chnl](valDCMD);
    return SUCCESS; 
  }

  command error_t HalPXA27xDMAChannel.setMaxBurstSize[uint8_t chnl](DMAMaxBurstSize_t size) {
    uint32_t valDCMD;
    valDCMD = call HplPXA27xDMAChnl.getDCMD[chnl]();
    valDCMD &= ~DCMD_BURST32; // zero the bits first

    switch(size) {
    case DMA_BURST_SIZE_8BYTES:
      valDCMD |= DCMD_BURST8;
      break;
    case DMA_BURST_SIZE_16BYTES:
      valDCMD |= DCMD_BURST16;
      break;
    case DMA_BURST_SIZE_32BYTES:
      valDCMD |= DCMD_BURST32;
      break;
    default:
      return FAIL;
    }
    
    call HplPXA27xDMAChnl.setDCMD[chnl](valDCMD);
    return SUCCESS; 
  }

  command error_t HalPXA27xDMAChannel.setTransferLength[uint8_t chnl](uint16_t length) {
    uint32_t valDCMD;
    valDCMD = call HplPXA27xDMAChnl.getDCMD[chnl]();
    
    if(length > DCMD_MAXLEN)
      return FAIL;

    valDCMD &= ~DCMD_MAXLEN; // zero the bits first
    valDCMD |= DCMD_LEN(length);
    
    call HplPXA27xDMAChnl.setDCMD[chnl](valDCMD);
    return SUCCESS;
  }

  command error_t HalPXA27xDMAChannel.setTransferWidth[uint8_t chnl](DMATransferWidth_t width) {
    uint32_t valDCMD;
    valDCMD = call HplPXA27xDMAChnl.getDCMD[chnl]();
    valDCMD &= ~DCMD_WIDTH4; // zero the bits first

    switch(width) {
    case DMA_WIDTH_1BYTE:
      valDCMD |= DCMD_WIDTH1;
      break;
    case DMA_WIDTH_2BYTES:
      valDCMD |= DCMD_WIDTH2;
      break;
    case DMA_WIDTH_4BYTES:
      valDCMD |= DCMD_WIDTH4;
      break;
    default:
      return FAIL;
    }
    
    call HplPXA27xDMAChnl.setDCMD[chnl](valDCMD);
    return SUCCESS;     
  }

  command error_t HalPXA27xDMAChannel.run[uint8_t chnl](bool InterruptEn) {
    uint32_t valDCSR;
    uint32_t valDCMD;

    valDCSR = call HplPXA27xDMAChnl.getDCSR[chnl]();
    valDCMD = call HplPXA27xDMAChnl.getDCMD[chnl]();
			
    valDCMD = (InterruptEn) ? valDCMD | DCMD_ENDIRQEN : valDCMD & ~DCMD_ENDIRQEN ; //was valDCSR & ~DCMD_ENDIRQEN
    
    call HplPXA27xDMAChnl.setDCMD[chnl](valDCMD);
    call HplPXA27xDMAChnl.setDCSR[chnl](valDCSR | DCSR_RUN | DCSR_NODESCFETCH);
    
    return SUCCESS;
  }

  command error_t HalPXA27xDMAChannel.stop[uint8_t chnl]() {
    uint32_t valDCSR;
    valDCSR = call HplPXA27xDMAChnl.getDCSR[chnl]();
    
    call HplPXA27xDMAChnl.setDCSR[chnl](valDCSR & ~DCSR_RUN);
    return SUCCESS;
  }

  async event void HplPXA27xDMAChnl.interruptDMA[uint8_t chnl]() {
	// might want to clear interrupt first
    // ...
	signal HalPXA27xDMAChannel.Interrupt[chnl]();
  }

  default async event void HalPXA27xDMAChannel.Interrupt[uint8_t chnl]() { }
  default event error_t HalPXA27xDMAChannel.requestChannelDone[uint8_t chnl]() { return FAIL; }
}
