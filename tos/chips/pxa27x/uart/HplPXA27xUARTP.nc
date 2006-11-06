/* $Id: HplPXA27xUARTP.nc,v 1.2 2006-11-06 11:57:12 scipio Exp $ */
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
 * access for the different uarts.  It is a generic that's bound to 
 * the particular UART upon creation.
 *
 * @param baseaddr. The base address of the associated uart. One of 
 * &FFRBR, &BTRBR or &STRBR.
 * This component automatically handles setting of the DLAB bit for
 * divisor register access (DLL and DLH) 
 *
 * @author Phil Buonadonna
 */

#include "PXA27X_UARTREG.h"

generic module HplPXA27xUARTP(uint32_t base_addr)
{
  provides interface Init;
  provides interface HplPXA27xUART as UART;
  uses interface HplPXA27xInterrupt as UARTIrq;
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
      switch (base_addr) {
      case (0x40100000):
	CKEN |= CKEN6_FFUART;
	break;
      case (0x40200000):
	CKEN |= CKEN7_BTUART;
	break;
      case (0x40700000):
	CKEN |= CKEN5_STUART;
	break;
      default:
	break;
      }
      call UARTIrq.allocate();
      call UARTIrq.enable();
      UARTLCR(base_addr) |= LCR_DLAB;
      UARTDLL(base_addr) = 0x04;
      UARTDLH(base_addr) = 0x00;
      UARTLCR(base_addr) &= ~LCR_DLAB;
    }

    return SUCCESS;
  }

  async command uint32_t UART.getRBR() { return UARTRBR(base_addr); }
  async command void UART.setTHR(uint32_t val) { UARTTHR(base_addr) = val; }
  async command void UART.setDLL(uint32_t val) { 
    UARTLCR(base_addr) |= LCR_DLAB;
    UARTDLL(base_addr) = val; 
    UARTLCR(base_addr) &= ~LCR_DLAB;
  }
  async command uint32_t UART.getDLL() { 
    uint32_t val;
    UARTLCR(base_addr) |= LCR_DLAB;
    val = UARTDLL(base_addr); 
    UARTLCR(base_addr) &= ~LCR_DLAB;
    return val;
  }
  async command void UART.setDLH(uint32_t val) { 
    UARTLCR(base_addr) |= LCR_DLAB;
    UARTDLH(base_addr) = val; 
    UARTLCR(base_addr) &= ~LCR_DLAB;
  }
  async command uint32_t UART.getDLH() { 
    uint32_t val;
    UARTLCR(base_addr) |= LCR_DLAB;
    val = UARTDLH(base_addr);
    UARTLCR(base_addr) &= ~LCR_DLAB;
    return val;
  }
  async command void UART.setIER(uint32_t val) { UARTIER(base_addr) = val; }
  async command uint32_t UART.getIER() { return UARTIER(base_addr); }
  async command uint32_t UART.getIIR() { return UARTIIR(base_addr); }
  async command void UART.setFCR(uint32_t val) { UARTFCR(base_addr) = val; }
  async command void UART.setLCR(uint32_t val) { UARTLCR(base_addr) = val; }
  async command uint32_t UART.getLCR() { return UARTLCR(base_addr); }
  async command void UART.setMCR(uint32_t val) { UARTMCR(base_addr) = val; }
  async command uint32_t UART.getMCR() { return UARTMCR(base_addr); }
  async command uint32_t UART.getLSR() { return UARTLSR(base_addr); }
  async command uint32_t UART.getMSR() { return UARTMSR(base_addr); }
  async command void UART.setSPR(uint32_t val) { UARTSPR(base_addr) = val; }
  async command uint32_t UART.getSPR() { return UARTSPR(base_addr); }
  async command void UART.setISR(uint32_t val) { UARTISR(base_addr) = val; }
  async command uint32_t UART.getISR() { return UARTISR(base_addr); }
  async command void UART.setFOR(uint32_t val) { UARTFOR(base_addr) = val; }
  async command uint32_t UART.getFOR() { return UARTFOR(base_addr); }
  async command void UART.setABR(uint32_t val) { UARTABR(base_addr) = val; }
  async command uint32_t UART.getABR() { return UARTABR(base_addr); }
  async command uint32_t UART.getACR() { return UARTACR(base_addr); }

  async event void UARTIrq.fired () {

    signal UART.interruptUART();
  }

  default async event void UART.interruptUART() { return; }
  
}
