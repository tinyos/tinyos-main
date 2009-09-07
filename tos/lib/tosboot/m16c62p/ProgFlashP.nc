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

/**
 * Implementation of the ProgFlash interface for M16c/62p.
 * The interface is responsible of reprogramming of the mcus
 * program flash.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

#include "M16c62pFlash.h"

module ProgFlashP
{
  provides interface ProgFlash;
  
  uses interface HplM16c62pFlash as Flash;
}

implementation
{

  command error_t ProgFlash.write(in_flash_addr_t addr, uint8_t* buf, in_flash_addr_t len)
  {
    
    // We dont need to rewrite the hw interrupt vector
    if (addr >= 0xFFE00L)
    {
      return SUCCESS;
    }

    if (addr + len >= TOSBOOT_START)
    {
      return FAIL;
    }

    if (addr == 0xA0000L)
    {
      // Erase Block 10
      if (call Flash.FlashErase(BLOCK_10) != 0 )
      {
        return FAIL;
      }
    }
    else if ( addr == 0xB0000L )
    {
      // Erase Block 9
      if (call Flash.FlashErase(BLOCK_9) != 0 )
      {
        return FAIL;
      }
    }
    else if ( addr == 0xC0000L )
    {
      // Erase Block 8
      if (call Flash.FlashErase(BLOCK_8) != 0 )
      {
        return FAIL;
      }
    }
    else if ( addr == 0xD0000L )
    {
      // Erase Block 7
      if (call Flash.FlashErase(BLOCK_7) != 0 )
      {
        return FAIL;
      }
    }

    if (call Flash.FlashWrite(addr, (unsigned int*) buf, len) != 0)
    {
      return FAIL;
    }
    
    return SUCCESS;
    
  }
}

