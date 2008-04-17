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
 * Implementation of USART1 lowlevel functionality - stateless.
 * Setting a mode will by default disable USART-Interrupts.
 *
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * @author: Jonathan Hui <jhui@archedrock.com>
 * @author: Vlado Handziski <handzisk@tkn.tu-berlin.de>
 * @author: Joe Polastre
 * @version $Revision: 1.5 $ $Date: 2008-04-17 22:38:34 $
 */

module HplMsp430Usart1P {
  provides interface AsyncStdControl;
  provides interface HplMsp430Usart as Usart;
  provides interface HplMsp430UsartInterrupts as Interrupts;

  uses interface HplMsp430GeneralIO as SIMO;
  uses interface HplMsp430GeneralIO as SOMI;
  uses interface HplMsp430GeneralIO as UCLK;
  uses interface HplMsp430GeneralIO as URXD;
  uses interface HplMsp430GeneralIO as UTXD;
  uses interface HplMsp430InterruptSig as SIGNAL_UART1RX_VECTOR;
  uses interface HplMsp430InterruptSig as SIGNAL_UART1TX_VECTOR;
}

implementation
{
  MSP430REG_NORACE(IE2);
  MSP430REG_NORACE(ME2);
  MSP430REG_NORACE(IFG2);
  MSP430REG_NORACE(U1TCTL);
  MSP430REG_NORACE(U1RCTL);
  MSP430REG_NORACE(U1TXBUF);

  inline async event void SIGNAL_UART1RX_VECTOR.fired() {
    uint8_t temp = U1RXBUF;
    signal Interrupts.rxDone(temp);
  }

  inline async event void SIGNAL_UART1TX_VECTOR.fired() {
    signal Interrupts.txDone();
  }

  async command error_t AsyncStdControl.start() {
    return SUCCESS;
  }

  async command error_t AsyncStdControl.stop() {
    call Usart.disableSpi();
    call Usart.disableUart();
    return SUCCESS;
  }


  async command void Usart.setUctl(msp430_uctl_t control) {
    U1CTL=uctl2int(control);
  }

  async command msp430_uctl_t Usart.getUctl() {
    return int2uctl(U0CTL);
  }

  async command void Usart.setUtctl(msp430_utctl_t control) {
    U1TCTL=utctl2int(control);
  }

  async command msp430_utctl_t Usart.getUtctl() {
    return int2utctl(U1TCTL);
  }

  async command void Usart.setUrctl(msp430_urctl_t control) {
    U1RCTL=urctl2int(control);
  }

  async command msp430_urctl_t Usart.getUrctl() {
    return int2urctl(U1RCTL);
  }

  async command void Usart.setUbr(uint16_t control) {
    atomic {
      U1BR0 = control & 0x00FF;
      U1BR1 = (control >> 8) & 0x00FF;
    }
  }

  async command uint16_t Usart.getUbr() {
    return (U1BR1 << 8) + U1BR0;
  }

  async command void Usart.setUmctl(uint8_t control) {
    U1MCTL=control;
  }

  async command uint8_t Usart.getUmctl() {
    return U1MCTL;
  }

  async command void Usart.resetUsart(bool reset) {
    if (reset)
      U1CTL = SWRST;
    else
      CLR_FLAG(U1CTL, SWRST);
  }

  async command bool Usart.isSpi() {
    atomic {
      return (U1CTL & SYNC) && (ME2 & USPIE1);
    }
  }

  async command bool Usart.isUart() {
    atomic {
      return !(U1CTL & SYNC) && ((ME2 & UTXE1) && (ME2 & URXE1));
    }
  }

  async command bool Usart.isUartTx() {
    atomic {
      return !(U1CTL & SYNC) && (ME2 & UTXE1);
    }
  }

  async command bool Usart.isUartRx() {
    atomic {
      return !(U1CTL & SYNC) && (ME2 & URXE1);
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
    else
      return USART_NONE;
  }

  async command void Usart.enableUart() {
    atomic{
      call UTXD.selectModuleFunc();
      call URXD.selectModuleFunc();
    }
    ME2 |= (UTXE1 | URXE1);   // USART1 UART module enable
  }

  async command void Usart.disableUart() {
    atomic {
      ME2 &= ~(UTXE1 | URXE1);   // USART1 UART module enable
      call UTXD.selectIOFunc();
      call URXD.selectIOFunc();
    }

  }

  async command void Usart.enableUartTx() {
    call UTXD.selectModuleFunc();
    ME2 |= UTXE1;   // USART1 UART Tx module enable
  }

  async command void Usart.disableUartTx() {
    ME2 &= ~UTXE1;   // USART1 UART Tx module enable
    call UTXD.selectIOFunc();

  }

  async command void Usart.enableUartRx() {
    call URXD.selectModuleFunc();
    ME2 |= URXE1;   // USART1 UART Rx module enable
  }

  async command void Usart.disableUartRx() {
    ME2 &= ~URXE1;  // USART1 UART Rx module disable
    call URXD.selectIOFunc();

  }

  async command void Usart.enableSpi() {
    atomic {
      call SIMO.selectModuleFunc();
      call SOMI.selectModuleFunc();
      call UCLK.selectModuleFunc();
    }
    ME2 |= USPIE1;   // USART1 SPI module enable
  }

  async command void Usart.disableSpi() {
    atomic {
      ME2 &= ~USPIE1;   // USART1 SPI module disable
      call SIMO.selectIOFunc();
      call SOMI.selectIOFunc();
      call UCLK.selectIOFunc();
    }
  }

  void configSpi(msp430_spi_union_config_t* config) {
    U1CTL = (config->spiRegisters.uctl) | SYNC | SWRST;  
    U1TCTL = config->spiRegisters.utctl;

    call Usart.setUbr(config->spiRegisters.ubr);
    call Usart.setUmctl(0x00);
  }


  async command void Usart.setModeSpi(msp430_spi_union_config_t* config) {    
    atomic {
      call Usart.resetUsart(TRUE);
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

    U1CTL = (config->uartRegisters.uctl & ~SYNC) | SWRST;
    U1TCTL = config->uartRegisters.utctl;
    U1RCTL = config->uartRegisters.urctl;        
    
    call Usart.setUbr(config->uartRegisters.ubr);
    call Usart.setUmctl(config->uartRegisters.umctl);
  }

  async command void Usart.setModeUart(msp430_uart_union_config_t* config) {

    atomic { 
      call Usart.resetUsart(TRUE);
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
    if (IFG2 & UTXIFG1){
      return TRUE;
    }
    return FALSE;
  }

  async command bool Usart.isTxEmpty(){
    if (U1TCTL & TXEPT) {
      return TRUE;
    }
    return FALSE;
  }

  async command bool Usart.isRxIntrPending(){
    if (IFG2 & URXIFG1){
      return TRUE;
    }
    return FALSE;
  }

  async command void Usart.clrTxIntr(){
    IFG2 &= ~UTXIFG1;
  }

  async command void Usart.clrRxIntr() {
    IFG2 &= ~URXIFG1;
  }

  async command void Usart.clrIntr() {
    IFG2 &= ~(UTXIFG1 | URXIFG1);
  }

  async command void Usart.disableRxIntr() {
    IE2 &= ~URXIE1;
  }

  async command void Usart.disableTxIntr() {
    IE2 &= ~UTXIE1;
  }

  async command void Usart.disableIntr() {
      IE2 &= ~(UTXIE1 | URXIE1);
  }

  async command void Usart.enableRxIntr() {
    atomic {
      IFG2 &= ~URXIFG1;
      IE2 |= URXIE1;
    }
  }

  async command void Usart.enableTxIntr() {
    atomic {
      IFG2 &= ~UTXIFG1;
      IE2 |= UTXIE1;
    }
  }

  async command void Usart.enableIntr() {
    atomic {
      IFG2 &= ~(UTXIFG1 | URXIFG1);
      IE2 |= (UTXIE1 | URXIE1);
    }
  }

  async command void Usart.tx(uint8_t data) {
    atomic U1TXBUF = data;
  }

  async command uint8_t Usart.rx() {
    uint8_t value;
    atomic value = U1RXBUF;
    return value;
  }

}
