/* $Id: MAX136xInternalP.nc,v 1.3 2006-11-07 19:31:27 scipio Exp $ */
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
module MAX136xInternalP {
  provides interface HplMAX136x[uint8_t id];
  uses interface HplMAX136x as ToHPLC;
}

implementation {
  uint8_t currentId;

  command error_t HplMAX136x.measureChannels[uint8_t id](uint8_t *buf, uint8_t len) {
    currentId = id;
    return call ToHPLC.measureChannels(buf, len);
  }
  command error_t HplMAX136x.setConfig[uint8_t id](uint8_t *cfgbuf, uint8_t len) {
    currentId = id;
    return call ToHPLC.setConfig(cfgbuf, len);
  }
  command error_t HplMAX136x.readStatus[uint8_t id](uint8_t *buf, uint8_t len) {
    currentId = id;
    return call ToHPLC.readStatus(buf, len);
  }
  async event void ToHPLC.measureChannelsDone(error_t error, uint8_t *buf, uint8_t len) {
    signal HplMAX136x.measureChannelsDone[currentId](error, buf, len);
  }
  async event void ToHPLC.setConfigDone(error_t error, uint8_t *cfgbuf, uint8_t len) {
    signal HplMAX136x.setConfigDone[currentId](error, cfgbuf, len);
  }
  async event void ToHPLC.alertThreshold() {
    signal HplMAX136x.alertThreshold[currentId]();
  }
  async event void ToHPLC.readStatusDone(error_t error, uint8_t * buf) {
    signal HplMAX136x.readStatusDone[currentId](error, buf);
  }

  default async event void HplMAX136x.measureChannelsDone[uint8_t id]( error_t error, uint8_t *buf, uint8_t len ) {}
  default async event void HplMAX136x.setConfigDone[uint8_t id]( error_t error , uint8_t *cfgbuf, uint8_t len) {}
  default async event void HplMAX136x.alertThreshold[uint8_t id]() {}
  default async event void HplMAX136x.readStatusDone[uint8_t id](error_t error, uint8_t *buf) { }
}
