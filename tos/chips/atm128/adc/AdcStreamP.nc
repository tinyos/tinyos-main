/* $Id: AdcStreamP.nc,v 1.12 2008-06-23 23:38:28 idgay Exp $
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
 * Convert ATmega128 HAL A/D interface to the HIL interfaces.
 * @author David Gay
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 */
#include "Timer.h"

module AdcStreamP @safe() {
  provides {
    interface Init @atleastonce();
    interface ReadStream<uint16_t>[uint8_t client];
  }
  uses {
    interface Atm128AdcSingle;
    interface Atm128AdcConfig[uint8_t client];
    interface Atm128Calibrate;
    interface Alarm<TMicro, uint32_t>;
  }
}
implementation {
  enum {
    NSTREAM = uniqueCount(UQ_ADC_READSTREAM)
  };

  /* Resource reservation is required, and it's incorrect to call getData
     again before dataReady is signaled, so there are no races in correct
     programs */
  norace uint8_t client = NSTREAM;

  /* Stream data */
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

  uint8_t channel() {
    return call Atm128AdcConfig.getChannel[client]();
  }

  uint8_t refVoltage() {
    return call Atm128AdcConfig.getRefVoltage[client]();
  }

  uint8_t prescaler() {
    return call Atm128AdcConfig.getPrescaler[client]();
  }

  void sample() {
    call Atm128AdcSingle.getData(channel(), refVoltage(), FALSE, prescaler());
  }

  command error_t ReadStream.postBuffer[uint8_t c](uint16_t *buf, uint16_t n) {
    if (n < sizeof(struct list_entry_t))
      return ESIZE;
    atomic
      {
	struct list_entry_t * ONE newEntry = TCAST(struct list_entry_t * ONE, buf);

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
    uint32_t actualPeriod = call Atm128Calibrate.actualMicro(period);

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
    for (; entry; entry = entry->next){
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
    sample();
  }

  command error_t ReadStream.read[uint8_t c](uint32_t usPeriod)
  {
    /* The first reading may be imprecise. So we just do a dummy read
       to get things rolling - this is indicated by setting count to 0 */
    buffer = pos = NULL;
    count = 0;
    period = call Atm128Calibrate.calibrateMicro(usPeriod);
    client = c;
    sample();

    return SUCCESS;
  }

  void nextBuffer() {
    atomic
      {
	struct list_entry_t *entry = bufferQueue[client];

	if (!entry)
	  {
	    // all done
	    bufferQueueEnd[client] = NULL; // prevent post
	    post readStreamDone();
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
	    nextAlarm();
	  }
      }
  }

  async event void Atm128AdcSingle.dataReady(uint16_t data, bool precise) {
    if (client == NSTREAM)
      return;

    if (count == 0)
      {
	now = call Alarm.getNow();
	nextBuffer();
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
		    return;
		  }
		else
		  {
		    lastCount = count;
		    lastBuffer = buffer;
		  }
	      }
	    post bufferDone();
	    nextBuffer();
	  }
	else
	  nextAlarm();
      }       
  }

  /* Configuration defaults. Read ground fast! ;-) */
  default async command uint8_t Atm128AdcConfig.getChannel[uint8_t c]() {
    return ATM128_ADC_SNGL_GND;
  }

  default async command uint8_t Atm128AdcConfig.getRefVoltage[uint8_t c]() {
    return ATM128_ADC_VREF_OFF;
  }

  default async command uint8_t Atm128AdcConfig.getPrescaler[uint8_t c]() {
    return ATM128_ADC_PRESCALE_2;
  }
}
