/* $Id: TMP175InternalP.nc,v 1.3 2006-11-07 19:31:27 scipio Exp $ */
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
module TMP175InternalP {
  provides interface HplTMP175[uint8_t id];
  uses interface HplTMP175 as ToHPLC;
}

implementation {
  uint8_t currentId;

  command error_t HplTMP175.measureTemperature[uint8_t id]() {
    currentId = id;
    return call ToHPLC.measureTemperature();
  }
  command error_t HplTMP175.setConfigReg[uint8_t id](uint8_t val) {
    currentId = id;
    return call ToHPLC.setConfigReg(val);
  }
  command error_t HplTMP175.setTLowReg[uint8_t id](uint16_t val) {
    currentId = id;
    return call ToHPLC.setTLowReg(val);
  }
  command error_t HplTMP175.setTHighReg[uint8_t id](uint16_t val) {
    currentId = id;
    return call ToHPLC.setTHighReg(val);
  }

  async event void ToHPLC.measureTemperatureDone(error_t error, uint16_t val) {
    signal HplTMP175.measureTemperatureDone[currentId](error, val);
  }
  async event void ToHPLC.setConfigRegDone(error_t error) {
    signal HplTMP175.setConfigRegDone[currentId](error);
  }
  async event void ToHPLC.setTLowRegDone(error_t error) {
    signal HplTMP175.setTLowRegDone[currentId](error);
  }
  async event void ToHPLC.setTHighRegDone(error_t error) {
    signal HplTMP175.setTHighRegDone[currentId](error);
  }
  async event void ToHPLC.alertThreshold() {
    signal HplTMP175.alertThreshold[currentId]();
  }

  default async event void HplTMP175.measureTemperatureDone[uint8_t id](error_t error, uint16_t val) { return; }
  default async event void HplTMP175.setConfigRegDone[uint8_t id](error_t error) { return; }
  default async event void HplTMP175.setTLowRegDone[uint8_t id](error_t error) { return; }
  default async event void HplTMP175.setTHighRegDone[uint8_t id](error_t error) { return; }
  default async event void HplTMP175.alertThreshold[uint8_t id]() { return; }
}
