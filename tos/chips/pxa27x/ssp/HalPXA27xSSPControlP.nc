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
 * @author Kaisen Lin
 * @author Phil Buonadonna
 */

#include "SSP.h"

generic module HalPXA27xSSPControlP() {
  provides interface HalPXA27xSSPCntl;

  uses interface HplPXA27xSSP as SSP;
}

implementation {

  command error_t HalPXA27xSSPCntl.setMasterSCLK(bool enable) {
    uint32_t valSSCR1;
    valSSCR1 = call SSP.getSSCR1() & ~SSCR1_SCLKDIR;

    if(!enable)
      valSSCR1 |= SSCR1_SCLKDIR;
    
    call SSP.setSSCR1(valSSCR1);
    return SUCCESS;
  }

  command error_t HalPXA27xSSPCntl.setMasterSFRM(bool enable) {
    uint32_t valSSCR1;
    valSSCR1 = call SSP.getSSCR1() & ~SSCR1_SFRMDIR;

    if(!enable)
      valSSCR1 |= SSCR1_SFRMDIR;
    
    call SSP.setSSCR1(valSSCR1);
    return SUCCESS;
  }

  command error_t HalPXA27xSSPCntl.setReceiveWithoutTransmit(bool enable) {
    uint32_t valSSCR1;
    valSSCR1 = call SSP.getSSCR1() & ~SSCR1_RWOT;

    if(enable)
      valSSCR1 |= SSCR1_RWOT;
    
    call SSP.setSSCR1(valSSCR1);
    return SUCCESS;
  }

  command error_t HalPXA27xSSPCntl.setSSPFormat(SSPFrameFormat_t format) {
    uint32_t valSSCR0;
    valSSCR0 = call SSP.getSSCR0() & ~SSCR0_FRF(3);

    call SSP.setSSCR0(valSSCR0 | SSCR0_FRF(format));
    return SUCCESS;
  }

  command error_t HalPXA27xSSPCntl.setDataWidth(SSPDataWidth_t width) {
    uint8_t bitEDSS;
    uint32_t valSSCR0;
    
    if(width < 4)
      return EINVAL;

    // width + 1 = bits to use, don't forget to adjust!
    width -= 1;
    bitEDSS = width & 0x10; // keep bit 4
    width = width & 0xF; // keep bits 0-3
    
    valSSCR0 = call SSP.getSSCR0() & ~SSCR0_DSS(0xF) & ~SSCR0_EDSS;
    if(bitEDSS)
      valSSCR0 |= SSCR0_EDSS;
    valSSCR0 |= SSCR0_DSS(width);
   
    call SSP.setSSCR0(valSSCR0);
    return SUCCESS;
  }

  command error_t HalPXA27xSSPCntl.enableInvertedSFRM(bool enable) {
    uint32_t valSSCR1;
    valSSCR1 = call SSP.getSSCR1() & ~SSCR1_IFS;

    if(!enable)
      valSSCR1 |= SSCR1_IFS;
    
    call SSP.setSSCR1(valSSCR1);
    return SUCCESS;
  }

  command error_t HalPXA27xSSPCntl.setRxFifoLevel(SSPFifoLevel_t level) {
    uint32_t valSSCR1;
    valSSCR1 = call SSP.getSSCR1() & ~SSCR1_RFT(0xF);

    call SSP.setSSCR1(valSSCR1 | SSCR1_RFT(level));
    return SUCCESS;
  }

  command error_t HalPXA27xSSPCntl.setTxFifoLevel(SSPFifoLevel_t level) {
    uint32_t valSSCR1;
    valSSCR1 = call SSP.getSSCR1() & ~SSCR1_TFT(0xF);

    call SSP.setSSCR1(valSSCR1 | SSCR1_TFT(level));
    return SUCCESS;
  }

  command error_t HalPXA27xSSPCntl.setMicrowireTxSize(SSPMicrowireTxSize_t size) {
    uint32_t valSSCR1;
    valSSCR1 = call SSP.getSSCR1();

    if(size == UWIRE_16BIT)
      valSSCR1 |= SSCR1_MWDS;
    else if(size == UWIRE_8BIT)
      valSSCR1 &= ~ SSCR1_MWDS;
    else
      return FAIL;

    call SSP.setSSCR1(valSSCR1);
    return SUCCESS;
  }

  command error_t HalPXA27xSSPCntl.setClkRate(uint16_t clkdivider) {
    uint32_t valSSCR0;

    clkdivider -= 1; // check PXA Dev Manual for why to do this

    valSSCR0 = call SSP.getSSCR0() & ~SSCR0_SCR(0xFFF);
    valSSCR0 |= SSCR0_SCR(clkdivider);
    call SSP.setSSCR0(valSSCR0);
    return SUCCESS;
  }

  command error_t HalPXA27xSSPCntl.setClkMode(SSPClkMode_t mode) {
    uint32_t valSSCR0;
    valSSCR0 = call SSP.getSSCR0();

    if(mode == SSP_NETWORKMODE)
      valSSCR0 |= SSCR0_NCS;
    else if(mode == SSP_NORMALMODE)
      valSSCR0 &= ~SSCR0_NCS;
    else
      return FAIL;

    call SSP.setSSCR0(valSSCR0);
    return SUCCESS;
  }

  async event void SSP.interruptSSP() {
    // intentionally left blank, not supposed to handle interrupts
  }
}
