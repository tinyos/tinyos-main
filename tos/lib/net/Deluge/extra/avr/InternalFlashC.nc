// $Id: InternalFlashC.nc,v 1.3 2010-06-29 22:07:47 scipio Exp $

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
 * - Neither the name of the University of California nor the names of
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

#include "InternalFlash.h"

module InternalFlashC {
  provides interface InternalFlash;
}

implementation {

  command error_t InternalFlash.write(void* addr, void* buf, uint16_t size) {

    uint8_t *addrPtr = (uint8_t*)addr;
    uint8_t *bufPtr = (uint8_t*)buf;

    for ( ; size; size-- )
      eeprom_write_byte(addrPtr++, *bufPtr++);

    while(!eeprom_is_ready());

    return SUCCESS;

  }

  command error_t InternalFlash.read(void* addr, void* buf, uint16_t size) {

    uint8_t *addrPtr = (uint8_t*)addr;
    uint8_t *bufPtr = (uint8_t*)buf;

    for ( ; size; size-- )
      *bufPtr++ = eeprom_read_byte(addrPtr++);

    return SUCCESS;

  }

}
