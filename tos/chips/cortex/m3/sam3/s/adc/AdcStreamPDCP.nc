/*
 * Copyright (c) 2009 Johns Hopkins University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Implementation for ReadStream interface with PDC in Sam3
 * @author JeongGil Ko
 */

#include "sam3sadchardware.h"
module AdcStreamPDCP {
  provides {
    interface Init @atleastonce();
    interface ReadStream<uint16_t>[uint8_t client];
  }
  uses {
    interface Sam3sGetAdc as GetAdc[uint8_t client];
    interface AdcConfigure<const sam3s_adc_channel_config_t*> as Config[uint8_t client];
    interface HplSam3Pdc as HplPdc;
    interface Leds;
  }
}
implementation {
  enum {
    NSTREAM = uniqueCount(ADCC_READ_STREAM_SERVICE)
  };

  norace uint8_t client = NSTREAM;
  adc_cr_t cr;

  struct list_entry_t {
    uint16_t count;
    struct list_entry_t * ONE_NOK next;
  };
  struct list_entry_t *bufferQueue[NSTREAM];
  struct list_entry_t * ONE_NOK * bufferQueueEnd[NSTREAM];
  uint16_t * COUNT_NOK(lastCount) lastBuffer, lastCount;

  norace uint16_t count;
  norace uint16_t * COUNT_NOK(count) buffer; 
  norace uint16_t * BND_NOK(buffer, buffer+count) pos;
  norace uint32_t now, period;
  norace uint16_t originalLength;
  norace uint16_t *originalPointer;
  norace uint8_t state;

  enum{
    S_READ,
    S_IDLE,
  };

  command error_t Init.init() {
    uint8_t i;
    state = S_IDLE;
    for (i = 0; i != NSTREAM; i++)
      bufferQueueEnd[i] = &bufferQueue[i];

    return SUCCESS;
  }

  void samplePdc() {
    // switch this to pdc enable
    call HplPdc.enablePdcRx();
    atomic cr.bits.start = 1; // enable software trigger
    atomic ADC->cr = cr;  

  }

  command error_t ReadStream.postBuffer[uint8_t c](uint16_t *buf, uint16_t n) {
    // set parameters here!!!!
    // set pdc buffers and set the length as a global parameter
    originalLength = n;
    originalPointer = buf;
    call HplPdc.setRxPtr(buf);
    call HplPdc.setRxCounter(n);
    return SUCCESS;
  }

  command error_t ReadStream.read[uint8_t c](uint32_t usPeriod)
  {
    period = usPeriod; 
    client = c;
    call GetAdc.configureAdc[c](call Config.getConfiguration[c]());
    state = S_READ;
    //samplePdc();
    call GetAdc.getData[c]();
    call HplPdc.enablePdcRx();
    return SUCCESS;
  }

  task void signalReadDone(){
    signal ReadStream.readDone[client](SUCCESS, period);
  }

  task void signalBufferDone(){
    signal ReadStream.bufferDone[client](SUCCESS, originalPointer, originalLength);
  }

  async event error_t GetAdc.dataReady[uint8_t streamClient](uint16_t data)
  {
    if(state == S_READ){
      atomic state = S_IDLE;
      call HplPdc.disablePdcRx();
      post signalReadDone();
      post signalBufferDone();
    }
    return SUCCESS;
  }

  const sam3s_adc_channel_config_t defaultConfig = {
  };

  default async command const sam3s_adc_channel_config_t* Config.getConfiguration[uint8_t c]()
  { 
    return &defaultConfig;
  }

  default async command error_t GetAdc.getData[uint8_t c]()
  {
    return FAIL;
  }  
  default async command error_t GetAdc.configureAdc[uint8_t c](
      const sam3s_adc_channel_config_t *config){ return FAIL; }
}
