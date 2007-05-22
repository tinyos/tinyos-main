// $Id: ExtFlashM.nc,v 1.1 2007-05-22 20:34:22 razvanm Exp $

/*									tab:2
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
 */

/**
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

module ExtFlashM {
  provides {
    interface StdControl;
    interface Init;
    interface ExtFlash;
  }
  uses {
    interface HPLUSARTControl as USARTControl;
  }
}

implementation {

  command error_t Init.init() {
    TOSH_MAKE_FLASH_HOLD_OUTPUT();
    TOSH_MAKE_FLASH_CS_OUTPUT();
    TOSH_SET_FLASH_HOLD_PIN();
    call USARTControl.setModeSPI();
    return SUCCESS;
  }

  command error_t StdControl.start() { 
    return SUCCESS; 
  }

  command error_t StdControl.stop() { 

    TOSH_CLR_FLASH_CS_PIN();
    
    call USARTControl.tx(0xb9);
    while(call USARTControl.isTxEmpty() != SUCCESS);

    TOSH_SET_FLASH_CS_PIN();

    call USARTControl.disableSPI();

    return SUCCESS; 

  }

  void powerOnFlash() {

    uint8_t i;

    TOSH_CLR_FLASH_CS_PIN();

    // command byte + 3 dummy bytes + signature
    for ( i = 0; i < 5; i++ ) {
      call USARTControl.tx(0xab);
      while(call USARTControl.isTxIntrPending() != SUCCESS);
    }
    
    TOSH_SET_FLASH_CS_PIN();

  }

  command void ExtFlash.startRead(uint32_t addr) {

    uint8_t i;
    
    powerOnFlash();
    
    TOSH_CLR_FLASH_CS_PIN();
    
    // add command byte to address
    addr |= (uint32_t)0x3 << 24;

    // address
    for ( i = 4; i > 0; i-- ) {
      call USARTControl.tx((addr >> (i-1)*8) & 0xff);
      while(call USARTControl.isTxIntrPending() != SUCCESS);
    }    

  }

  command uint8_t ExtFlash.readByte() {
    call USARTControl.rx();
    call USARTControl.tx(0);
    while(call USARTControl.isRxIntrPending() != SUCCESS);
    return call USARTControl.rx();
  }

  command void ExtFlash.stopRead() {
    TOSH_SET_FLASH_CS_PIN();
  }

}
