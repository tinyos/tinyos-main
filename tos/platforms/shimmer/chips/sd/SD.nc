/*
 * Copyright (c) 2006, Intel Corporation
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * Redistributions of source code must retain the above copyright notice, 
 * this list of conditions and the following disclaimer. 
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution. 
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software 
 * without specific prior written permission. 
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * Interface for communciating with an SD card via a standard sd card slot.
 *
 * @author Steve Ayer
 * @date May 2006
 */

#include "SD.h"

interface SD {

  command mmcerror_t init ();

  command mmcerror_t setIdle();

  // we don't have pin for this one yet; it uses cd
  //  command mmcerror_t detect();

  // change block length to 2^len bytes; default is 512
  command mmcerror_t setBlockLength (const uint16_t len);

  // see macro in module for writing to a sector instead of an address
  // read a block of size count from address
  command mmcerror_t readBlock(const uint32_t address, const uint16_t count, uint8_t * buffer);
  command mmcerror_t readSector(uint32_t sector, uint8_t * pBuffer);

  // see macro in module for writing to a sector instead of an address
  command mmcerror_t writeBlock (const uint32_t address, const uint16_t count, uint8_t * buffer);
  command mmcerror_t writeSector(uint32_t sector, uint8_t * pBuffer);

  // register read of length len into buffer
  command mmcerror_t readRegister(const uint8_t register, const uint8_t len, uint8_t * buffer);

  // Read the Card Size from the CSD Register
  // unsupported on sdio only cards
  command uint32_t readCardSize();
}
