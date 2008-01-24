// $Id: ProgFlashM.nc,v 1.1 2008-01-24 20:46:55 sallai Exp $

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
#include <avr/boot.h>

module ProgFlashM {
  provides {
    interface ProgFlash;
  }
}

implementation {


  command error_t ProgFlash.write(in_flash_addr_t addr, uint8_t* buf, in_flash_addr_t len) {

    uint16_t* wordBuf = (uint16_t*)buf;
    uint32_t i;

    if ( addr + len > TOSBOOT_START )
      return FAIL;

    boot_page_erase( addr );
    while( boot_rww_busy() )
      boot_rww_enable();

    for ( i = 0; i < len; i += 2 )
      boot_page_fill( addr + i, *wordBuf++ );

    boot_page_write( addr );

    while ( boot_rww_busy() )
      boot_rww_enable();

    return SUCCESS;

  }

}
