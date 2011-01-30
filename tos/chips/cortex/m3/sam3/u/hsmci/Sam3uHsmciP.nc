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
 */

/**
 * High Speed Multimedia Card Interface Implementations.
 * @author Kevin Klues <kevin.klues@csiro.au>
 */

#include "sam3uhsmcihardware.h"

module Sam3uHsmciP
{
  provides {
    interface Sam3uHsmciInit @exactlyonce();
    interface Sam3uHsmci[uint8_t];
  }
  uses {
    interface ArbiterInfo;
    interface HplSam3uHsmci;
    interface Leds;
  }
}

implementation
{
  #define BYTES_PER_BLOCK 512
  #define WORDS_PER_BLOCK ((BYTES_PER_BLOCK)/4)
  #define BLOCK_MULTIPLIER (card_type ? 1 : 512)
  #define CURRENT_OWNER (call ArbiterInfo.userId())

  enum {
    SD_STANDARD_CAP,
    SD_HIGHEXT_CAP,
  };

  enum {
    S_INACTIVE,
    S_IDLE,
    S_BUSY,
  };

  // Protected by state variables 
  norace uint8_t state = S_INACTIVE;
  norace uint32_t rca_addr;
  norace int card_type = SD_STANDARD_CAP;
  norace uint64_t card_size = 0;
  norace uint32_t *trans_buf;

  uint32_t computeV1CardSize(hsmci_sd_r2_t* rsp) {
    int i,j;
    uint64_t s = rsp->v1_csd.c_size + 1;
    for(i=2, j=rsp->v1_csd.c_size_mult + 2; j>1; j--)
      i <<= 1;
    s*=i;
    for(i=2, j=rsp->v1_csd.read_bl_len; j>1; j--)
      i <<= 1;
    s*=i;
    return s;
  }

  command error_t Sam3uHsmciInit.init() {
    if(state != S_INACTIVE)
      return EALREADY;
    return call HplSam3uHsmci.init(&trans_buf);
  }

  async event void HplSam3uHsmci.initDone(hsmci_sd_r6_t* rsp, error_t error) {
    if(error == SUCCESS) {
      rca_addr = rsp->rca << 16;
      call HplSam3uHsmci.sendCommand(CMD9, rca_addr);
    }
    else
      signal Sam3uHsmciInit.initDone(error);
  }

  async command uint64_t Sam3uHsmci.readCardSize[uint8_t id](){
    if(state != S_INACTIVE)
      return card_size;
    return -1;
  }

  async event void* HplSam3uHsmci.sendCommandDone(uint8_t cmd, void* rsp, error_t error) {
    if(state == S_INACTIVE) {
      if(error == SUCCESS) {
        switch(cmd) {
          case CMD9:
          {
            hsmci_sd_r2_t *r2 = (hsmci_sd_r2_t*)rsp;
            card_type = r2->csd.csd_structure;
            if(card_type == SD_HIGHEXT_CAP)
              card_size = (r2->csd.c_size + 1)*BYTES_PER_BLOCK*1024;
            else
              card_size = computeV1CardSize(r2);
            call HplSam3uHsmci.sendCommand(CMD7, rca_addr);
            break;
          }
          case CMD7:
            call HplSam3uHsmci.sendCommand(ACMD6, SD_STAT_DATA_BUS_WIDTH_4BIT);
            break;
          case ACMD6:
            call HplSam3uHsmci.sendCommand(CMD16, BYTES_PER_BLOCK);
            break;
          case CMD16:
            state = S_IDLE;
            signal Sam3uHsmciInit.initDone(SUCCESS);
            break;
          default:
            //Should never get here!!
        }
      }
      else signal Sam3uHsmciInit.initDone(error);
    }
    else if(error != SUCCESS) {
      state = S_IDLE;
      switch(cmd) {
        case CMD17:
          signal Sam3uHsmci.readBlockDone[CURRENT_OWNER](trans_buf, error);
          break;
        case CMD24:
          signal Sam3uHsmci.writeBlockDone[CURRENT_OWNER](trans_buf, error);
          break;
        default:
          //Should never get here!!
      }
    }
    return rsp;
  }

  async command error_t Sam3uHsmci.readBlock[uint8_t id](uint32_t sector, uint32_t *buffer) {
    if(CURRENT_OWNER != id)
      return ERESERVE;

    if(state == S_IDLE) {
      error_t e;
      trans_buf = buffer;
      state = S_BUSY;
      e = call HplSam3uHsmci.sendCommand(CMD17, sector*BLOCK_MULTIPLIER); 
      if(e != SUCCESS)
        state = S_IDLE;
      return e;
    }
    return EBUSY;
  }

  async command error_t Sam3uHsmci.writeBlock[uint8_t id](uint32_t sector, uint32_t *buffer) {
    if(CURRENT_OWNER != id)
      return ERESERVE;
    
    if(state == S_IDLE) {
      error_t e;
      trans_buf = buffer;
      state = S_BUSY;
      e = call HplSam3uHsmci.sendCommand(CMD24, sector*BLOCK_MULTIPLIER); 
      if(e != SUCCESS)
        state = S_IDLE;
      return e;
    }
    return EBUSY;
  }

  async event void HplSam3uHsmci.txDone(error_t error) {
    state = S_IDLE;
    signal Sam3uHsmci.writeBlockDone[CURRENT_OWNER](trans_buf, error);
  }

  async event void HplSam3uHsmci.rxDone(error_t error) {
    state = S_IDLE;
    signal Sam3uHsmci.readBlockDone[CURRENT_OWNER](trans_buf, error);
  }

  async default event void Sam3uHsmci.writeBlockDone[uint8_t id](uint32_t *buf, error_t error) {}
  async default event void Sam3uHsmci.readBlockDone[uint8_t id](uint32_t *buf, error_t error) {}
}

