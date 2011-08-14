/*
 * Copyright (c) 2010-2011, Eric B. Decker
 * Copyright (c) 2009 DEXMA SENSORS SL
 * Copyright (c) 2005-2006, Arch Rock Corporation
 * Copyright (c) 2004-2005, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "msp430usci.h"

/*
 * Implementation of usci A0 (uart or spi) low level functionality - stateless.
 * Setting a mode will by default disable USCI-Interrupts.
 *
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * @author: Jonathan Hui <jhui@archedrock.com>
 * @author: Vlado Handziski <handzisk@tkn.tu-berlin.de>
 * @author: Joe Polastre
 * @author: Philipp Huppertz <huppertz@tkn.tu-berlin.de>
 * @author: Xavier Orduna <xorduna@dexmatech.com>
 * @author: Eric B. Decker <cire831@gmail.com>
 *
 * A0, A1: uart, spi, irda.
 * B0, B1: spi, i2c.
 *
 * This module interfaces to usciA0: uart or spi.
 */

module HplMsp430UsciA0P @safe() {
  provides {
    interface HplMsp430UsciA as Usci;
    interface HplMsp430UsciInterrupts as Interrupts;
  }
  uses {
    interface HplMsp430GeneralIO as SIMO;
    interface HplMsp430GeneralIO as SOMI;
    interface HplMsp430GeneralIO as UCLK;
    interface HplMsp430GeneralIO as URXD;
    interface HplMsp430GeneralIO as UTXD;
    interface HplMsp430UsciRawInterrupts as UsciRawInterrupts;
  }
}

