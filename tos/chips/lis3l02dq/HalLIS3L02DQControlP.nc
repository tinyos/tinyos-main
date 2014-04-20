/* $Id: HalLIS3L02DQControlP.nc,v 1.4 2006-12-12 18:23:06 vlahan Exp $ */
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

module HalLIS3L02DQControlP {
  provides interface HalLIS3L02DQAdvanced as Advanced;

  uses interface Resource;
  uses interface HplLIS3L02DQ as Hpl;
}

implementation {
  enum {
    S_IDLE,
    S_DECIMATION,
    S_ENAXIS,
    S_TLOW,
    S_THIGH,
  };
  uint8_t state = S_IDLE;

  uint8_t ctrlReg1Shadow = 0x7;
  
  error_t clientResult;
  uint8_t clientRegAddr;
  uint8_t clientVal;

  task void signal_Task() {
  	uint8_t loc_clientResult;
  	
  	atomic loc_clientResult = clientResult;
  	
    switch(state) {
    case S_DECIMATION:
      state = S_IDLE;
      call Resource.release();
      signal Advanced.setDecimationDone(loc_clientResult);
      break;
    case S_ENAXIS:
      state = S_IDLE;
      call Resource.release();
      signal Advanced.enableAxisDone(loc_clientResult);
      break;
    case S_TLOW:
      state = S_IDLE;
      call Resource.release();
      signal Advanced.setTLowDone(loc_clientResult);
      break;
    case S_THIGH:
      state = S_IDLE;
      call Resource.release();
      signal Advanced.setTHighDone(loc_clientResult);
      break;
    default:
      break;
    }
  }

  event void Resource.granted() {
    // intentionally left blank
  }
  
  command error_t Advanced.setDecimation(uint8_t factor) {
    error_t status;
    if(state != S_IDLE)
      return FAIL;
    status = call Resource.immediateRequest();
    if(status != SUCCESS)
      return status;
    state = S_DECIMATION;
    ctrlReg1Shadow &= ~LIS3L01DQ_CTRL_REG1_DF(3);
    ctrlReg1Shadow |= LIS3L01DQ_CTRL_REG1_DF(factor);
    call Hpl.setReg(LIS3L02DQ_CTRL_REG1, ctrlReg1Shadow);
    return SUCCESS;
  }

 command error_t Advanced.enableAxis(bool bX, bool bY, bool bZ) {
    error_t status;
    if(state != S_IDLE)
      return FAIL;
    status = call Resource.immediateRequest();
    if(status != SUCCESS)
      return status;
    state = S_ENAXIS;
    ctrlReg1Shadow &= ~LIS3L01DQ_CTRL_REG1_DF(7);
    // if any of them on, power it on
    if(bZ || bY || bX)
      ctrlReg1Shadow |= LIS3L01DQ_CTRL_REG1_PD(1);

    // enable all the relevant axes
    if(bZ)
      ctrlReg1Shadow |= LIS3L01DQ_CTRL_REG1_DF(LIS3L01DQ_CTRL_REG1_ZEN);
    if(bY)
      ctrlReg1Shadow |= LIS3L01DQ_CTRL_REG1_DF(LIS3L01DQ_CTRL_REG1_YEN);
    if(bX)
      ctrlReg1Shadow |= LIS3L01DQ_CTRL_REG1_DF(LIS3L01DQ_CTRL_REG1_XEN);
    call Hpl.setReg(LIS3L02DQ_CTRL_REG1, ctrlReg1Shadow);
    return SUCCESS;
  }

  command error_t Advanced.setTLow(uint8_t val) {
    error_t status;
    if(state != S_IDLE)
      return FAIL;
    status = call Resource.immediateRequest();
    if(status != SUCCESS)
      return status;
    state = S_TLOW;
    call Hpl.setReg(LIS3L02DQ_THS_L, val);
    return SUCCESS;
  }

  command error_t Advanced.setTHigh(uint8_t val) {
    error_t status;
    if(state != S_IDLE)
      return FAIL;
    status = call Resource.immediateRequest();
    if(status != SUCCESS)
      return status;
    state = S_THIGH;
    call Hpl.setReg(LIS3L02DQ_THS_H, val);
    return SUCCESS;
  }

  async event void Hpl.getRegDone(error_t error, uint8_t regAddr, uint8_t val) {}
  async event void Hpl.alertThreshold() {}
  
  async event void Hpl.setRegDone(error_t error, uint8_t regAddr, uint8_t val) {
    clientResult = error;
    clientRegAddr = regAddr;
    clientVal = val;
    post signal_Task();
  }

  command error_t Advanced.enableAlert(lis_alertflags_t xFlags,
				       lis_alertflags_t yFlags,
				       lis_alertflags_t zFlags,
				       bool requireAll) {
    return FAIL;
  }
  command error_t Advanced.getAlertSource() { return FAIL; }
}
