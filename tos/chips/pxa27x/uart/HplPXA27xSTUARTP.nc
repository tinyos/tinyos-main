/* $Id: HplPXA27xSTUARTP.nc,v 1.3 2006-12-12 18:23:12 vlahan Exp $ */
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
 * Provides low-level initialization, 1st level interrupt dispatch and register
 * access to the STUART.
 * This component automatically handles setting of the DLAB bit for
 * divisor register access (DLL and DLH) 
 *
 * @author Phil Buonadonna
 */

module HplPXA27xSTUARTP
{
  provides interface Init;
  provides interface HplPXA27xUART as STUART;
  uses interface HplPXA27xInterrupt as STUARTIrq;
}

implementation
{
  bool m_fInit = FALSE;

  command error_t Init.init() {
    bool isInited;

    atomic {
      isInited = m_fInit;
      m_fInit = TRUE;
    }

    if (!isInited) {
      CKEN |= CKEN5_STUART;
      call STUARTIrq.allocate();
      call STUARTIrq.enable();
      STLCR |= LCR_DLAB;
      STDLL = 0x04;
      STDLH = 0x00;
      STLCR &= ~LCR_DLAB;
    }

    return SUCCESS;
  }

  async command uint32_t STUART.getRBR() { return STRBR; }
  async command void STUART.setTHR(uint32_t val) { STRBR = val; }
  async command void STUART.setDLL(uint32_t val) { 
    STLCR |= LCR_DLAB;
    STDLL = val; 
    STLCR &= ~LCR_DLAB;
  }
  async command uint32_t STUART.getDLL() { 
    uint32_t val;
    STLCR |= LCR_DLAB;
    val = STDLL; 
    STLCR &= ~LCR_DLAB;
    return val;
  }
  async command void STUART.setDLH(uint32_t val) { 
    STLCR |= LCR_DLAB;
    STDLH = val; 
    STLCR &= ~LCR_DLAB;
  }
  async command uint32_t STUART.getDLH() { 
    uint32_t val;
    STLCR |= LCR_DLAB;
    val = STDLH;
    STLCR &= ~LCR_DLAB;
    return val;
  }
  async command void STUART.setIER(uint32_t val) { STIER = val; }
  async command uint32_t STUART.getIER() { return STIER; }
  async command uint32_t STUART.getIIR() { return STIIR; }
  async command void STUART.setFCR(uint32_t val) { STFCR = val; }
  async command void STUART.setLCR(uint32_t val) { STLCR = val; }
  async command uint32_t STUART.getLCR() { return STLCR; }
  async command void STUART.setMCR(uint32_t val) { STMCR = val; }
  async command uint32_t STUART.getMCR() { return STMCR; }
  async command uint32_t STUART.getLSR() { return STLSR; }
  async command uint32_t STUART.getMSR() { return STMSR; }
  async command void STUART.setSPR(uint32_t val) { STSPR = val; }
  async command uint32_t STUART.getSPR() { return STSPR; }
  async command void STUART.setISR(uint32_t val) { STISR = val; }
  async command uint32_t STUART.getISR() { return STISR; }
  async command void STUART.setFOR(uint32_t val) { STFOR = val; }
  async command uint32_t STUART.getFOR() { return STFOR; }
  async command void STUART.setABR(uint32_t val) { STABR = val; }
  async command uint32_t STUART.getABR() { return STABR; }
  async command uint32_t STUART.getACR() { return STACR; }

  async event void STUARTIrq.fired () {

    signal STUART.interruptUART();
  }

  default async event void STUART.interruptUART() { return; }
  
}
