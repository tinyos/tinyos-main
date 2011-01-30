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
#include "FatFs.h"

module MoteP
{
  uses {
    interface Boot;
    interface FatFs;
    interface Leds;
  }
}

implementation
{
  FATFS fs;
  DIR dp;
  FIL fp;

  #define BUF_SIZE 1024
  uint8_t buf[BUF_SIZE];
  uint bytes_written;

  event void Boot.booted() {
    int i;
    for(i=0; i<BUF_SIZE; i++)
      buf[i] = i;

    call FatFs.mount(&fs);
    call FatFs.mkdir("/data");
    call FatFs.fopen(&fp, "/data/sample.dat", (FA_OPEN_ALWAYS | FA_WRITE | FA_READ));
    call FatFs.fwrite(&fp, (uint8_t *)buf, BUF_SIZE, &bytes_written);
    call FatFs.fsync(&fp);
    call FatFs.fclose(&fp);
    call Leds.led0On();
  }

  async event void FatFs.mediaUnavailable() {
  }
  async event void FatFs.mediaAvailable() {
  }
}
