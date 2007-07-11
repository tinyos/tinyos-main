// $Id: HPLUSART0M.nc,v 1.1 2007-07-11 00:42:57 razvanm Exp $

/*									tab:2
 *
 *
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/**
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

module HPLUSART0M {
  provides interface HPLUSARTControl;
}
implementation {

  command void HPLUSARTControl.disableSPI() {
    // USART0 SPI module disable
    //ME1 &= ~USPIE0;

    // set to PUC values
    ME1 = 0;
    U0CTL = 1;
    U0TCTL = 1;
    U0RCTL = 0;
  }
  
  command void HPLUSARTControl.setModeSPI() {

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

  command void HPLUSARTControl.disableI2C() {
    /*
    U0CTL = 1;
    U0TCTL = 1;
    I2CTCTL = 0;
    */
    U0CTL &= ~I2CEN;
    U0CTL &= ~I2C;
    I2CTCTL = 0;
    call HPLUSARTControl.disableSPI();
  }

  command void HPLUSARTControl.setModeI2C() {
   
    // Recommended init procedure
    U0CTL = I2C + SYNC + MST;

    // use 1MHz SMCLK as the I2C reference
    I2CTCTL |= I2CSSEL_2 | I2CTRX;

    // Enable I2C
    U0CTL |= I2CEN;

    return;
  }

  command error_t HPLUSARTControl.isTxEmpty(){
    if (U0TCTL & TXEPT) {
      return SUCCESS;
    }
    return FAIL;
  }
  
  command error_t HPLUSARTControl.isTxIntrPending(){
    if (IFG1 & UTXIFG0){
      IFG1 &= ~UTXIFG0;
      return SUCCESS;
    }
    return FAIL;
  }

  command error_t HPLUSARTControl.isRxIntrPending(){
    if (IFG1 & URXIFG0){
      IFG1 &= ~URXIFG0;
      return SUCCESS;
    }
    return FAIL;
  }

  command void HPLUSARTControl.tx(uint8_t data){
    U0TXBUF = data;
  }
  
  command uint8_t HPLUSARTControl.rx(){
    return U0RXBUF;
  }

}
