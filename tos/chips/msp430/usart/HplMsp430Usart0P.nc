/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 * - Neither the name of the Arch Rock Corporation nor the names of
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

/*
 * Copyright (c) 2004-2005, Technische Universitat Berlin
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
 */

/**
 * Implementation of USART0 lowlevel functionality - stateless.
 * Setting a mode will by default disable USART-Interrupts.
 *
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * @author: Jonathan Hui <jhui@archrock.com>
 * @author: Joe Polastre
 * @version $Revision: 1.2 $ $Date: 2006-07-12 17:01:46 $
 */

module HplMsp430Usart0P {
  provides interface AsyncStdControl;
  provides interface HplMsp430Usart as Usart;
  provides interface HplMsp430UsartInterrupts as Interrupts;

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
  MSP430REG_NORACE(U0TXBUF);

  uint16_t l_br;
  uint8_t l_mctl;
  uint8_t l_ssel;
  
  TOSH_SIGNAL(UART0RX_VECTOR) {
    uint8_t temp = U0RXBUF;
    signal Interrupts.rxDone(temp);
  }
  
  TOSH_SIGNAL(UART0TX_VECTOR) {
    signal Interrupts.txDone();
  }
  
  async command error_t AsyncStdControl.start() {
    return SUCCESS;
  }
  
  async command error_t AsyncStdControl.stop() {
    call Usart.disableSPI();
    call Usart.disableI2C();
    call Usart.disableUART();
    return SUCCESS;
  }

  async command bool Usart.isSPI() {
    atomic {
      return (U0CTL & SYNC) && (ME1 & USPIE0);
    }
  }

  async command bool Usart.isUART() {
    atomic {
      return !(U0CTL & SYNC) && ((ME1 & UTXE0) && (ME1 & URXE0));
    }
  }

  async command bool Usart.isUARTtx() {
    atomic {
      return !(U0CTL & SYNC) && (ME1 & UTXE0);
    }
  }

  async command bool Usart.isUARTrx() {
    atomic {
      return !(U0CTL & SYNC) && (ME1 & URXE0);
    }
  }

  async command bool Usart.isI2C() {
    atomic {
      return ((U0CTL & I2C) && (U0CTL & SYNC) && (U0CTL & I2CEN));
    }
  }

  async command msp430_usartmode_t Usart.getMode() {
    if (call Usart.isUART())
      return USART_UART;
    else if (call Usart.isUARTrx())
      return USART_UART_RX;
    else if (call Usart.isUARTtx())
      return USART_UART_TX;
    else if (call Usart.isSPI())
      return USART_SPI;
    else if (call Usart.isI2C())
      return USART_I2C;
    else
      return USART_NONE;
  }

  /**
   * Sets the USART mode to one of the options from msp430_usartmode_t
   * defined in MSP430Usart.h
   */
  async command void Usart.setMode(msp430_usartmode_t _mode) {
    switch (_mode) {
    case USART_UART:
      call Usart.setModeUART();
      break;
    case USART_UART_RX:
      call Usart.setModeUART_RX();
      break;
    case USART_UART_TX:
      call Usart.setModeUART_TX();
      break;
    case USART_SPI:
      call Usart.setModeSPI();
      break;
    case USART_I2C:
      call Usart.setModeI2C();
      break;
    default:
      break;
    }
  }

  async command void Usart.enableUART() {
    atomic{
      call UTXD.selectModuleFunc();
      call URXD.selectModuleFunc();
    }
    ME1 |= (UTXE0 | URXE0);   // USART0 UART module enable
  }

  async command void Usart.disableUART() {
    ME1 &= ~(UTXE0 | URXE0);   // USART0 UART module enable
    atomic {
      call UTXD.selectIOFunc();
      call URXD.selectIOFunc();
    }

  }

  async command void Usart.enableUARTTx() {
    call UTXD.selectModuleFunc();
    ME1 |= UTXE0;   // USART0 UART Tx module enable
  }

  async command void Usart.disableUARTTx() {
    ME1 &= ~UTXE0;   // USART0 UART Tx module enable
    call UTXD.selectIOFunc();

  }

