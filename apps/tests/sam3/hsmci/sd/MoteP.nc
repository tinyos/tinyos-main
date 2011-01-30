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
#include "printf.h"

module MoteP
{
  uses {
    interface Boot;
    interface StdControl;
    interface SD;
    interface Leds;
  }
}

implementation
{
  #define NUM_BLOCKS 1000
  #define BYTES_PER_BLOCK 512

  int next_block = 0;
  uint8_t tx_buf[BYTES_PER_BLOCK];
  uint8_t rx_buf[BYTES_PER_BLOCK];

  task void writeTask();
  task void readTask();

  event void Boot.booted() {
    int i;
    uint32_t size;
    for(i=0; i<BYTES_PER_BLOCK; i++)
      tx_buf[i] = i;
    call StdControl.start();
    size = call SD.readCardSize();
    printf("card_size: %u\n", size);
    printfflush();
  }

  task void writeTask() {
    int i;
    error_t error = call SD.writeBlock(next_block, tx_buf);

    if(error != SUCCESS)
      call Leds.led0On();
    for(i=0; i<BYTES_PER_BLOCK; i++)
      rx_buf[i] = 0;
    post readTask();
  }

  task void readTask() {
    int i, busted = FALSE;
    call SD.readBlock(next_block, rx_buf);

    for(i=0; i<BYTES_PER_BLOCK; i++) {
      if(rx_buf[i] != (uint8_t)i) {
        busted = TRUE;
      }
    }

    next_block++;
    if(busted)
      call Leds.led0On();
    else if(next_block == NUM_BLOCKS)
      call Leds.led1On();
    else {
      post writeTask();
    }
  }

  async event void SD.available() {
    call Leds.led2On();
    post writeTask();
  }
  
  async event void SD.unavailable() {
  }
}

