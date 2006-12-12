/* $Id: HplPXA27xDMAM.nc,v 1.4 2006-12-12 18:23:12 vlahan Exp $ */
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
 * 
 * @author Phil Buonadonna
 */
module HplPXA27xDMAM
{
  provides {
    interface Init;
    interface HplPXA27xDMACntl;
    interface HplPXA27xDMAChnl[uint8_t chnl];
  }
  uses {
    interface HplPXA27xInterrupt as DMAIrq;
  }
}

implementation
{
  
  command error_t Init.init() {
    call DMAIrq.allocate();
    call DMAIrq.enable();
    return SUCCESS;
  }
  
  async command void HplPXA27xDMACntl.setDRCMR(uint8_t peripheral, uint8_t val) {
    DRCMR(peripheral) = val;
  }
  async command uint8_t HplPXA27xDMACntl.getDRCMR(uint8_t peripheral) { return DRCMR(peripheral);}
  async command void HplPXA27xDMACntl.setDALGN(uint32_t val) {DALGN = val;}
  async command uint32_t HplPXA27xDMACntl.getDALGN(uint32_t val) {return DALGN; }
  async command void HplPXA27xDMACntl.setDPCSR(uint32_t val) {DPCSR = val; }
  async command uint32_t HplPXA27xDMACntl.getDPSCR() {return DPCSR; }
  async command void HplPXA27xDMACntl.setDRQSR0(uint32_t val) {DRQSR0 = val; }
  async command uint32_t HplPXA27xDMACntl.getDRQSR0() {return DRQSR0; }
  async command void HplPXA27xDMACntl.setDRQSR1(uint32_t val) {DRQSR1 = val; }
  async command uint32_t HplPXA27xDMACntl.getDRQSR1() {return DRQSR1; }
  async command void HplPXA27xDMACntl.setDRQSR2(uint32_t val) {DRQSR2 = val; }
  async command uint32_t HplPXA27xDMACntl.getDRQSR2() {return DRQSR2; }
  async command uint32_t HplPXA27xDMACntl.getDINT() {return DINT; }
  async command void HplPXA27xDMACntl.setFLYCNFG(uint32_t val) {FLYCNFG = val; }
  async command uint32_t HplPXA27xDMACntl.getFLYCNFG() {return FLYCNFG; }

  
  async command error_t HplPXA27xDMAChnl.setMap[uint8_t chnl](uint8_t dev) {
    call HplPXA27xDMACntl.setDRCMR(dev,(DRCMR_MAPVLD | DRCMR_CHLNUM(chnl)));
    return SUCCESS;
  }
  async command void HplPXA27xDMAChnl.setDALGNbit[uint8_t chnl](bool flag) {
    if (flag) {
      DALGN |= (1 << chnl);
    }
    else {
      DALGN &= ~(1 << chnl);
    }
    return;
  }
  async command bool HplPXA27xDMAChnl.getDALGNbit[uint8_t chnl]() {
    return ((DALGN & (1 << chnl)) != 0);
  }
  async command bool HplPXA27xDMAChnl.getDINTbit[uint8_t chnl]() {
    return ((DINT & (1 << chnl)) != 0);
  }
  async command void HplPXA27xDMAChnl.setDCSR[uint8_t chnl](uint32_t val) {
    // uint32_t cycles;
    //_pxa27x_perf_clear();
    DCSR(chnl) = val;
    //_pxa27x_perf_get(cycles);
  }
  async command uint32_t HplPXA27xDMAChnl.getDCSR[uint8_t chnl]() {return DCSR(chnl); }
  async command void HplPXA27xDMAChnl.setDCMD[uint8_t chnl](uint32_t val) {DCMD(chnl) = val; }
  async command uint32_t HplPXA27xDMAChnl.getDCMD[uint8_t chnl]() {return DCMD(chnl); }
  async command void HplPXA27xDMAChnl.setDDADR[uint8_t chnl](uint32_t val) {DDADR(chnl) = val; }
  async command uint32_t HplPXA27xDMAChnl.getDDADR[uint8_t chnl]() {return DDADR(chnl); }
  async command void HplPXA27xDMAChnl.setDSADR[uint8_t chnl](uint32_t val) {DSADR(chnl) = val; }
  async command uint32_t HplPXA27xDMAChnl.getDSADR[uint8_t chnl]() {return DSADR(chnl); }
  async command void HplPXA27xDMAChnl.setDTADR[uint8_t chnl](uint32_t val) {DTADR(chnl) = val; }
  async command uint32_t HplPXA27xDMAChnl.getDTADR[uint8_t chnl]() {return DTADR(chnl); }

  async event void DMAIrq.fired() {
    uint32_t IntReg;
    uint8_t chnl;
    IntReg = call HplPXA27xDMACntl.getDINT();

    while (IntReg) {
      chnl = 31 - _pxa27x_clzui(IntReg);
      signal HplPXA27xDMAChnl.interruptDMA[chnl]();
      IntReg &= ~(1 << chnl);
    }
    return;
  }

  default async event void HplPXA27xDMAChnl.interruptDMA[uint8_t chnl]() {
    call HplPXA27xDMAChnl.setDCMD[chnl](0);
    call HplPXA27xDMAChnl.setDCSR[chnl](DCSR_EORINT | DCSR_ENDINTR
					| DCSR_STARTINTR | DCSR_BUSERRINTR);
  }
}
