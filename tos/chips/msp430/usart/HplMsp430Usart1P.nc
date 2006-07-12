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
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.2 $
 * $Date: 2006-07-12 17:01:46 $
 * ========================================================================
 */

/**
 * Implementation of USART0 lowlevel functionality - stateless.
 * Setting a mode will by default disable USART-Interrupts.
 *
 * @author Jan Hauer (hauer@tkn.tu-berlin.de)
 * @author Joe Polastre
 */

module HplMsp430Usart1P {
  provides interface HplMsp430Usart as Usart;
  provides interface HplMsp430UsartInterrupts as UsartInterrupts;

  uses interface HplMsp430GeneralIO as SIMO;
  uses interface HplMsp430GeneralIO as SOMI;
  uses interface HplMsp430GeneralIO as UCLK;
  uses interface HplMsp430GeneralIO as URXD;
  uses interface HplMsp430GeneralIO as UTXD;
}
implementation
{
  MSP430REG_NORACE(IE2);
  MSP430REG_NORACE(ME2);
  MSP430REG_NORACE(IFG2);
  MSP430REG_NORACE(U1TCTL);
  MSP430REG_NORACE(U1TXBUF);
  
  uint16_t l_br;
  uint8_t l_mctl;
  uint8_t l_ssel;
  
  TOSH_SIGNAL(UART1RX_VECTOR) {
    uint8_t temp = U1RXBUF;
    signal UsartInterrupts.rxDone(temp);
  }

  TOSH_SIGNAL(UART1TX_VECTOR) {
    signal UsartInterrupts.txDone();
  }

  async command bool Usart.isSPI() {
    bool _ret = FALSE;
    atomic{
      if (ME2 & USPIE1)
	_ret = TRUE;
    }
    return _ret;
  }
  
  async command bool Usart.isUART() {
    bool _ret = FALSE;
    atomic {
      if ((ME2 & UTXE1) && (ME2 & URXE1))
	_ret = TRUE;
    }
    return _ret;
  }
  
  async command bool Usart.isUARTtx() {
    bool _ret = FALSE;
    atomic {
      if (ME2 & UTXE1)
	_ret = TRUE;
    }
    return _ret;
  }
  
  async command bool Usart.isUARTrx() {
    bool _ret = FALSE;
    atomic {
      if (ME2 & URXE1)
	_ret = TRUE;
    }
    return _ret;
  }
  
  async command bool Usart.isI2C() {
    return FALSE;
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
    default:
      break;
    }
  }
  
  async command void Usart.enableUART() {
//    TOSH_SEL_UTXD1_MODFUNC();
//    TOSH_SEL_URXD1_MODFUNC();
    ME2 |= (UTXE1 | URXE1);   // USART1 UART module enable
  }
  
  async command void Usart.disableUART() {
    ME2 &= ~(UTXE1 | URXE1);   // USART0 UART module enable
    call UTXD.selectIOFunc();
    call URXD.selectIOFunc();
  }
  
  async command void Usart.enableUARTTx() {
    ME2 |= UTXE1;   // USART0 UART Tx module enable
  }
  
  async command void Usart.disableUARTTx() {
    ME2 &= ~UTXE1;   // USART0 UART Tx module enable
    call UTXD.selectIOFunc();
  }
  
  async command void Usart.enableUARTRx() {
    ME2 |= URXE1;   // USART0 UART Rx module enable
  }
  
  async command void Usart.disableUARTRx() {
    ME2 &= ~URXE1;  // USART0 UART Rx module disable
    call URXD.selectIOFunc();
  }

  async command void Usart.enableSPI() {
    ME2 |= USPIE1;   // USART0 SPI module enable
  }
  
  async command void Usart.disableSPI() {
    ME2 &= ~USPIE1;   // USART0 SPI module disable
    call SIMO.selectIOFunc();
    call SOMI.selectIOFunc();
    call UCLK.selectIOFunc();
  }
  
  async command void Usart.enableI2C() { }
  
  async command void Usart.disableI2C() { }

  async command void Usart.setModeSPI() {
    // check if we are already in SPI mode
    if (call Usart.getMode() == USART_SPI) 
      return;
    
    call Usart.disableUART();
    call Usart.disableI2C();
    
    atomic {
      call SIMO.selectModuleFunc();
      call SOMI.selectModuleFunc();
      call UCLK.selectModuleFunc();

      IE2 &= ~(UTXIE1 | URXIE1);  // interrupt disable    

      U1CTL = SWRST;
      U1CTL |= CHAR | SYNC | MM;  // 8-bit char, SPI-mode, USART as master
      U1CTL &= ~(0x20); 

      U1TCTL = STC ;     // 3-pin
      U1TCTL |= CKPH;    // half-cycle delayed UCLK

      if (l_ssel & 0x80) {
        U1TCTL &= ~(SSEL_0 | SSEL_1 | SSEL_2 | SSEL_3);
        U1TCTL |= (l_ssel & 0x7F); 
      }
      else {
        U1TCTL &= ~(SSEL_0 | SSEL_1 | SSEL_2 | SSEL_3);
        U1TCTL |= SSEL_SMCLK; // use SMCLK, assuming 1MHz
      }

      if (l_br != 0) {
        U1BR0 = l_br & 0x0FF;
        U1BR1 = (l_br >> 8) & 0x0FF;
      }
      else {
        U1BR0 = 0x02;   // as fast as possible
        U1BR1 = 0x00;
      }
      U1MCTL = 0;

      ME2 &= ~(UTXE1 | URXE1); //USART UART module disable
      ME2 |= USPIE1;   // USART SPI module enable
      U1CTL &= ~SWRST;  

      IFG2 &= ~(UTXIFG1 | URXIFG1);
      IE2 &= ~(UTXIE1 | URXIE1);  // interrupt disabled    
    }
    return;
  }
  
  void setUARTModeCommon() {
    atomic {
      U1CTL = SWRST;  
      U1CTL |= CHAR;  // 8-bit char, UART-mode

      U1RCTL &= ~URXEIE;  // even erroneous characters trigger interrupts

      
      U1CTL = SWRST;
      U1CTL |= CHAR;  // 8-bit char, UART-mode

      if (l_ssel & 0x80) {
        U1TCTL &= ~(SSEL_0 | SSEL_1 | SSEL_2 | SSEL_3);
        U1TCTL |= (l_ssel & 0x7F); 
      }
      else {
        U1TCTL &= ~(SSEL_0 | SSEL_1 | SSEL_2 | SSEL_3);
        U1TCTL |= SSEL_ACLK; // use ACLK, assuming 32khz
      }

      if ((l_mctl != 0) || (l_br != 0)) {
        U1BR0 = l_br & 0x0FF;
        U1BR1 = (l_br >> 8) & 0x0FF;
        U1MCTL = l_mctl;
      }
      else {
        U1BR0 = 0x03;   // 9600 baud
        U1BR1 = 0x00;
        U1MCTL = 0x4A;
      }

      ME2 &= ~USPIE1;   // USART0 SPI module disable
      ME2 |= (UTXE1 | URXE1); //USART0 UART module enable;
      
      U1CTL &= ~SWRST;

      IFG2 &= ~(UTXIFG1 | URXIFG1);
      IE2 &= ~(UTXIE1 | URXIE1);  // interrupt disabled
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

      IE2 &= ~(UTXIE1 | URXIE1);  // interrupt disable    

      U1CTL = SWRST;
      U1CTL |= SYNC | I2C;  // 7-bit addr, I2C-mode, USART as master
      U1CTL &= ~I2CEN;

      U1CTL |= MST;

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
      U1TCTL &= ~(SSEL_0 | SSEL_1 | SSEL_2 | SSEL_3);
      U1TCTL |= (l_ssel & 0x7F); 
    }
  }
  
  async command void Usart.setClockRate(uint16_t baudrate, uint8_t mctl) {
    atomic {
      l_br = baudrate;
      l_mctl = mctl;
      U1BR0 = baudrate & 0x0FF;
      U1BR1 = (baudrate >> 8) & 0x0FF;
      U1MCTL = mctl;
    }
  }

  async command bool Usart.isTxIntrPending(){
    if (IFG2 & UTXIFG1){
      IFG2 &= ~UTXIFG1;
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
      IFG2 &= ~URXIFG1;
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
    IE2 &= ~URXIE1;    
  }
  
  async command void Usart.disableTxIntr(){
    IE2 &= ~UTXIE1;  
  }
  
  async command void Usart.enableRxIntr(){
    atomic {
      IFG2 &= ~URXIFG1;
      IE2 |= URXIE1;  
    }
  }

  async command void Usart.enableTxIntr(){
    atomic {
      IFG2 &= ~UTXIFG1;
      IE2 |= UTXIE1;
    }
  }
  
  async command void Usart.tx(uint8_t data){
    atomic U1TXBUF = data;
  }
  
  async command uint8_t Usart.rx(){
    uint8_t value;
    atomic value = U1RXBUF;
    return value;
  }

}
