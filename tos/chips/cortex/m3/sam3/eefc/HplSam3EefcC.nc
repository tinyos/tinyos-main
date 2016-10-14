/*
 * Copyright (c) 2010 CSIRO Australia
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
 * @author Kevin Klues <Kevin.Klues@csiro.au>
 */

#include "sam3eefchardware.h"

generic module HplSam3EefcC(uint32_t eefc_base, uint32_t base_addr, uint32_t page_size, uint32_t total_size) {
  provides interface Init;
  provides interface InternalFlash;
  provides interface HplSam3Eefc;
}

implementation {
  volatile eefc_t *EEFC;
  // Temporary holder as we build the flash cmd register
  eefc_fcr_t fcr;
  // Shouldn't need this temp_buf (i.e. we should be able to write 
  // directly to the base_addr)
  // Doesn't seem to work without it though...
  uint8_t temp_buf[page_size]; 
  
  __attribute__((noinline)) uint32_t sendCommand(uint8_t cmd, uint32_t arg) {
    while(!EEFC->fsr.bits.frdy);
    fcr.bits.fkey = EFFC_FCR_KEY; // Set the key required to send commands
    fcr.bits.farg = arg;
    fcr.bits.fcmd = cmd;
    EEFC->fcr = fcr;
    while(!EEFC->fsr.bits.frdy);
    return EEFC->frr.flat;
  }

  bool getGpnvmBit(uint8_t bit) {
    return sendCommand(EFFC_FCMD_GET_GPNVM, 0) & (1 << bit);
  }

  void eraseIFlash() {
    sendCommand(EFFC_FCMD_ERASE_ALL, 0);
  }

  void eraseWriteIFlashPage(void* buf, uint32_t page) {
    // Write the buffer into the internal flash's latch buffer
    // by writing it to the base address for this flash region
    memcpy((void*)base_addr, buf, page_size);
    sendCommand(EFFC_FCMD_ERASE_PAGE_WRITE_PAGE, page);
  }

  __attribute__((noinline)) error_t doIFlashWrite(void* saddr, void* buf, uint16_t size) {
    int i;
    uint8_t *aligned_saddr = ALIGN_N(saddr, page_size);
    uint8_t *aligned_eaddr = ALIGN_N(saddr+size-1, page_size);
    uint16_t soffset = (uint32_t)saddr - (uint32_t)aligned_saddr;
    uint16_t next_page = ((uint32_t)aligned_saddr - base_addr)/page_size;
    uint16_t npages = ((uint32_t)(aligned_eaddr-aligned_saddr))/page_size + 1;

    // If nothing to write, just return SUCCESS
    if(size == 0)
      return SUCCESS;

    if(((uint32_t)saddr + size) > (base_addr + total_size))
      return ESIZE;

    // Make sure there are no outstanding requests
    while(!EEFC->fsr.bits.frdy);

    // Prepare the temporary buffer with the contents of the first page
    // Preserve original contents at the front
    memcpy(temp_buf, aligned_saddr, soffset); 
    // If the whole buffer fits within the first page
    if(aligned_saddr == aligned_eaddr) {
      //Write new contents to the middle
      memcpy(temp_buf+soffset, buf, size); 
      // Preserve contents to the end
      memcpy(temp_buf+soffset+size, aligned_saddr+soffset+size, page_size-soffset-size); 
    }
    else 
      // Write new contents to the end
      memcpy(temp_buf+soffset, buf, page_size-soffset); 

    // Write the first page
    eraseWriteIFlashPage(temp_buf, next_page);

    // If there was only one page, we're done
    if(aligned_saddr == aligned_eaddr)
      return SUCCESS;

    // Otherwise update variables and move onto the next page
    buf+=page_size-soffset;
    size-=page_size-soffset;
    next_page++;

    // Write all remaining pages except for the last one which may
    // have some alignment issues
    for(i=0; i<npages-2; i++) {
      eraseWriteIFlashPage(buf, next_page);
      buf+=page_size;
      size-=page_size;
      next_page++;
    }

    // Write the last page like this if the remainder of the buffer
    // doesn't fill the whole page
    if(size < page_size) {
      memcpy(temp_buf, buf, size);
      memcpy(temp_buf+size, aligned_eaddr+size, page_size-size);
      eraseWriteIFlashPage(temp_buf, next_page);
    }
    // Otherwise just write the whole last page from the buffer
    else 
      eraseWriteIFlashPage(buf, next_page);

    return SUCCESS;
  }

  error_t doIFlashErase() {
  }

  command error_t Init.init() {
    EEFC = (volatile eefc_t*) eefc_base;
    EEFC->fmr.bits.frdy = 0;   // Don't generate an frdy interrupt
    EEFC->fmr.bits.fws = 2;    // use 3 wait states
    EEFC->fmr.bits.fam = 0;    // enhance for performance
    return SUCCESS;
  }

  command error_t InternalFlash.write(void* addr, void* buf, uint16_t size) {
    return doIFlashWrite(addr, buf, size);
  }

  command error_t InternalFlash.read(void* addr, void* buf, uint16_t size) {
    memcpy(buf, addr, size);
    return SUCCESS;
  }

  command error_t HplSam3Eefc.write(void* addr, void* buf, uint16_t size) {
    return doIFlashWrite(addr, buf, size);
  }

  command error_t HplSam3Eefc.read(void* addr, void* buf, uint16_t size) {
    memcpy(buf, addr, size);
    return SUCCESS;
  }

  command error_t HplSam3Eefc.erase() {
    eraseIFlash();
    return SUCCESS;
  }
}

