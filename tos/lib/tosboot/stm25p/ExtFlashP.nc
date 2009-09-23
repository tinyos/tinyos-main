// $Id: ExtFlashP.nc,v 1.1 2009-09-23 18:29:24 razvanm Exp $

/*
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

module ExtFlashP {
  provides {
    interface StdControl;
    interface Init;
    interface ExtFlash;
  }
  uses {
    interface HplUsartControl as UsartControl;
  }
}

implementation {

  command error_t Init.init() {
    TOSH_MAKE_FLASH_HOLD_OUTPUT();
    TOSH_MAKE_FLASH_CS_OUTPUT();
    TOSH_SET_FLASH_HOLD_PIN();
    call UsartControl.setModeSPI();
    return SUCCESS;
  }

  command error_t StdControl.start() { 
    return SUCCESS; 
  }

  command error_t StdControl.stop() { 

    TOSH_CLR_FLASH_CS_PIN();
    
    call UsartControl.tx(0xb9);
    while(call UsartControl.isTxEmpty() != SUCCESS);

    TOSH_SET_FLASH_CS_PIN();

    call UsartControl.disableSPI();

    return SUCCESS; 

  }

  void powerOnFlash() {

    uint8_t i;

    TOSH_CLR_FLASH_CS_PIN();

    // command byte + 3 dummy bytes + signature
    for ( i = 0; i < 5; i++ ) {
      call UsartControl.tx(0xab);
      while(call UsartControl.isTxIntrPending() != SUCCESS);
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
      call UsartControl.tx((addr >> (i-1)*8) & 0xff);
      while(call UsartControl.isTxIntrPending() != SUCCESS);
    }    

  }

  command uint8_t ExtFlash.readByte() {
    call UsartControl.rx();
    call UsartControl.tx(0);
    while(call UsartControl.isRxIntrPending() != SUCCESS);
    return call UsartControl.rx();
  }

  command void ExtFlash.stopRead() {
    TOSH_SET_FLASH_CS_PIN();
  }

}
