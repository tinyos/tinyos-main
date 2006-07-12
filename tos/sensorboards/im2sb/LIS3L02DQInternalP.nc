/* $Id: LIS3L02DQInternalP.nc,v 1.2 2006-07-12 17:03:16 scipio Exp $ */
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
 * This Hal module implements the TinyOS 2.0 I2CPacket interface over
 * the PXA27x I2C Hpl
 *
 * @author Kaisen Lin
 * @author Phil Buonadonna
 */

module LIS3L02DQInternalP {
  provides interface HplLIS3L02DQ[uint8_t id];
  uses interface HplLIS3L02DQ as ToHPLC;
}

implementation {
  uint8_t currentId;

  command error_t HplLIS3L02DQ.getReg[uint8_t id](uint8_t regAddr) {
    currentId = id;
    return call ToHPLC.getReg(regAddr);
  }
  command error_t HplLIS3L02DQ.setReg[uint8_t id](uint8_t regAddr, uint8_t val) {
    currentId = id;
    return call ToHPLC.setReg(regAddr, val);
  }
  async event void ToHPLC.getRegDone(error_t error, uint8_t regAddr, uint8_t val) {
    signal HplLIS3L02DQ.getRegDone[currentId](error, regAddr, val);
  }
  async event void ToHPLC.setRegDone(error_t error, uint8_t regAddr, uint8_t val) {
    signal HplLIS3L02DQ.setRegDone[currentId](error, regAddr, val);
  }
  async event void ToHPLC.alertThreshold() {
    signal HplLIS3L02DQ.alertThreshold[currentId]();
  }

  default async event void HplLIS3L02DQ.getRegDone[uint8_t id](error_t error, uint8_t regAddr, uint8_t val) { }
  default async event void HplLIS3L02DQ.setRegDone[uint8_t id](error_t error, uint8_t regAddr, uint8_t val) { }
}
