/*
 * Copyright (c) 2010 CSIRO
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
 */

/**
 * Simple test program for SAM3U's HSMCI HPL interface
 * @author Kevin Klues <kevin.klues@csiro.au>
 */

#include "sam3uhsmcihardware.h"

module MoteP
{
  uses {
    interface Boot;
    interface AsyncStdControl;
    interface HplSam3uHsmci;
    interface Leds;
    interface BusyWait<TMicro, uint16_t>;
  }
}

implementation
{
  #define NUM_BLOCKS 1000
  #define WORDS_PER_BLOCK 128

  enum {
    SD_STANDARD_CAP,
    SD_HIGHEXT_CAP,
  };

  norace int next_block = 0;
  norace int block_multiplier = 512;
  norace int card_type = SD_STANDARD_CAP;
  uint16_t card_size = 0;

  norace uint32_t rca_addr;
  norace uint32_t trans_buf[WORDS_PER_BLOCK];
  uint32_t *trans_buf_ptr;

  event void Boot.booted() {
    int i;
    call AsyncStdControl.start();
    trans_buf_ptr = trans_buf;
    call HplSam3uHsmci.init(&trans_buf_ptr);
    for(i=0; i<WORDS_PER_BLOCK; i++) {
      trans_buf[i] = i;
    }
  }

  async event void HplSam3uHsmci.initDone(hsmci_sd_r6_t* rsp, error_t error) {
    if(error == SUCCESS) {
      rca_addr = rsp->rca << 16;
      call HplSam3uHsmci.sendCommand(CMD9, rca_addr);
    }
  }

  async event void* HplSam3uHsmci.sendCommandDone(uint8_t cmd, void* rsp, error_t error) {
    if(error == SUCCESS) {
      switch(cmd) {
        case CMD9:
        {
          hsmci_sd_r2_t *r2 = (hsmci_sd_r2_t*)rsp;
          card_type = r2->csd.csd_structure;
          block_multiplier = card_type ? 1 : 512;
          //TODO: compute the card size so one can query it
          call HplSam3uHsmci.sendCommand(CMD7, rca_addr);
          break;
        }
        case CMD7:
          call HplSam3uHsmci.sendCommand(ACMD6, 2);
          break;
        case ACMD6:
          call Leds.led2Toggle();
          call HplSam3uHsmci.sendCommand(CMD16, 512);
          break;
        case CMD16:
          call HplSam3uHsmci.sendCommand(CMD24, next_block*block_multiplier);
          break;
        case CMD24:
          break;
        case CMD17:
          break;
        default:
      }
    }
    return rsp;
  }

  async event void HplSam3uHsmci.txDone(error_t error) {
    int i;
    if(error != SUCCESS)
      call Leds.led0On();
    for(i=0; i<WORDS_PER_BLOCK; i++)
      trans_buf[i] = 0;
    call HplSam3uHsmci.sendCommand(CMD17, next_block*block_multiplier);
  }

  async event void HplSam3uHsmci.rxDone(error_t error) {
    int i, busted = FALSE;
    for(i=0; i<WORDS_PER_BLOCK; i++) {
      if(trans_buf[i] != i)
        busted = TRUE;
    }

    next_block++;
    if(busted)
      call Leds.led0On();
    else if(next_block == NUM_BLOCKS)
      call Leds.led1On();
    else {
      call HplSam3uHsmci.sendCommand(CMD24, next_block*block_multiplier);
    }
  }
}

