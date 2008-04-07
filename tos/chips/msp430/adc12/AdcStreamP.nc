/* $Id: AdcStreamP.nc,v 1.1 2008-04-07 09:41:55 janhauer Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 *
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

/**
 * Convert MSP430 HAL A/D interface to the HIL interfaces (adapted atmega code).
 * @author David Gay
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 */
#include "Timer.h"

module AdcStreamP {
  provides {
    interface Init @atleastonce();
    interface ReadStream<uint16_t>[uint8_t client];
  }
  uses {
    interface Msp430Adc12SingleChannel as SingleChannel[uint8_t client];
    interface AdcConfigure<const msp430adc12_channel_config_t*>[uint8_t client];
    interface Alarm<TMilli, uint32_t>;
  }
}
implementation {
  enum {
    NSTREAM = uniqueCount(ADCC_READ_STREAM_SERVICE)
  };

  /* Resource reservation is required, and it's incorrect to call getData
     again before dataReady is signaled, so there are no races in correct
     programs */
  norace uint8_t client = NSTREAM;

  /* Stream data */
  struct list_entry_t {
    uint16_t count;
    struct list_entry_t *next;
  };
  struct list_entry_t *bufferQueue[NSTREAM];
  struct list_entry_t **bufferQueueEnd[NSTREAM];
  uint16_t *lastBuffer, lastCount;

  norace uint16_t *buffer, *pos, count;
  norace uint32_t now, period;
  norace bool periodModified;


  command error_t Init.init() {
    uint8_t i;

    for (i = 0; i != NSTREAM; i++)
      bufferQueueEnd[i] = &bufferQueue[i];

    return SUCCESS;
  }

  void sampleSingle() {
    call SingleChannel.getData[client]();
  }

  command error_t ReadStream.postBuffer[uint8_t c](uint16_t *buf, uint16_t n) {
    if (n < sizeof(struct list_entry_t))
      return ESIZE;
    atomic
    {
      struct list_entry_t *newEntry = (struct list_entry_t *)buf;

      if (!bufferQueueEnd[c]) // Can't post right now.
        return FAIL;

      newEntry->count = n;
      newEntry->next = NULL;
      *bufferQueueEnd[c] = newEntry;
      bufferQueueEnd[c] = &newEntry->next;
    }
    return SUCCESS;
  }

  task void readStreamDone() {
    uint8_t c = client;
    uint32_t actualPeriod = period;
    if (periodModified)
      actualPeriod = period - (period % 1000);

    atomic
    {
      bufferQueue[c] = NULL;
      bufferQueueEnd[c] = &bufferQueue[c];
    }

    client = NSTREAM;
    signal ReadStream.readDone[c](SUCCESS, actualPeriod);
  }

  task void readStreamFail() {
    /* By now, the pending bufferDone has been signaled (see readStream). */
    struct list_entry_t *entry;
    uint8_t c = client;

    atomic entry = bufferQueue[c];
    for (; entry; entry = entry->next)
      signal ReadStream.bufferDone[c](FAIL, (uint16_t *)entry, entry->count);

    atomic
    {
      bufferQueue[c] = NULL;
      bufferQueueEnd[c] = &bufferQueue[c];
    }

    client = NSTREAM;
    signal ReadStream.readDone[c](FAIL, 0);
  }

  task void bufferDone() {
    uint16_t *b, c;
    atomic
    {
      b = lastBuffer;
      c = lastCount;
      lastBuffer = NULL;
    }

    signal ReadStream.bufferDone[client](SUCCESS, b, c);
  }

  void nextAlarm() {
    call Alarm.startAt(now, period);
    now += period;
  }

  async event void Alarm.fired() {
    sampleSingle();
  }

  error_t nextBuffer(bool startNextAlarm) {
    atomic
    {
      struct list_entry_t *entry = bufferQueue[client];

      if (!entry)
      {
        // all done
        bufferQueueEnd[client] = NULL; // prevent post
        post readStreamDone();
        return FAIL;
      }
      else
      {
        bufferQueue[client] = entry->next;
        if (!bufferQueue[client])
          bufferQueueEnd[client] = &bufferQueue[client];
        pos = buffer = (uint16_t *)entry;
        count = entry->count;
        if (startNextAlarm)
          nextAlarm();
        return SUCCESS;
      }
    }
  }

  void nextMultiple(uint8_t c)
  {
    if (nextBuffer(FALSE) == SUCCESS){
      msp430adc12_channel_config_t config = *call AdcConfigure.getConfiguration[c]();
      config.sampcon_ssel = SAMPCON_SOURCE_SMCLK; // assumption: SMCLK runs at 1 MHz
      config.sampcon_id = SAMPCON_CLOCK_DIV_1; 
      call SingleChannel.configureMultiple[c]( &config, pos, count, period);
      call SingleChannel.getData[c]();
    }
  }

  command error_t ReadStream.read[uint8_t c](uint32_t usPeriod)
  {
    if (usPeriod & 0xFFFF0000){
      // "manual" sampling
      period = usPeriod / 1000;
      periodModified = TRUE;
      client = c;
      now = call Alarm.getNow();
      call SingleChannel.configureSingle[c](call AdcConfigure.getConfiguration[c]());
      if (nextBuffer(FALSE) == SUCCESS)
        sampleSingle();
    } else {
      period = usPeriod;
      periodModified = FALSE;
      client = c;
      nextMultiple(c);
    }
    return SUCCESS;
  }


  async event error_t SingleChannel.singleDataReady[uint8_t streamClient](uint16_t data)
  {
    if (client == NSTREAM)
      return FAIL;

    if (count == 0)
    {
      now = call Alarm.getNow();
      nextBuffer(TRUE);
    }
    else
    {
      *pos++ = data;
      if (!--count)
      {
        atomic
        {
          if (lastBuffer)
          {
            /* We failed to signal bufferDone in time. Fail. */
            bufferQueueEnd[client] = NULL; // prevent post
            post readStreamFail();
            return FAIL;
          }
          else
          {
            lastBuffer = buffer;
            lastCount = pos - buffer;
          }
        }
        post bufferDone();
        nextBuffer(TRUE);
      }
      else
        nextAlarm();
    }
    return FAIL;
  }
  
  async event uint16_t* SingleChannel.multipleDataReady[uint8_t streamClient](
      uint16_t *buf, uint16_t length)
  {
    atomic
    {
      if (lastBuffer)
      {
        /* We failed to signal bufferDone in time. Fail. */
        bufferQueueEnd[client] = NULL; // prevent post
        post readStreamFail();
        return 0;
      }
      else
      {
        lastBuffer = buffer;
        lastCount = pos - buffer;
      }
    }
    post bufferDone();
    nextMultiple(streamClient);
    return 0;
  }

  const msp430adc12_channel_config_t defaultConfig = {
      inch: SUPPLY_VOLTAGE_HALF_CHANNEL,
      sref: REFERENCE_VREFplus_AVss,
      ref2_5v: REFVOLT_LEVEL_1_5,
      adc12ssel: SHT_SOURCE_ACLK,
      adc12div: SHT_CLOCK_DIV_1,
      sht: SAMPLE_HOLD_4_CYCLES,
      sampcon_ssel: SAMPCON_SOURCE_SMCLK,
      sampcon_id: SAMPCON_CLOCK_DIV_1
  };
  default async command const msp430adc12_channel_config_t* AdcConfigure.getConfiguration[uint8_t c]()
  { 
    return &defaultConfig;
  }
  default async command error_t SingleChannel.configureMultiple[uint8_t c](
      const msp430adc12_channel_config_t *config, uint16_t b[], 
      uint16_t numSamples, uint16_t jiffies)
  {
    return FAIL;
  }
  default async command error_t SingleChannel.getData[uint8_t c]()
  {
    return FAIL;
  }  
  default async command error_t SingleChannel.configureSingle[uint8_t c](
      const msp430adc12_channel_config_t *config){ return FAIL; }
}