implementation {
  MSP430REG_NORACE(IE2);
  MSP430REG_NORACE(IFG2);
  MSP430REG_NORACE(UCA0CTL0);
  MSP430REG_NORACE(UCA0CTL1);
  MSP430REG_NORACE(UCA0TXBUF);

  async event void UsciRawInterrupts.rxDone(uint8_t temp) {
    signal Interrupts.rxDone(temp);
  }

  async event void UsciRawInterrupts.txDone() {
    signal Interrupts.txDone();
  }

  /* Control registers */
  async command void Usci.setUctl0(msp430_uctl0_t control) {
    UCA0CTL0 = uctl02int(control);
  }

  async command msp430_uctl0_t Usci.getUctl0() {
    return int2uctl0(UCA0CTL0);
  }

  async command void Usci.setUctl1(msp430_uctl1_t control) {
    UCA0CTL1 = uctl12int(control);
  }

  async command msp430_uctl1_t Usci.getUctl1() {
    return int2uctl1(UCA0CTL0);
  }

  async command void Usci.setUbr(uint16_t control) {
    atomic {
      UCA0BR0 = control & 0x00FF;
      UCA0BR1 = (control >> 8) & 0x00FF;
    }
  }

  async command uint16_t Usci.getUbr() {
    return (UCA0BR1 << 8) + UCA0BR0;
  }

  async command void Usci.setUmctl(uint8_t control) {
    UCA0MCTL=control;
  }

  async command uint8_t Usci.getUmctl() {
    return UCA0MCTL;
  }

  async command void Usci.setUstat(uint8_t control) {
    UCA0STAT = control;
  }

  async command uint8_t Usci.getUstat() {
    return UCA0STAT;
  }

  /* Operations */
  async command void Usci.resetUsci(bool reset) {
    if (reset)
      SET_FLAG(UCA0CTL1, UCSWRST);
    else
      CLR_FLAG(UCA0CTL1, UCSWRST);
  }

  bool isSpi() {
    msp430_uctl0_t tmp;

    tmp = int2uctl0(UCA0CTL0);
    return (tmp.ucsync && tmp.ucmode != 3);
  }

  bool isI2C() {
    msp430_uctl0_t tmp;

    tmp = int2uctl0(UCA0CTL0);
    return (tmp.ucsync && tmp.ucmode == 3);
  }

  bool isUart() {
    msp430_uctl0_t tmp;

    tmp = int2uctl0(UCA0CTL0);
    return (tmp.ucsync == 0);
  }

  async command bool Usci.isSpi() {
    return isSpi();
  }

  async command msp430_uscimode_t Usci.getMode() {
    if (isSpi())
      return USCI_SPI;
    if (isI2C())
      return USCI_I2C;
    if (isUart())
      return USCI_UART;
    else
      return USCI_NONE;
  }

  async command void Usci.enableSpi() {
    atomic {
      call SIMO.selectModuleFunc();
      call SOMI.selectModuleFunc();
      call UCLK.selectModuleFunc();
    }
  }

  async command void Usci.disableSpi() {
    atomic {
      call SIMO.selectIOFunc();
      call SOMI.selectIOFunc();
      call UCLK.selectIOFunc();
    }
  }

  void configSpi(msp430_spi_union_config_t* config) {
    UCA0CTL1 = (config->spiRegisters.uctl1 | UCSWRST);
    UCA0CTL0 = (config->spiRegisters.uctl0 | UCSYNC);
    call Usci.setUbr(config->spiRegisters.ubr);
    call Usci.setUmctl(0);		/* MCTL <- 0 if spi */
  }

  async command void Usci.setModeSpi(msp430_spi_union_config_t* config) {
    atomic {
      call Usci.disableIntr();
      call Usci.clrIntr();
      call Usci.resetUsci(TRUE);
      call Usci.enableSpi();
      configSpi(config);
      call Usci.resetUsci(FALSE);
    }    
  }

  async command bool Usci.isTxIntrPending(){
    if (IFG2 & UCA0TXIFG)
      return TRUE;
    return FALSE;
  }

  async command bool Usci.isRxIntrPending(){
    if (IFG2 & UCA0RXIFG)
      return TRUE;
    return FALSE;
  }

  async command void Usci.clrTxIntr(){
    IFG2 &= ~UCA0TXIFG;
  }

  async command void Usci.clrRxIntr() {
    IFG2 &= ~UCA0RXIFG;
  }

  async command void Usci.clrIntr() {
    IFG2 &= ~(UCA0TXIFG | UCA0RXIFG);
  }

  async command void Usci.disableRxIntr() {
    IE2 &= ~UCA0RXIE;
  }

  async command void Usci.disableTxIntr() {
    IE2 &= ~UCA0TXIE;
  }

  async command void Usci.disableIntr() {
      IE2 &= ~(UCA0TXIE | UCA0RXIE);
  }

  async command void Usci.enableRxIntr() {
    atomic {
      IFG2 &= ~UCA0RXIFG;
      IE2  |=  UCA0RXIE;
    }
  }

  async command void Usci.enableTxIntr() {
    atomic {
      IFG2 &= ~UCA0TXIFG;
      IE2  |=  UCA0TXIE;
    }
  }

  async command void Usci.enableIntr() {
    atomic {
      IFG2 &= ~(UCA0TXIFG | UCA0RXIFG);
      IE2  |=  (UCA0TXIE  | UCA0RXIE);
    }
  }

  /*
   * Returns true if the transmit path is empty.
   *
   * in the usart hardware there was a seperate bit that indicated
   * both parts of the transmitter path were empty.  The TXBUF and
   * the outgoing shift register.
   *
   * Unfortunately, TI changed this in the USCI h/w to a single busy
   * bit that indcates that either the tx or the rx path is busy.
   * So if the transmitter is idle but we are receiving a character
   * then we still think the transmitter is busy.  TI sucks.
   */
  async command bool Usci.isTxEmpty() {
    if (UCA0STAT & UCBUSY)
      return FALSE;
    return TRUE;
  }

  async command void Usci.tx(uint8_t data) {
    UCA0TXBUF = data;
  }

  async command uint8_t Usci.rx() {
    return UCA0RXBUF;
  }

  async command bool Usci.isUart() {
    return isUart();
  }

  async command void Usci.enableUart() {
    atomic {
      call UTXD.selectModuleFunc();
      call URXD.selectModuleFunc();
    }
  }

  async command void Usci.disableUart() {
    atomic {
      call UTXD.selectIOFunc();
      call URXD.selectIOFunc();
    }
  }

  void configUart(msp430_uart_union_config_t* config) {
    UCA0CTL1 = (config->uartRegisters.uctl1 | UCSWRST);
    UCA0CTL0 = config->uartRegisters.uctl0;		/* ucsync should be off */
    call Usci.setUbr(config->uartRegisters.ubr);
    call Usci.setUmctl(config->uartRegisters.umctl);
  }

  async command void Usci.setModeUart(msp430_uart_union_config_t* config) {
    atomic { 
      call Usci.disableIntr();
      call Usci.clrIntr();
      call Usci.resetUsci(TRUE);
      call Usci.enableUart();
      configUart(config);
      call Usci.resetUsci(FALSE);
    }
  }
}
