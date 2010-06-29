// $Id: ExtFlashC.nc,v 1.4 2010-06-29 22:07:50 scipio Exp $

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

module ExtFlashC {
  provides {
    interface Init;
    interface StdControl;
    interface ExtFlash;
  }
}

implementation {

  uint32_t addr;

  command error_t Init.init() {
    TOSH_MAKE_FLASH_CS_OUTPUT();
    TOSH_SET_FLASH_CS_PIN();
    TOSH_MAKE_FLASH_CLK_OUTPUT();
    TOSH_CLR_FLASH_CLK_PIN();
    TOSH_MAKE_FLASH_OUT_OUTPUT();      
    TOSH_SET_FLASH_OUT_PIN();
    TOSH_MAKE_FLASH_IN_INPUT();
    TOSH_CLR_FLASH_IN_PIN();
    return SUCCESS; 
  }

  command error_t StdControl.start() { return SUCCESS; }
  command error_t StdControl.stop() { return SUCCESS; }

  uint8_t SPIByte(uint8_t out) {

    uint8_t in = 0;
    uint8_t i;

    for ( i = 0; i < 8; i++, out <<= 1 ) {

      // write bit
      if (out & 0x80)
	TOSH_SET_FLASH_OUT_PIN();
      else
	TOSH_CLR_FLASH_OUT_PIN();

      // clock
      TOSH_SET_FLASH_CLK_PIN();

      // read bit
      in <<= 1;
      if (TOSH_READ_FLASH_IN_PIN())
	in |= 1;

      // clock
      TOSH_CLR_FLASH_CLK_PIN();

    }

    return in;

  }

  command void ExtFlash.startRead(uint32_t newAddr) {

    uint8_t  cmdBuf[4];
    uint8_t  i;

    addr = newAddr;

#if defined(PLATFORM_MULLE)
    cmdBuf[0] = 0x68;
    cmdBuf[1] = (addr >> 15);
    cmdBuf[2] = ((addr >> 7) & 0xFC) + ((addr >> 8) & 0x1);
    cmdBuf[3] = addr & 0xff;
#else
    cmdBuf[0] = 0x68;
    cmdBuf[1] = (addr >> 15) & 0xff;
    cmdBuf[2] = (addr >> 7) & 0xfe;
    cmdBuf[3] = addr & 0xff;
#endif
    
    TOSH_CLR_FLASH_CLK_PIN();
    TOSH_CLR_FLASH_CS_PIN();
    
    for(i = 0; i < 4; i++)
      SPIByte(cmdBuf[i]);
    for(i = 0; i < 4; i++)
      SPIByte(0x0);
    
    TOSH_SET_FLASH_CLK_PIN();
    TOSH_CLR_FLASH_CLK_PIN();

  }

  command uint8_t ExtFlash.readByte() {
#if defined(PLATFORM_MULLE)
    if (!(addr & 0x1ff)) {
#else
    if (!(addr & 0xff)) {
#endif
      call ExtFlash.stopRead();
      call ExtFlash.startRead(addr);
    }
    addr++;
    return SPIByte(0);
  }

  command void ExtFlash.stopRead() {
    TOSH_SET_FLASH_CS_PIN();
  }

}
