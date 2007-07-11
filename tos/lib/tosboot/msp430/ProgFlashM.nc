// $Id: ProgFlashM.nc,v 1.1 2007-07-11 00:42:57 razvanm Exp $

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

module ProgFlashM {
  provides {
    interface ProgFlash;
  }
}

implementation {

  enum {
    RESET_ADDR = 0xfffe,
  };

  command error_t ProgFlash.write(in_flash_addr_t addr, uint8_t* buf, uint16_t len) {

    volatile uint16_t *flashAddr = (uint16_t*)(uint16_t)addr;
    uint16_t *wordBuf = (uint16_t*)buf;
    uint16_t i = 0;

    // len is 16 bits so it can't be larger than 0xffff
    // make sure we can't wrap around
    if (addr < (0xffff - (len >> 1))) {
      FCTL2 = FWKEY + FSSEL1 + FN2;
      FCTL3 = FWKEY;
      FCTL1 = FWKEY + ERASE;
      *flashAddr = 0;
      FCTL1 = FWKEY + WRT;
      for (i = 0; i < (len >> 1); i++, flashAddr++) {
	if ((uint16_t)flashAddr != RESET_ADDR)
	  *flashAddr = wordBuf[i];
	else
	  *flashAddr = TOSBOOT_START;
      }
      FCTL1 = FWKEY;
      FCTL3 = FWKEY + LOCK;
      return SUCCESS;
    }
    return FAIL;
  }

}