  async command void Usart.enableUARTRx() {
    call URXD.selectModuleFunc();
    ME1 |= URXE0;   // USART0 UART Rx module enable
  }

  async command void Usart.disableUARTRx() {
    ME1 &= ~URXE0;  // USART0 UART Rx module disable
    call URXD.selectIOFunc();

  }

  async command void Usart.enableSPI() {
    ME1 |= USPIE0;   // USART0 SPI module enable
    //FIXME: Set pins in ModuleFunction?
    atomic {
      call SIMO.selectModuleFunc();
      call SOMI.selectModuleFunc();
      call UCLK.selectModuleFunc();
    }
  }

  async command void Usart.disableSPI() {
    ME1 &= ~USPIE0;   // USART0 SPI module disable
    atomic {
      call SIMO.selectIOFunc();
      call SOMI.selectIOFunc();
      call UCLK.selectIOFunc();
    }
  }

  async command void Usart.enableI2C() {
    atomic U0CTL |= I2C | I2CEN | SYNC;
  }

  async command void Usart.disableI2C() {
    atomic U0CTL &= ~(I2C | I2CEN | SYNC);
  }

  async command void Usart.setModeSPI() {
    // check if we are already in SPI mode
    if (call Usart.isSPI())
      return;

    call Usart.disableUART();
    call Usart.disableI2C();

    atomic {
      call SIMO.selectModuleFunc();
      call SOMI.selectModuleFunc();
      call UCLK.selectModuleFunc();

      U0CTL = SWRST;
      U0CTL |= CHAR | SYNC | MM;  // 8-bit char, SPI-mode, USART as master
      U0CTL &= ~(0x20);

      U0TCTL = STC ;     // 3-pin
      U0TCTL |= CKPH;    // half-cycle delayed UCLK

      U0TCTL &= ~(SSEL_0 | SSEL_1 | SSEL_2 | SSEL_3);
      if (l_ssel & 0x80)
        U0TCTL |= (l_ssel & 0x7F);
      else
        U0TCTL |= SSEL_SMCLK; // use SMCLK, assuming 1MHz

      if (l_br != 0) {
        U0BR0 = l_br & 0x0FF;
        U0BR1 = (l_br >> 8) & 0x0FF;
      }
      else {
        U0BR0 = 0x02;   // as fast as possible
        U0BR1 = 0x00;
      }
      U0MCTL = 0;

      ME1 |= USPIE0;   // USART SPI module enable
      U0CTL &= ~SWRST;

      IFG1 &= ~(UTXIFG0 | URXIFG0);
      IE1 &= ~(UTXIE0 | URXIE0);  // interrupt disabled
    }
    return;
  }

  void setUARTModeCommon() {
    atomic {
      U0CTL = SWRST;
      U0CTL |= CHAR;  // 8-bit char, UART-mode

      U0RCTL &= ~URXEIE;  // even erroneous characters trigger interrupts


      U0CTL = SWRST;
      U0CTL |= CHAR;  // 8-bit char, UART-mode

      if (l_ssel & 0x80) {
        U0TCTL &= ~SSEL_3;
        U0TCTL |= (l_ssel & 0x7F);
      }
      else {
        U0TCTL &= ~SSEL_3;
        U0TCTL |= SSEL_ACLK; // use ACLK, assuming 32khz
      }

      if ((l_mctl != 0) || (l_br != 0)) {
        U0BR0 = l_br & 0x0FF;
        U0BR1 = (l_br >> 8) & 0x0FF;
        U0MCTL = l_mctl;
      }
      else {
        U0BR0 = 0x03;   // 9600 baud
        U0BR1 = 0x00;
        U0MCTL = 0x4A;
      }

      ME1 &= ~USPIE0;   // USART0 SPI module disable
      ME1 |= (UTXE0 | URXE0); //USART0 UART module enable;

      U0CTL &= ~SWRST;

      IFG1 &= ~(UTXIFG0 | URXIFG0);
      IE1 &= ~(UTXIE0 | URXIE0);  // interrupt disabled
    }
    return;
  }

