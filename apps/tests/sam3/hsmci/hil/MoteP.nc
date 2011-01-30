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
    interface Resource;
    interface Sam3uHsmciInit;
    interface Sam3uHsmci;
    interface Leds;
  }
}

implementation
{
  #define NUM_BLOCKS 1000
  #define WORDS_PER_BLOCK 128

  norace int next_block = 0;
  norace uint32_t tx_buf[WORDS_PER_BLOCK];
  norace uint32_t rx_buf[WORDS_PER_BLOCK];

  event void Boot.booted() {
    int i;
    for(i=0; i<WORDS_PER_BLOCK; i++)
      tx_buf[i] = i;
    call Resource.request();
  }
  
  event void Resource.granted() {
    call Sam3uHsmciInit.init();
  }

  async event void Sam3uHsmciInit.initDone(error_t error) {
    if(error == SUCCESS) {
      call Leds.led2On();
      call Sam3uHsmci.writeBlock(next_block, tx_buf);
    }
  }

  async event void Sam3uHsmci.writeBlockDone(uint32_t *buf, error_t error) {
    int i;
    if(error != SUCCESS)
      call Leds.led0On();
    for(i=0; i<WORDS_PER_BLOCK; i++)
      rx_buf[i] = 0;
    call Resource.release();
    call Resource.immediateRequest();
    call Sam3uHsmci.readBlock(next_block, rx_buf);
  }

  async event void Sam3uHsmci.readBlockDone(uint32_t *buf, error_t error) {
    int i, busted = FALSE;
    for(i=0; i<WORDS_PER_BLOCK; i++) {
      if(rx_buf[i] != i)
        busted = TRUE;
    }

    next_block++;
    if(busted)
      call Leds.led0On();
    else if(next_block == NUM_BLOCKS)
      call Leds.led1On();
    else {
      call Resource.release();
      call Resource.immediateRequest();
      call Sam3uHsmci.writeBlock(next_block, tx_buf);
    }
  }
}

