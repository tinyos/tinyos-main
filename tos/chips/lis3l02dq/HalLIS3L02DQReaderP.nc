/* $Id: HalLIS3L02DQReaderP.nc,v 1.3 2006-11-07 19:30:54 scipio Exp $ */
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
 *
 * @author Kaisen Lin
 * @author Phil Buonadonna
 */

#include "LIS3L02DQ.h"

generic module HalLIS3L02DQReaderP() {
  provides interface Read<uint16_t> as AccelX;
  provides interface Read<uint16_t> as AccelY;
  provides interface Read<uint16_t> as AccelZ;

  uses interface Resource as AccelXResource;
  uses interface Resource as AccelYResource;
  uses interface Resource as AccelZResource;
  uses interface HplLIS3L02DQ as Hpl;
}

implementation {
  enum {
    S_IDLE,
    S_GET_XL,
    S_GET_XH,
    S_GET_YL,
    S_GET_YH,
    S_GET_ZL,
    S_GET_ZH,
  };
  uint8_t state = S_IDLE;
  uint16_t readResult;
  uint8_t byteResult;
  uint8_t errorResult;

  task void complete_Task() {
    switch(state) {
    case S_GET_XL:
      readResult += byteResult;
      state = S_IDLE;
      call AccelXResource.release();
      signal AccelX.readDone(errorResult, readResult);
      break;
    case S_GET_XH:
      readResult = (uint16_t) byteResult & 0xF;
      readResult <<= 8;
      state = S_GET_XL;
      call Hpl.getReg(LIS3L02DQ_OUTX_L);
      break;
    case S_GET_YL:
      readResult += byteResult;
      state = S_IDLE;
      call AccelYResource.release();
      signal AccelY.readDone(errorResult, readResult);
      break;
    case S_GET_YH:
      readResult = (uint16_t) byteResult & 0xF;
      readResult <<= 8;
      state = S_GET_YL;
      call Hpl.getReg(LIS3L02DQ_OUTY_L);
      break;
    case S_GET_ZL:
      readResult += byteResult;
      state = S_IDLE;
      call AccelZResource.release();
      signal AccelZ.readDone(errorResult, readResult);
      break;
    case S_GET_ZH:
      readResult = (uint16_t) byteResult & 0xF;
      readResult <<= 8;
      state = S_GET_ZL;
      call Hpl.getReg(LIS3L02DQ_OUTZ_L);
      break;
    default:
      break;
    }
  }

  command error_t AccelX.read() {
    return call AccelXResource.request();
  }
  command error_t AccelY.read() {
    return call AccelYResource.request();
  }
  command error_t AccelZ.read() {
    return call AccelZResource.request();
  }
  
  event void AccelXResource.granted() {
    errorResult = call Hpl.getReg(LIS3L02DQ_OUTX_H);
    if (errorResult != SUCCESS) {
      state = S_GET_XL;
      post complete_Task();
    }
    state = S_GET_XH;
  }

  event void AccelYResource.granted() {
    errorResult = call Hpl.getReg(LIS3L02DQ_OUTY_H);
    if (errorResult != SUCCESS) {
      state = S_GET_YL;
      post complete_Task();
    }
    state = S_GET_YH;
  }

  event void AccelZResource.granted() {
    errorResult = call Hpl.getReg(LIS3L02DQ_OUTZ_H);
    if (errorResult != SUCCESS) {
      state = S_GET_ZL;
      post complete_Task();
    }
    state = S_GET_ZH;
  }

  async event void Hpl.getRegDone(error_t error, uint8_t regAddr, uint8_t val) {
    errorResult |= error;
    byteResult = val;
    post complete_Task();
  }

  async event void Hpl.setRegDone( error_t error , uint8_t regAddr, uint8_t val) {
    // intentionally left blank
  }

  async event void Hpl.alertThreshold() { }
}
