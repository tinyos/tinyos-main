/* $Id: HplP30P.nc,v 1.4 2006-12-12 18:23:12 vlahan Exp $ */
/*
 * Copyright (c) 2005 Arch Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arch Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/**
 * @author Phil Buonadonna
 *
 */
#include <P30.h>
module HplP30P {
  provides interface HplP30;
}

implementation {

  volatile uint16_t * devBaseAddress = (uint16_t *)(0x0);

  async command error_t HplP30.progWord(uint32_t addr, uint16_t word) {
    volatile uint16_t *blkAddress = (uint16_t *)addr;
    uint32_t result;

    *devBaseAddress = P30_READ_CLRSTATUS;
    *blkAddress = P30_WRITE_WORDPRGSETUP;
    *blkAddress = word;

    do {
      result = *blkAddress;
    } while ((result & P30_SR_DWS) == 0);

    *blkAddress = P30_READ_READARRAY;

    if (result & (P30_SR_PS | P30_SR_VPPS | P30_SR_BLS)) {
      return FAIL;
    }

    return SUCCESS;

  }

  async command error_t HplP30.progBuffer(uint32_t addr, uint16_t *data, uint8_t len) {
    volatile uint16_t *blkAddress = (uint16_t *)addr;
    uint32_t i,result;
    error_t error = SUCCESS;

    if (len <= 0) {
      error = EINVAL;
      goto done;
    }

    *devBaseAddress = P30_READ_CLRSTATUS;
    *blkAddress = P30_WRITE_BUFPRG;

    result = *blkAddress;
    if ((result & P30_SR_DWS) == 0) {
      error = FAIL;
      goto cleanup;
    }

    *blkAddress = len-1;
    
    for (i=0;i<len;i++) {
      blkAddress[i] = data[i];
    }
    
    *blkAddress = P30_WRITE_BUFPRGCONFIRM;

    do {
      result = *blkAddress;
    } while ((result & P30_SR_DWS) == 0);

    if (result & (P30_SR_PS | P30_SR_VPPS)) {
      error = FAIL;
      goto done;
    }
  cleanup:
    *blkAddress = P30_READ_READARRAY;
  done:
    return error;

  }

  async command error_t HplP30.blkErase(uint32_t blkaddr) {
    volatile uint16_t *blkAddress = (uint16_t *)blkaddr;
    uint32_t result;

    *devBaseAddress = P30_READ_CLRSTATUS;
    *blkAddress = P30_ERASE_BLKSETUP;
    *blkAddress = P30_ERASE_BLKCONFIRM;

    do {
      result = *blkAddress;
    } while ((result & P30_SR_DWS) == 0);

    *blkAddress = P30_READ_READARRAY;

    if (result & (P30_SR_ES | P30_SR_VPPS | P30_SR_BLS)) {
      return FAIL;
    }

    return SUCCESS;

  }

  async command error_t HplP30.blkLock(uint32_t blkaddr) {
    volatile uint16_t *blkAddress = (uint16_t*) blkaddr;

    asm volatile (
		  ".align 5\n\t"
		  "strh %0,[%3]\n\t"
		  "strh %1,[%3]\n\t"
		  "strh %2,[%3]\n\t"
		  : 
		  :"r" (P30_LOCK_SETUP), 
		  "r" (P30_LOCK_LOCK), 
		  "r" (P30_READ_READARRAY),
		  "r" (blkaddr)
		  );

    return SUCCESS;
  }

  async command error_t HplP30.blkUnlock(uint32_t blkaddr) {

    asm volatile (
		  ".align 5\n\t"
		  "strh %0,[%3]\n\t"
		  "strh %1,[%3]\n\t"
		  "strh %2,[%3]\n\t"
		  : 
		  : "r" (P30_LOCK_SETUP), 
		  "r" (P30_LOCK_UNLOCK), 
		  "r" (P30_READ_READARRAY),
		  "r" (blkaddr)
		  );

    return SUCCESS;

  }

  /* THIS FUNCTION IS UNTESTED, USE READBYTEBURST FOR NOW */
  async command error_t HplP30.readWordBurst(uint32_t addr, uint16_t* word) {
    volatile uint16_t *blkAddress = (uint16_t *)addr;
    *word = *blkAddress;
    return SUCCESS;
  }

  async command error_t HplP30.readByteBurst(uint32_t addr, uint8_t* bytex) {
    volatile uint8_t *blkAddress = (uint8_t *)addr;
    *bytex = *blkAddress;
    return SUCCESS;
  }

}
