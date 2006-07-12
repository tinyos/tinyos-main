/*
 * Copyright (c) 2004, Technische Universitat Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitat Berlin nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description ----------------------------------------------------------
 * Implementation of UART0 lowlevel functionality - stateless.
 * - Revision -------------------------------------------------------------
 * $Revision: 1.2 $
 * $Date: 2006-07-12 17:01:47 $
 * @author Jan Hauer 
 * @author Vlado Handziski
 * @author Joe Polastre
 * ========================================================================
 */

#include "msp430baudrates.h"

generic module Msp430UartP(uint32_t default_baudrate) {

  provides interface Init;
  provides interface StdControl;
  provides interface SerialByteComm;
  
  uses interface HplMsp430Usart as HplUsart;
  uses interface HplMsp430UsartInterrupts as HplUsartInterrupts;
}

implementation {

  command error_t Init.init() {
    return SUCCESS;
  }

  command error_t StdControl.start() {
    call HplUsart.setModeUART();
    call HplUsart.setClockSource(SSEL_SMCLK);
    if (default_baudrate == 57600UL){
      call HplUsart.setClockRate(UBR_SMCLK_57600, UMCTL_SMCLK_57600);
    } else if (default_baudrate == 115200UL){
      call HplUsart.setClockRate(UBR_SMCLK_115200, UMCTL_SMCLK_115200);
    } else if (default_baudrate == 230400UL){
      call HplUsart.setClockRate(UBR_SMCLK_230400, UMCTL_SMCLK_230400);
    }
    call HplUsart.enableRxIntr();
    call HplUsart.enableTxIntr();
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    call HplUsart.disableRxIntr();
    call HplUsart.disableTxIntr();

    call HplUsart.disableUART();
    return SUCCESS;
  }

  async command error_t SerialByteComm.put( uint8_t data ) {
    call HplUsart.tx( data );
    return SUCCESS;
  }

  async event void HplUsartInterrupts.txDone() {
    signal SerialByteComm.putDone();
  }

  async event void HplUsartInterrupts.rxDone( uint8_t data ) {
    signal SerialByteComm.get( data );
  }
}
