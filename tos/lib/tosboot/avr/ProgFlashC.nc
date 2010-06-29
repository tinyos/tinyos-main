// $Id: ProgFlashC.nc,v 1.2 2010-06-29 22:07:50 scipio Exp $

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

module ProgFlashC {
  provides {
    interface ProgFlash;
  }
}

implementation {

#include <avr/boot.h>

  command error_t ProgFlash.write(in_flash_addr_t addr, uint8_t* buf, in_flash_addr_t len) {

    uint16_t* wordBuf = (uint16_t*)buf;
    uint32_t i;

    if ( addr + len > TOSBOOT_START )
      return FAIL;    

    boot_page_erase_safe( addr );
    while( boot_rww_busy() )
      boot_rww_enable_safe();
    
    for ( i = 0; i < len; i += 2 )
      boot_page_fill_safe( addr + i, *wordBuf++ );

    boot_page_write_safe( addr );
    
    while ( boot_rww_busy() )
      boot_rww_enable_safe();
    
    return SUCCESS;
    
  }

}