  async command void Usart.setModeUART_TX() {
    // check if we are already in UART mode
    if (call Usart.getMode() == USART_UART_TX)
      return;

    call Usart.disableSPI();
    call Usart.disableI2C();
    call Usart.disableUART();

    atomic {
      call UTXD.selectModuleFunc();
      call URXD.selectIOFunc();
    }
    setUARTModeCommon();
    return;
  }

  async command void Usart.setModeUART_RX() {
    // check if we are already in UART mode
    if (call Usart.getMode() == USART_UART_RX)
      return;

    call Usart.disableSPI();
    call Usart.disableI2C();
    call Usart.disableUART();

    atomic {
      call UTXD.selectIOFunc();
      call URXD.selectModuleFunc();
    }
    setUARTModeCommon();
    return;
  }

  async command void Usart.setModeUART() {
    // check if we are already in UART mode
    if (call Usart.getMode() == USART_UART)
      return;

    call Usart.disableSPI();
    call Usart.disableI2C();
    call Usart.disableUART();

    atomic {
      call UTXD.selectModuleFunc();
      call URXD.selectModuleFunc();
    }
    setUARTModeCommon();
    return;
  }

  // i2c enable bit is not set by default
  async command void Usart.setModeI2C() {
    // check if we are already in I2C mode
    if (call Usart.getMode() == USART_I2C)
      return;

    call Usart.disableUART();
    call Usart.disableSPI();

    atomic {
      call SIMO.makeInput();
      call UCLK.makeInput();
      call SIMO.selectModuleFunc();
      call UCLK.selectModuleFunc();

      IE1 &= ~(UTXIE0 | URXIE0);  // interrupt disable

      U0CTL = SWRST;
      U0CTL |= SYNC | I2C;  // 7-bit addr, I2C-mode, USART as master
      U0CTL &= ~I2CEN;

      U0CTL |= MST;

      I2CTCTL = I2CSSEL_2;        // use 1MHz SMCLK as the I2C reference

      I2CPSC = 0x00;              // I2C CLK runs at 1MHz/10 = 100kHz
      I2CSCLH = 0x03;
      I2CSCLL = 0x03;

      I2CIE = 0;                 // clear all I2C interrupt enables
      I2CIFG = 0;                // clear all I2C interrupt flags
    }
    return;
  }

  async command void Usart.setClockSource(uint8_t source) {
    atomic {
      l_ssel = source | 0x80;
      U0TCTL &= ~SSEL_3;
      U0TCTL |= (l_ssel & 0x7F);
    }
  }

  async command void Usart.setClockRate(uint16_t baudrate, uint8_t mctl) {
    atomic {
      l_br = baudrate;
      l_mctl = mctl;
      U0BR0 = baudrate & 0x0FF;
      U0BR1 = (baudrate >> 8) & 0x0FF;
      U0MCTL = mctl;
    }
  }

  async command bool Usart.isTxIntrPending(){
    if (IFG1 & UTXIFG0){
      IFG1 &= ~UTXIFG0;
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
//      IFG1 &= ~URXIFG0;
      return TRUE;
    }
    return FALSE;
  }

  async command error_t Usart.clrTxIntr(){
    IFG1 &= ~UTXIFG0;
    return SUCCESS;
  }

  async command error_t Usart.clrRxIntr() {
    IFG1 &= ~URXIFG0;
    return SUCCESS;
  }

  async command void Usart.disableRxIntr(){
    IE1 &= ~URXIE0;
  }

  async command void Usart.disableTxIntr(){
    IE1 &= ~UTXIE0;
  }

  async command void Usart.enableRxIntr(){
    atomic {
      IFG1 &= ~URXIFG0;
      IE1 |= URXIE0;
    }
  }

  async command void Usart.enableTxIntr(){
    atomic {
      IFG1 &= ~UTXIFG0;
      IE1 |= UTXIE0;
    }
  }

  async command void Usart.tx(uint8_t data){
    atomic U0TXBUF = data;
  }

  async command uint8_t Usart.rx(){
    uint8_t value;
    atomic value = U0RXBUF;
    return value;
  }

}
