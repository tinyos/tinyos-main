/*
 * Copyright (c) 2011 University of Utah. 
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
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 *
 *
 * @author Thomas Schmid
 */

#include "Timer.h"

module DacC @safe()
{
  uses 
  {
    interface Leds;
    interface Boot;

    interface StdControl as DacControl;
    interface Sam3sDac as Dac;
  }
}
implementation
{
#define SAMPLES 100

  const int16_t sine_data[SAMPLES]=
  {
    0x0,   0x080, 0x100, 0x17f, 0x1fd, 0x278, 0x2f1, 0x367, 0x3da, 0x449,
    0x4b3, 0x519, 0x579, 0x5d4, 0x629, 0x678, 0x6c0, 0x702, 0x73c, 0x76f,
    0x79b, 0x7bf, 0x7db, 0x7ef, 0x7fb, 0x7ff, 0x7fb, 0x7ef, 0x7db, 0x7bf,
    0x79b, 0x76f, 0x73c, 0x702, 0x6c0, 0x678, 0x629, 0x5d4, 0x579, 0x519,
    0x4b3, 0x449, 0x3da, 0x367, 0x2f1, 0x278, 0x1fd, 0x17f, 0x100, 0x080,

    -0x0, -0x080, -0x100, -0x17f, -0x1fd, -0x278, -0x2f1, -0x367,  -0x3da, -0x449,
    -0x4b3, -0x519, -0x579, -0x5d4, -0x629, -0x678, -0x6c0, -0x702, -0x73c, -0x76f,
    -0x79b, -0x7bf, -0x7db, -0x7ef, -0x7fb, -0x7ff, -0x7fb, -0x7ef, -0x7db, -0x7bf,
    -0x79b, -0x76f, -0x73c, -0x702, -0x6c0, -0x678, -0x629, -0x5d4, -0x579, -0x519,
    -0x4b3, -0x449, -0x3da, -0x367, -0x2f1, -0x278, -0x1fd, -0x17f, -0x100, -0x080
  };

  uint32_t sine[SAMPLES] = {0};

  event void Boot.booted()
  {
    uint32_t d0;
    uint32_t d1;
    uint16_t i;

    for(i=0; i<SAMPLES; i++)
    {

      d0 = sine_data[i] * 1024 / (1<<11) + (1 << 11);
      d1 = sine_data[(i+SAMPLES/4)%SAMPLES] * 1024 / (1<<11) + (1 << 11);
      // format: <ch><data><ch><data>
      sine[i] = (((0 << 12) + d0) << 16) + ((1 << 12) + d1);
    }

    call DacControl.start();
    call Dac.configure(
        0, // enable external trigger mode
        0, // select trigger source
        1, // 1: word transfer, 0: half-word
        0, // 1: sleep mode, 0: normal mode
        0, // fast wakeup
        1, // refresh period = 1024 * REFRESH/DACC Clock
        0, // select channel
        1, // 1: bits 13-12 in data select channel
        0, // 1: max speed mode enabled
        8);

    call Dac.enable(0);
    call Dac.enable(1);

    call Dac.setFrequency(12000); // for some reason, we currently have to double the DAC frequency
    call Dac.setBuffer(sine, SAMPLES);
    call Dac.startPdc();
    
    while(call Dac.setBuffer(sine, SAMPLES) == SUCCESS)
    {
    }
  }

  async event void Dac.bufferDone(error_t error, uint32_t *buffer, uint16_t length)
  {
    call Leds.led2Toggle();
    while(call Dac.setBuffer(sine, SAMPLES) == SUCCESS)
    {
    }
  }
}

