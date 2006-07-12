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
 * - Revision -------------------------------------------------------------
 * $Revision: 1.2 $
 * $Date: 2006-07-12 17:01:59 $
 * ========================================================================
 */

 /**
 * HplTda5250DataP module
 *
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
  */

module HplTda5250DataP {
  provides {
    interface Init;
    interface HplTda5250Data;
    interface Resource;
  }
  uses {
    interface GeneralIO as DATA;
    // FIXME: platform dependence at HPL-level!
    interface HplMsp430Usart as Usart;
    interface HplMsp430UsartInterrupts as UsartInterrupts;
    interface Resource as UartResource;
  }
}

implementation {

  /**
   * Initializes the Radio, setting up all Pin configurations
   * to the MicroProcessor that is driving it
   *
   * @return always returns SUCCESS
    */
  command error_t Init.init() {
    call DATA.makeOutput();
    call DATA.clr();

    //Make Rx default
    call DATA.makeInput();
    return SUCCESS;
  }

  async command error_t Resource.request() {
    return call UartResource.request();
  }

  async command error_t Resource.immediateRequest() {
    if(call UartResource.immediateRequest() == EBUSY) {
      return EBUSY;
    }
    call Usart.setModeUART();
    return SUCCESS;
  }

  async command void Resource.release() {
    call Usart.disableRxIntr();
    call Usart.disableTxIntr();
    call UartResource.release();
  }

  async command bool Resource.isOwner() {
    return call UartResource.isOwner();
  }

  event void UartResource.granted() {
    call Usart.setModeUART();
    signal Resource.granted();
  }

  async command error_t HplTda5250Data.tx(uint8_t data) {
    if(call UartResource.isOwner() == FALSE)
     return FAIL;
    call Usart.tx(data);
    return SUCCESS;
  }

  async command bool HplTda5250Data.isTxDone() {
    if(call UartResource.isOwner() == FALSE)
      return FAIL;
    return call Usart.isTxEmpty();
  }

  async command error_t HplTda5250Data.enableTx() {
    if(call UartResource.isOwner() == FALSE)
      return FAIL;
    call Usart.setModeUART_TX();
    call Usart.setClockSource(SSEL_SMCLK);
    call Usart.setClockRate(UBR_SMCLK_38400, UMCTL_SMCLK_38400);
    call Usart.enableTxIntr();
    return SUCCESS;
  }

  async command error_t HplTda5250Data.disableTx() {
    if(call UartResource.isOwner() == FALSE)
      return FAIL;
    call Usart.disableUARTTx();
    call Usart.disableTxIntr();
    return SUCCESS;
  }

  async command error_t HplTda5250Data.enableRx() {
    if(call UartResource.isOwner() == FALSE)
      return FAIL;
    call Usart.setModeUART_RX();
    call Usart.setClockSource(SSEL_SMCLK);
    call Usart.setClockRate(UBR_SMCLK_38400, UMCTL_SMCLK_38400);
    call Usart.enableRxIntr();
    return SUCCESS;
  }

  async command error_t HplTda5250Data.disableRx() {
    if(call UartResource.isOwner() == FALSE)
      return FAIL;
    call Usart.disableUARTRx();
    call Usart.disableRxIntr();
    return SUCCESS;
  }

  async event void UsartInterrupts.txDone() {
    if(call UartResource.isOwner() == FALSE)
      return;
    signal HplTda5250Data.txReady();
  }

  async event void UsartInterrupts.rxDone(uint8_t data) {
    if(call UartResource.isOwner() == FALSE)
      return;
    signal HplTda5250Data.rxDone(data);
  }

  default event void Resource.granted() {}
  default async event void HplTda5250Data.txReady() {}
  default async event void HplTda5250Data.rxDone(uint8_t data) {}
}
