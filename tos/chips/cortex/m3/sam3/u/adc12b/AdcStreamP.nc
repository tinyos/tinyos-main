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
 * Implementation for ReadStream interface in Sam3u
 * (Coverted msp430 and atm128 code)
 * @author JeongGil Ko
 */

#include "sam3uadc12bhardware.h"
module AdcStreamP {
  provides {
    interface Init @atleastonce();
    interface ReadStream<uint16_t>[uint8_t client];
  }
  uses {
    interface Sam3uGetAdc12b as GetAdc[uint8_t client];
    interface AdcConfigure<const sam3u_adc12_channel_config_t*> as Config[uint8_t client];
    interface Alarm<TMicro, uint32_t>;
    interface Leds;
  }
}
implementation {
  enum {
    NSTREAM = uniqueCount(ADCC_READ_STREAM_SERVICE)
  };

  norace uint8_t client = NSTREAM;

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

  command error_t Init.init() {
    uint8_t i;

    for (i = 0; i != NSTREAM; i++)
      bufferQueueEnd[i] = &bufferQueue[i];

    return SUCCESS;
  }

  void sampleSingle() {
    call GetAdc.getData[client]();
  }

  error_t postBuffer(uint8_t c, uint16_t *buf, uint16_t n)
  {
    if (n < sizeof(struct list_entry_t))
      return ESIZE;
    atomic
    {
      struct list_entry_t * ONE newEntry = TCAST(struct list_entry_t * ONE, buf);

      if (!bufferQueueEnd[c])
        return FAIL;

      newEntry->count = n;
      newEntry->next = NULL;
      *bufferQueueEnd[c] = newEntry;
      bufferQueueEnd[c] = &newEntry->next;
    }

    return SUCCESS;
  }

  command error_t ReadStream.postBuffer[uint8_t c](uint16_t *buf, uint16_t n) {
    return postBuffer(c, buf, n);
  }

  task void readStreamDone() {
    uint8_t c = client;
    uint32_t actualPeriod = period;

    atomic
    {
      bufferQueue[c] = NULL;
      bufferQueueEnd[c] = &bufferQueue[c];
    }

    client = NSTREAM;
    signal ReadStream.readDone[c](SUCCESS, actualPeriod);
  }

  task void readStreamFail() {
    struct list_entry_t *entry;
    uint8_t c = client;

    atomic entry = bufferQueue[c];
    for (; entry; entry = entry->next) {
      uint16_t tmp_count __DEPUTY_UNUSED__ = entry->count;
      signal ReadStream.bufferDone[c](FAIL, TCAST(uint16_t * COUNT_NOK(tmp_count),entry), entry->count);
    }

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
        uint16_t tmp_count;
        bufferQueue[client] = entry->next;
        if (!bufferQueue[client])
          bufferQueueEnd[client] = &bufferQueue[client];
	pos = buffer = NULL;
        count = entry->count;
        tmp_count = count;
	pos = buffer = TCAST(uint16_t * COUNT_NOK(tmp_count), entry);
        if (startNextAlarm)
          nextAlarm();
        return SUCCESS;
      }
    }
  }

  command error_t ReadStream.read[uint8_t c](uint32_t usPeriod)
  {
    /* not exactly microseconds                 */
    /* ADC is currently based on a 1.5MHz clock */
    period = usPeriod; 
    client = c;
    now = call Alarm.getNow();
    call GetAdc.configureAdc[c](call Config.getConfiguration[c]());
    if (nextBuffer(FALSE) == SUCCESS){
       sampleSingle();
    }
    return SUCCESS;
  }

  async event error_t GetAdc.dataReady[uint8_t streamClient](uint16_t data)
  {
    call Leds.led0Toggle();
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
      if (pos == buffer + count)
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
	    lastCount = count;
            lastBuffer = buffer;
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

  const sam3u_adc12_channel_config_t defaultConfig = {
  };

  default async command const sam3u_adc12_channel_config_t* Config.getConfiguration[uint8_t c]()
  { 
    return &defaultConfig;
  }

  default async command error_t GetAdc.getData[uint8_t c]()
  {
    return FAIL;
  }  
  default async command error_t GetAdc.configureAdc[uint8_t c](
      const sam3u_adc12_channel_config_t *config){ return FAIL; }
}
