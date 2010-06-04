/**
 * Copyright (c) 2005-2006 Arched Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arched Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * Copyright (c) 2004-2005, Technische Universitaet Berlin
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
 * - Neither the name of the Technische Universitaet Berlin nor the names
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
 */

#include "msp430usart.h"
/**
 * Implementation of USART0 lowlevel functionality - stateless.
 * Setting a mode will by default disable USART-Interrupts.
 *
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * @author: Jonathan Hui <jhui@archedrock.com>
 * @author: Vlado Handziski <handzisk@tkn.tu-berlin.de>
 * @author: Joe Polastre
 * @author: Philipp Huppertz <huppertz@tkn.tu-berlin.de>
 * @version $Revision: 1.8 $ $Date: 2010-06-04 22:30:21 $
 */

module HplMsp430Usart0P @safe() {
  provides interface HplMsp430Usart as Usart;
  provides interface HplMsp430UsartInterrupts as Interrupts;
  provides interface HplMsp430I2CInterrupts as I2CInterrupts;
  
  uses interface HplMsp430I2C as HplI2C;
  uses interface HplMsp430GeneralIO as SIMO;
  uses interface HplMsp430GeneralIO as SOMI;
  uses interface HplMsp430GeneralIO as UCLK;
  uses interface HplMsp430GeneralIO as URXD;
  uses interface HplMsp430GeneralIO as UTXD;
}

