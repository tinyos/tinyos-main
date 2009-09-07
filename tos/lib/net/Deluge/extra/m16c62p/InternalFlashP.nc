/*
 * Copyright (c) 2009 Communication Group and Eislab at
 * Lulea University of Technology
 *
 * Contact: Laurynas Riliskis, LTU
 * Mail: laurynas.riliskis@ltu.se
 * All rights reserved.
 *
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of Communication Group at Lulea University of Technology
 *   nor the names of its contributors may be used to endorse or promote
 *    products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "M16c62pFlash.h"

/**
 * Implementation of the InternalFlash interface for the
 * M16c/62p mcu. Currently flash block 5 is used for the
 * internal flash and is hard coded.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */
// TODO(henrik) Fix the hard coded value of the flash block.
module InternalFlashP {
  provides interface InternalFlash;
  
  uses interface HplM16c62pFlash as Flash;
}

implementation {

#define INTERNAL_ADDRESS 0xF0000L 
#define INTERNAL_BLOCK BLOCK_5

  command error_t InternalFlash.write(void* addr, void* buf, uint16_t size) {
    // TODO(henrik) Make this more sain by making use of the whole block before
    // erasing the whole block.
    if (call Flash.FlashErase(INTERNAL_BLOCK) != 0)
    {
      return FAIL;
    }
    if (call Flash.FlashWrite(INTERNAL_ADDRESS, (unsigned int*)buf, size) != 0)
    {
      return FAIL;
    }
    return SUCCESS;
  }

  command error_t InternalFlash.read(void* addr, void* buf, uint16_t size) {
    unsigned long address = INTERNAL_ADDRESS;
    uint16_t i;
    uint8_t* buffer = (uint8_t*)buf;

    for (i = 0; i < size; ++i, ++address)
    {
      buffer[i] = call Flash.FlashRead(address);
    }
    return SUCCESS;
  }
}
