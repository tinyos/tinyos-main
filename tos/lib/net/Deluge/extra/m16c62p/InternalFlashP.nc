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
 * M16c/62p mcu to be used as the TOSBoot arguments storage.
 * 
 * The implementation uses 2 flash blocks to store the arguments into. First one
 * block is filled up or written to until a error occurs. After that the second block
 * will be written to. Everytime the start address of one block is written to the
 * otherone will be erased. If a erase is not executed due to powerdown or some other
 * error a erase command will be executed on that block the next time.
 * 
 * A argument writing is surrounded by two 0x1 bytes:
 * 0x1 [arguments data] 0x1. The first byte indicating a new TOSBoot argument entry
 * and the last one indicating a successfull write of a TOSBoot argument to the flash.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */
generic module InternalFlashP(M16C62P_BLOCK block1, M16C62P_BLOCK block2)
{
  provides interface InternalFlash;

  uses interface HplM16c62pFlash as Flash;
}

implementation
{

#define INTERNAL_ADDRESS_1 m16c62p_block_start_addresses[block1]
#define INTERNAL_ADDRESS_1_END m16c62p_block_end_addresses[block1]

#define INTERNAL_ADDRESS_2 m16c62p_block_start_addresses[block2]
#define INTERNAL_ADDRESS_2_END m16c62p_block_end_addresses[block2]

#define INTERNAL_BLOCK_1 block1
#define INTERNAL_BLOCK_2 block2

  void sanityCheck(uint16_t size)
  {
    if (call Flash.read(INTERNAL_ADDRESS_1) != 0xff &&
        call Flash.read(INTERNAL_ADDRESS_2) != 0xff)
    {
      // Something happened last time we wrote with a erase command
      // that should have been executet or failed.
      if (call Flash.read(INTERNAL_ADDRESS_1+size+2) != 0x1)
      {
        if (call Flash.read(INTERNAL_ADDRESS_1+size+1) == 0x1)
        {
          call Flash.erase(INTERNAL_BLOCK_2);
        }
        else
        {
          call Flash.erase(INTERNAL_BLOCK_1);
        }
      }
      else
      {
        if (call Flash.read(INTERNAL_ADDRESS_2+size+1) == 0x1)
        {
          call Flash.erase(INTERNAL_BLOCK_1);
        }
        else
        {
          call Flash.erase(INTERNAL_BLOCK_2);
        }
      }
    }
  }

  error_t writableAddressInBlock(unsigned long start, unsigned long end, uint16_t size, unsigned long* address)
  {
    for(; (start < end) && (start+size < end); start += (unsigned long)size)
    {
      if (call Flash.read(start) == 0xFF)
      {
        if (call Flash.read(start-1) != 0x1)
        {
          return FAIL;
        }
        *address = start;
        return SUCCESS;
      }
    }
    return FAIL;
  }

  unsigned long writableAddress(uint16_t size)
  {
    if (call Flash.read(INTERNAL_ADDRESS_1) == 0xFF)
    {
      if (call Flash.read(INTERNAL_ADDRESS_2) == 0xFF)
      {
        return INTERNAL_ADDRESS_1;
      }
      else
      {
        unsigned long address;
        if (writableAddressInBlock(INTERNAL_ADDRESS_2, INTERNAL_ADDRESS_2_END, size+2, &address) == SUCCESS)
        {
          return address;
        }
        return INTERNAL_ADDRESS_1;
      }
    }
    else
    {
      unsigned long address;
      if (writableAddressInBlock(INTERNAL_ADDRESS_1, INTERNAL_ADDRESS_1_END, size+2, &address) == SUCCESS)
      {
        return address;
      }
      return INTERNAL_ADDRESS_2;
    }
  }

  command error_t InternalFlash.write(void* addr, void* buf, uint16_t size)
  {
    uint8_t wbuf[sizeof(BootArgs)];
    unsigned long address;

    sanityCheck(size);

    wbuf[0] = 0x1;
    wbuf[size+1] = 0x1;
    memcpy(wbuf+1, buf, size);

    address = writableAddress(size);
    if (call Flash.write(address, (unsigned int*)wbuf, size+2) != 0)
    {
      return FAIL;
    }
    if (address == INTERNAL_ADDRESS_1)
    {
      return call Flash.erase(INTERNAL_BLOCK_2);
    }
    else if (address == INTERNAL_ADDRESS_2)
    {
      return call Flash.erase(INTERNAL_BLOCK_1);
    }
    return SUCCESS;
  }

  void readFromFlash(unsigned long address, uint8_t* buf, uint16_t size)
  {
    uint16_t i;
    for (i = 0; i < size; ++i, ++address)
    {
      buf[i] = call Flash.read(address);
    }
  }

  void readFromBlock(unsigned long start, unsigned long end, uint8_t *buffer, uint16_t size)
  {
    unsigned long address = start;
    for (; address < end; address += 2 + size)
    {
      if (call Flash.read(address) != 0x1)
      {
        break;
      }
    }

    for (; address > start; address -= size + 2)
    {
      if(call Flash.read(address+size+1) == 0x1)
      {
        break;
      }
    }
    if(call Flash.read(address+size+1) == 0x1)
    {
      address++;
      readFromFlash(address, buffer, size);
    }
    else
    {
      memset(buffer, 0xff, size);
    }
  }

  command error_t InternalFlash.read(void* addr, void* buf, uint16_t size) 
  {
    uint8_t* buffer = (uint8_t*)buf;

    sanityCheck(size);
    if (call Flash.read(INTERNAL_ADDRESS_1) == 0xFF)
    {
      if (call Flash.read(INTERNAL_ADDRESS_2) == 0xFF)
      {
        memset(buf, 0xff, size);
      }
      else
      {
        readFromBlock(INTERNAL_ADDRESS_2, INTERNAL_ADDRESS_2_END, buffer, size);
      }
    }
    else
    {
      readFromBlock(INTERNAL_ADDRESS_1, INTERNAL_ADDRESS_1_END, buffer, size);
    }
    return SUCCESS;
  }
}
