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
 * @author Kaisen Lin
 * @author Phil Buonadonna
 *
 */
#include <P30.h>
#include <StorageVolumes.h>

module P30BlockP {
  provides interface BlockRead as Read[ storage_volume_t block ];
  provides interface BlockWrite as Write[ storage_volume_t block ];

  uses interface Leds;
  uses interface Flash;
}

implementation {
  typedef enum {
    S_IDLE,
    S_READ,
    S_WRITE,
    S_ERASE,
    S_CRC,
    S_SYNC,

  } p30_block_state_t;
  norace p30_block_state_t m_state = S_IDLE;
  storage_volume_t clientId = 0xff;
  storage_addr_t clientAddr;
  void* clientBuf;
  storage_len_t clientLen;
  error_t clientResult;

  /*
   * This is a helper function to translate from the client address
   * space to the underlying HalP30 address space. This is necessary
   * because HAL provides a flat 32MB interface.
   */
  uint32_t xlateAddr(storage_volume_t b, storage_addr_t addr) {
    return P30_VMAP[b].base * FLASH_PARTITION_SIZE + addr;
  }

  task void signalDoneTask() {
    switch(m_state) {
    case S_WRITE:
      m_state = S_IDLE;
      signal Write.writeDone[clientId](clientAddr, clientBuf, clientLen, clientResult);
      break;
   case S_SYNC:
      m_state = S_IDLE;
      signal Write.syncDone[clientId](SUCCESS);
      break;
    case S_ERASE:
      m_state = S_IDLE;
      signal Write.eraseDone[clientId](clientResult);
      break;
   case S_READ:
      m_state = S_IDLE;
      signal Read.readDone[clientId](clientAddr, clientBuf, clientLen, clientResult);
      break;
    default:
      break;
    }
  }

  /*
   * Translate the address to a physical flash address and do the
   * write.
   */
  command error_t Write.write[ storage_volume_t b ]( storage_addr_t addr, 
						    void* buf, 
						    storage_len_t len ) {
    uint32_t physAddr;

    if(m_state != S_IDLE)
      return EBUSY;

    // error check
    if(addr + len > P30_VMAP[b].size * FLASH_PARTITION_SIZE)
      return EINVAL;

    clientId = b;
    clientAddr = addr;
    clientBuf = buf;
    clientLen = len;

    m_state = S_WRITE;

    physAddr = xlateAddr(b, addr);

    clientResult = call Flash.write(physAddr, (uint8_t*) buf, len);

    post signalDoneTask();
    return SUCCESS;
  }
  
  /*
   * Sync doesn't really do anything because Intel PXA is
   * write-through.
   */
  command error_t Write.sync[ storage_volume_t b ]() {

    m_state = S_SYNC;
    clientId = b;

    post signalDoneTask();
    return SUCCESS;
  }
  
  /*
   * Because each 2MB partition is divided into 128k erasable pieces,
   * we must go through and erase all of them.
   */
  command error_t Write.erase[ storage_volume_t b ]() {
   uint32_t physAddr;
   uint32_t blocks;

    if(m_state != S_IDLE)
      return EBUSY;

    clientId = b;

    m_state = S_ERASE;
    physAddr = xlateAddr(b,0);
    for(blocks = ((P30_VMAP[b].size)*FLASH_PARTITION_SIZE)/P30_BLOCK_SIZE;
	blocks > 0;
	blocks--) {
      clientResult = call Flash.erase(physAddr);
      if(clientResult != SUCCESS)
	break;
      physAddr += P30_BLOCK_SIZE;
    }

    post signalDoneTask();
    return SUCCESS;
  }

  /*
   * Translate the address to a physical flash address and do the
   * read.
   */
  command error_t Read.read[ storage_volume_t b ]( storage_addr_t addr,
						  void* buf,
						  storage_len_t len ) {
   uint32_t physAddr;

    if(m_state != S_IDLE)
      return FAIL;

    clientId = b;
    clientAddr = addr;
    clientBuf = buf;
    clientLen = len;

    m_state = S_READ;
    physAddr = xlateAddr(b,addr);

    call Flash.read((uint32_t) physAddr, (uint8_t*) buf, (uint32_t) len);

    post signalDoneTask();
    return SUCCESS;
  }
  
  
  command error_t Read.computeCrc[ storage_volume_t b ]( storage_addr_t addr,
							storage_len_t len,
							uint16_t crc) {
    m_state = S_CRC;
    clientId = b;

    post signalDoneTask();
    return SUCCESS;
  }

  command storage_len_t Read.getSize[ storage_volume_t b]() {
    return P30_VMAP[b].size * FLASH_PARTITION_SIZE;
  }

  default event void Write.writeDone[ storage_volume_t b ]( storage_addr_t addr, void* buf, storage_len_t len, error_t error ) {}
  default event void Write.eraseDone[ storage_volume_t b ]( error_t error ) {}
  default event void Write.syncDone[ storage_volume_t b ]( error_t error ) {}

  default event void Read.readDone[ storage_volume_t b ]( storage_addr_t addr, void* buf, storage_len_t len, error_t error ) {}
  default event void Read.computeCrcDone[ storage_volume_t b ]( storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error ) {}

}
