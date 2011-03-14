/* $Id: AdcP.nc,v 1.1 2009-09-07 14:12:25 r-studio Exp $
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
 * Convert M16c60 HAL A/D interface to the HIL interfaces.
 * @author Fan Zhang <fanzha@ltu.se>
 */
#include "Timer.h"

module AdcP
{
  provides {
    interface Read<uint16_t>[uint8_t client];
    interface ReadNow<uint16_t>[uint8_t client];
  }
  uses {
    interface M16c60AdcSingle;
    interface M16c60AdcConfig[uint8_t client];
  }
}
implementation {
  enum {
    IDLE,
    ACQUIRE_DATA,
    ACQUIRE_DATA_NOW,
  };

  /* Resource reservation is required, and it's incorrect to call getData
     again before dataReady is signaled, so there are no races in correct
     programs */
  norace uint8_t state;
  norace uint8_t client;
  norace uint16_t val;

  uint8_t channel() {
    return call M16c60AdcConfig.getChannel[client]();
  }

  uint8_t precision() {
    return call M16c60AdcConfig.getPrecision[client]();
  }

  uint8_t prescaler() {
    return call M16c60AdcConfig.getPrescaler[client]();
  }

  void sample() {
    call M16c60AdcSingle.getData(channel(), precision(), prescaler());
  }

  error_t startGet(uint8_t newState, uint8_t newClient) {
    /* Note: we retry imprecise results in dataReady */
    state = newState;
    client = newClient;
    sample();

    return SUCCESS;
  }

  command error_t Read.read[uint8_t c]() {
    return startGet(ACQUIRE_DATA, c);
  }

  async command error_t ReadNow.read[uint8_t c]() {
    return startGet(ACQUIRE_DATA_NOW, c);
  }

  task void acquiredData() {
    state = IDLE;
    signal Read.readDone[client](SUCCESS, val);
  }

  async event void M16c60AdcSingle.dataReady(uint16_t data, bool precise) {
    switch (state)
    {
      case ACQUIRE_DATA:
		if (!precise)
		  sample();
		else
		{
		    val = data;
		    post acquiredData();
		}
		break;

      case ACQUIRE_DATA_NOW:
		if (!precise)
		  sample();
		else
		{
		    state = IDLE;
		    signal ReadNow.readDone[client](SUCCESS, data);
		}
		break;

      default:
		break;
     }
  }

  /* Configuration defaults. Read ground fast! ;-) */
  default async command uint8_t M16c60AdcConfig.getChannel[uint8_t c]() {
    return M16c60_ADC_CHL_AN0;
  }

  default async command uint8_t M16c60AdcConfig.getPrecision[uint8_t c]() {
    return M16c60_ADC_PRECISION_10BIT;
  }

  default async command uint8_t M16c60AdcConfig.getPrescaler[uint8_t c]() {
    return M16c60_ADC_PRESCALE_2;
  }

  default event void Read.readDone[uint8_t c](error_t e, uint16_t d) { }
  default async event void ReadNow.readDone[uint8_t c](error_t e, uint16_t d) { }
}
