// $Id: ExtFlashP.nc,v 1.2 2010-06-29 22:07:50 scipio Exp $

/*
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
