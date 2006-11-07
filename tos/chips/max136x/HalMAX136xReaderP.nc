/* $Id: HalMAX136xReaderP.nc,v 1.3 2006-11-07 19:30:54 scipio Exp $ */
/*
 * Copyright (c) 2005 Arch Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arch Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/**
 *
 * @author Kaisen Lin
 * @author Phil Buonadonna
 */

#include "MAX136x.h"

generic module HalMAX136xReaderP()
{
  provides interface Read<max136x_data_t> as ADC;

  uses interface HplMAX136x;
  uses interface Resource as MAX136xResource;
}

implementation {

  uint8_t channelBuf[2];
  
  command error_t ADC.read() {
    return call MAX136xResource.request();
  }

  event void MAX136xResource.granted() {
    error_t error;

    error = call HplMAX136x.measureChannels(channelBuf, 2);
    if (error) {
      call MAX136xResource.release();
      signal ADC.readDone(error,0);
    }
  }

  async event void HplMAX136x.measureChannelsDone(error_t error,
						  uint8_t *buf,
						  uint8_t len)
  {
    uint16_t result = 0;
    result = buf[0];
    result <<= 8;
    result += buf[1];
    call MAX136xResource.release();
    signal ADC.readDone(error,result);
    return;
  }

  async event void HplMAX136x.setConfigDone(error_t error,
					    uint8_t *cfgbuf,
					    uint8_t len)
  {
    // intentionally left blank
  }

  async event void HplMAX136x.alertThreshold() {}
  async event void HplMAX136x.readStatusDone(error_t error, uint8_t* buf) { }
}
