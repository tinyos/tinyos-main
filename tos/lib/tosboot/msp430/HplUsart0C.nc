// $Id: HplUsart0C.nc,v 1.2 2010-06-29 22:07:50 scipio Exp $

/*
 *
 *
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
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
 *
 */

/**
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

module HplUsart0C {
  provides interface HplUsartControl;
}
implementation {

  command void HplUsartControl.disableSPI() {
    // USART0 SPI module disable
    //ME1 &= ~USPIE0;

    // set to PUC values
    ME1 = 0;
    U0CTL = 1;
    U0TCTL = 1;
    U0RCTL = 0;
  }
  
  command void HplUsartControl.setModeSPI() {

    //U0CTL = SWRST;

    // 8-bit char, SPI-mode, USART as master
    U0CTL = SWRST | CHAR | SYNC | MM;

    // 3-pin + half-cycle delayed UCLK
    U0TCTL |= STC + CKPH + SSEL_SMCLK; 

    // as fast as possible
    U0BR0 = 0x02;
    U0BR1 = 0;

    // enable SPI
    ME1 |= USPIE0;

    U0CTL &= ~SWRST;  
    
    // clear interrupts
    IFG1 = 0;

  }

  command void HplUsartControl.disableI2C() {
    /*
    U0CTL = 1;
    U0TCTL = 1;
    I2CTCTL = 0;
    */
    U0CTL &= ~I2CEN;
    U0CTL &= ~I2C;
    I2CTCTL = 0;
    call HplUsartControl.disableSPI();
  }

  command void HplUsartControl.setModeI2C() {
   
    // Recommended init procedure
    U0CTL = I2C + SYNC + MST;

    // use 1MHz SMCLK as the I2C reference
    I2CTCTL |= I2CSSEL_2 | I2CTRX;

    // Enable I2C
    U0CTL |= I2CEN;

    return;
  }

  command error_t HplUsartControl.isTxEmpty(){
    if (U0TCTL & TXEPT) {
      return SUCCESS;
    }
    return FAIL;
  }
  
  command error_t HplUsartControl.isTxIntrPending(){
    if (IFG1 & UTXIFG0){
      IFG1 &= ~UTXIFG0;
      return SUCCESS;
    }
    return FAIL;
  }

  command error_t HplUsartControl.isRxIntrPending(){
    if (IFG1 & URXIFG0){
      IFG1 &= ~URXIFG0;
      return SUCCESS;
    }
    return FAIL;
  }

  command void HplUsartControl.tx(uint8_t data){
    U0TXBUF = data;
  }
  
  command uint8_t HplUsartControl.rx(){
    return U0RXBUF;
  }

}
