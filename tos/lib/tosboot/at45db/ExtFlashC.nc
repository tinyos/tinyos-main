// $Id: ExtFlashC.nc,v 1.1 2007-07-11 00:42:56 razvanm Exp $

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

    cmdBuf[0] = 0x68;
    cmdBuf[1] = (addr >> 15) & 0xff;
    cmdBuf[2] = (addr >> 7) & 0xfe;
    cmdBuf[3] = addr & 0xff;
    
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
    if (!(addr & 0xff)) {
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