implementation
{
  MSP430REG_NORACE(IE1);
  MSP430REG_NORACE(ME1);
  MSP430REG_NORACE(IFG1);
  MSP430REG_NORACE(U0TCTL);
  MSP430REG_NORACE(U0RCTL);
  MSP430REG_NORACE(U0TXBUF);
  
  TOSH_SIGNAL(UART0RX_VECTOR) {
    uint8_t temp = U0RXBUF;
    signal Interrupts.rxDone(temp);
  }
  
  TOSH_SIGNAL(UART0TX_VECTOR) {
    if ( call HplI2C.isI2C() )
      signal I2CInterrupts.fired();
    else
      signal Interrupts.txDone();
  }
  
  async command void Usart.setUctl(msp430_uctl_t control) {
    U0CTL=uctl2int(control);
  }

  async command msp430_uctl_t Usart.getUctl() {
    return int2uctl(U0CTL);
  }

  async command void Usart.setUtctl(msp430_utctl_t control) {
    U0TCTL=utctl2int(control);
  }

  async command msp430_utctl_t Usart.getUtctl() {
    return int2utctl(U0TCTL);
  }

  async command void Usart.setUrctl(msp430_urctl_t control) {
    U0RCTL=urctl2int(control);
  }

  async command msp430_urctl_t Usart.getUrctl() {
    return int2urctl(U0RCTL);
  }

  async command void Usart.setUbr(uint16_t control) {
    atomic {
      U0BR0 = control & 0x00FF;
      U0BR1 = (control >> 8) & 0x00FF;
    }
  }

  async command uint16_t Usart.getUbr() {
    return (U0BR1 << 8) + U0BR0;
  }

  async command void Usart.setUmctl(uint8_t control) {
    U0MCTL=control;
  }

  async command uint8_t Usart.getUmctl() {
    return U0MCTL;
  }

  async command void Usart.resetUsart(bool reset) {
    if (reset) {
      U0CTL = SWRST;
    }
    else {
      CLR_FLAG(U0CTL, SWRST);
    }
  }

  async command bool Usart.isSpi() {
    atomic {
      return (U0CTL & SYNC) && (ME1 & USPIE0);
    }
  }

  async command bool Usart.isUart() {
    atomic {
      return !(U0CTL & SYNC) && ((ME1 & UTXE0) && (ME1 & URXE0));
    }
  }

  async command bool Usart.isUartTx() {
    atomic {
      return !(U0CTL & SYNC) && (ME1 & UTXE0);
    }
  }

  async command bool Usart.isUartRx() {
    atomic {
      return !(U0CTL & SYNC) && (ME1 & URXE0);
    }
  }

  async command msp430_usartmode_t Usart.getMode() {
    if (call Usart.isUart())
      return USART_UART;
    else if (call Usart.isUartRx())
      return USART_UART_RX;
    else if (call Usart.isUartTx())
      return USART_UART_TX;
    else if (call Usart.isSpi())
      return USART_SPI;
    else if (call HplI2C.isI2C())
      return USART_I2C;
    else
      return USART_NONE;
  }

  async command void Usart.enableUart() {
    atomic{
      call UTXD.selectModuleFunc();
      call URXD.selectModuleFunc();
    }
    ME1 |= (UTXE0 | URXE0);   // USART0 UART module enable
  }

  async command void Usart.disableUart() {
    atomic {
      ME1 &= ~(UTXE0 | URXE0);   // USART0 UART module enable
      call UTXD.selectIOFunc();
      call URXD.selectIOFunc();
    }

  }

  async command void Usart.enableUartTx() {
    call UTXD.selectModuleFunc();
    ME1 |= UTXE0;   // USART0 UART Tx module enable
  }

  async command void Usart.disableUartTx() {
    ME1 &= ~UTXE0;   // USART0 UART Tx module enable
    call UTXD.selectIOFunc();

  }

  async command void Usart.enableUartRx() {
    call URXD.selectModuleFunc();
    ME1 |= URXE0;   // USART0 UART Rx module enable
  }

  async command void Usart.disableUartRx() {
    ME1 &= ~URXE0;  // USART0 UART Rx module disable
    call URXD.selectIOFunc();

  }

  async command void Usart.enableSpi() {
    atomic {
      call SIMO.selectModuleFunc();
      call SOMI.selectModuleFunc();
      call UCLK.selectModuleFunc();
    }
    ME1 |= USPIE0;   // USART0 SPI module enable
  }

  async command void Usart.disableSpi() {
    atomic {
      ME1 &= ~USPIE0;   // USART0 SPI module disable
      call SIMO.selectIOFunc();
      call SOMI.selectIOFunc();
      call UCLK.selectIOFunc();
    }
  }
  
  void configSpi(msp430_spi_union_config_t* config) {
    // U0CTL = (config->spiRegisters.uctl & ~I2C) | SYNC | SWRST;
    U0CTL = (config->spiRegisters.uctl) | SYNC | SWRST;  
    U0TCTL = config->spiRegisters.utctl;

    call Usart.setUbr(config->spiRegisters.ubr);
    call Usart.setUmctl(0x00);
  }

  async command void Usart.setModeSpi(msp430_spi_union_config_t* config) {
    
    atomic {
    	call Usart.resetUsart(TRUE);
    	call HplI2C.clearModeI2C();
    	call Usart.disableUart();
      configSpi(config);
      call Usart.enableSpi();
      call Usart.resetUsart(FALSE);
      call Usart.clrIntr();
      call Usart.disableIntr();
    }    
    return;
  }

  void configUart(msp430_uart_union_config_t* config) {

    U0CTL = (config->uartRegisters.uctl & ~SYNC) | SWRST;
    U0TCTL = config->uartRegisters.utctl;
    U0RCTL = config->uartRegisters.urctl;        
    
    call Usart.setUbr(config->uartRegisters.ubr);
    call Usart.setUmctl(config->uartRegisters.umctl);
  }

  async command void Usart.setModeUart(msp430_uart_union_config_t* config) {

    atomic { 
      call Usart.resetUsart(TRUE);
     	call HplI2C.clearModeI2C();
    	call Usart.disableSpi();
      configUart(config);
      if ((config->uartConfig.utxe == 1) && (config->uartConfig.urxe == 1)) {
      	call Usart.enableUart();
      } else if ((config->uartConfig.utxe == 0) && (config->uartConfig.urxe == 1)) {
        call Usart.disableUartTx();
        call Usart.enableUartRx();
      } else if ((config->uartConfig.utxe == 1) && (config->uartConfig.urxe == 0)){
        call Usart.disableUartRx();
        call Usart.enableUartTx();
      } else {
        call Usart.disableUart();
      }
      call Usart.resetUsart(FALSE);
      call Usart.clrIntr();
      call Usart.disableIntr();
    }
    
    return;
  }

  async command bool Usart.isTxIntrPending(){
    if (IFG1 & UTXIFG0){
      return TRUE;
    }
    return FALSE;
  }

  async command bool Usart.isTxEmpty(){
    if (U0TCTL & TXEPT) {
      return TRUE;
    }
    return FALSE;
  }

  async command bool Usart.isRxIntrPending(){
    if (IFG1 & URXIFG0){
      return TRUE;
    }
    return FALSE;
  }

  async command void Usart.clrTxIntr(){
    IFG1 &= ~UTXIFG0;
  }

  async command void Usart.clrRxIntr() {
    IFG1 &= ~URXIFG0;
  }

  async command void Usart.clrIntr() {
    IFG1 &= ~(UTXIFG0 | URXIFG0);
  }

  async command void Usart.disableRxIntr() {
    IE1 &= ~URXIE0;
  }

  async command void Usart.disableTxIntr() {
    IE1 &= ~UTXIE0;
  }

  async command void Usart.disableIntr() {
      IE1 &= ~(UTXIE0 | URXIE0);
  }

  async command void Usart.enableRxIntr() {
    atomic {
      IFG1 &= ~URXIFG0;
      IE1 |= URXIE0;
    }
  }

  async command void Usart.enableTxIntr() {
    atomic {
      IFG1 &= ~UTXIFG0;
      IE1 |= UTXIE0;
    }
  }

  async command void Usart.enableIntr() {
    atomic {
      IFG1 &= ~(UTXIFG0 | URXIFG0);
      IE1 |= (UTXIE0 | URXIE0);
    }
  }

  async command void Usart.tx(uint8_t data) {
    U0TXBUF = data;
  }

  async command uint8_t Usart.rx() {
    return U0RXBUF;
  }

  default async event void I2CInterrupts.fired() {}
  default async command bool HplI2C.isI2C() { return FALSE; }
  default async command void HplI2C.clearModeI2C() {};
  
}
