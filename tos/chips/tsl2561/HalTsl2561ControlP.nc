/* $Id: HalTsl2561ControlP.nc,v 1.3 2006-11-07 19:31:16 scipio Exp $ */
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

#include "TSL256x.h"

module HalTsl2561ControlP {
  provides interface HalTsl2561Advanced;

  uses interface Resource;
  uses interface HplTSL256x;
}

implementation {
  enum {
    S_IDLE = 0,
    S_GAIN,
    S_INTEG,
    S_PERSIST,
    S_TLOW,
    S_THIGH,
    S_ENALERT,
  };
  uint8_t state = S_IDLE;
  error_t clientResult;

  uint8_t timingRegisterShadow = 0x02;
  uint8_t iControlRegisterShadow = 0x0;
  
  task void complete_Alert() {
    signal HalTsl2561Advanced.alertThreshold();
  }

  task void complete_Task() {
    switch(state) {
    case S_GAIN:
      state = S_IDLE;
      call Resource.release();
      signal HalTsl2561Advanced.setGainDone(clientResult);
      break;
    case S_INTEG:
      state = S_IDLE;
      call Resource.release();
      signal HalTsl2561Advanced.setIntegrationDone(clientResult);
      break;
    case S_PERSIST:
      state = S_IDLE;
      call Resource.release();
      signal HalTsl2561Advanced.setPersistenceDone(clientResult);
      break;
    case S_TLOW:
      state = S_IDLE;
      call Resource.release();
      signal HalTsl2561Advanced.setTLowDone(clientResult);
      break;
    case S_THIGH:
      state = S_IDLE;
      call Resource.release();
      signal HalTsl2561Advanced.setTHighDone(clientResult);
      break;
    case S_ENALERT:
      state = S_IDLE;
      call Resource.release();
      signal HalTsl2561Advanced.enableAlertDone(clientResult);
      break;
    default:
      break;
    }    
  }

  command error_t HalTsl2561Advanced.setGain(bool gainHigh) {
    error_t status;
    if(state != S_IDLE)
      return FAIL;
    status = call Resource.immediateRequest();
    if(status != SUCCESS)
      return status;
    state = S_GAIN;
    if(gainHigh)
      timingRegisterShadow |= TSL256X_TIMING_GAIN;
    else
      timingRegisterShadow &= ~TSL256X_TIMING_GAIN;

    call HplTSL256x.setTIMING(timingRegisterShadow);
    return SUCCESS;
  }

  command error_t HalTsl2561Advanced.setIntegration(uint8_t val) {
    error_t status;
    if(state != S_IDLE)
      return FAIL;
    status = call Resource.immediateRequest();
    if(status != SUCCESS)
      return status;
    state = S_INTEG;
    timingRegisterShadow |= TSL256X_TIMING_MANUAL;
    timingRegisterShadow |= TSL256X_TIMING_INTEG(val);

    call HplTSL256x.setTIMING(timingRegisterShadow);
    return SUCCESS;
  }

  command error_t HalTsl2561Advanced.setPersistence(uint8_t val) {
    error_t status;
    if(state != S_IDLE)
      return FAIL;
    status = call Resource.immediateRequest();
    if(status != SUCCESS)
      return status;
    state = S_PERSIST;
    iControlRegisterShadow &= ~TSL256X_INTERRUPT_PERSIST(0xF);
    iControlRegisterShadow |= TSL256X_INTERRUPT_PERSIST(val);

    call HplTSL256x.setINTERRUPT(iControlRegisterShadow);
    return SUCCESS;
  }

  command error_t HalTsl2561Advanced.setTLow(uint16_t val) {
    error_t status;
    if(state != S_IDLE)
      return FAIL;
    status = call Resource.immediateRequest();
    if(status != SUCCESS)
      return status;
    state = S_TLOW;

    call HplTSL256x.setTHRESHLOW(val);
    return SUCCESS;
  }

  command error_t HalTsl2561Advanced.setTHigh(uint16_t val) {
    error_t status;
    if(state != S_IDLE)
      return FAIL;
    status = call Resource.immediateRequest();
    if(status != SUCCESS)
      return status;
    state = S_THIGH;

    call HplTSL256x.setTHRESHHIGH(val);
    return SUCCESS;
  }

  command error_t HalTsl2561Advanced.enableAlert(bool enable) {
    error_t status;
    if(state != S_IDLE)
      return FAIL;
    
    state = S_ENALERT;
    iControlRegisterShadow &= ~TSL256X_INTERRUPT_INTR(3); // strip off interrupt select
    if(enable)
      iControlRegisterShadow |= TSL256X_INTERRUPT_INTR(1);
    
    status = call Resource.immediateRequest();
    if(status != SUCCESS) {
      status = call Resource.request();
      return status;
    }
    else {
      call HplTSL256x.setINTERRUPT(iControlRegisterShadow);
    }
    return SUCCESS;
  }

  event void Resource.granted() {
    // Only use Queued requests for alertEnable
    if (state == S_ENALERT) {
      call HplTSL256x.setINTERRUPT(iControlRegisterShadow);
    }
    return;
  }

  async event void HplTSL256x.setTIMINGDone(error_t error) {
    clientResult = error;
    post complete_Task();
  }
  async event void HplTSL256x.setINTERRUPTDone(error_t error) {
    clientResult = error;
    post complete_Task();
  }
  async event void HplTSL256x.setTHRESHLOWDone(error_t error) {
    clientResult = error;
    post complete_Task();
  }
  async event void HplTSL256x.setTHRESHHIGHDone(error_t error) {
    clientResult = error;
    post complete_Task();
  }
  async event void HplTSL256x.alertThreshold() { post complete_Alert(); }

  // stubs
  async event void HplTSL256x.getIDDone(error_t error, uint8_t idval) {}

  // intentionally left empty
  async event void HplTSL256x.setCONTROLDone(error_t error) {}
  async event void HplTSL256x.measureCh0Done(error_t error, uint16_t val) {}
  async event void HplTSL256x.measureCh1Done(error_t error, uint16_t val) {}

  // default stuff
  /*
  default event void HalTsl2561Advanced.setGainDone(error_t error) {}
  default event void HalTsl2561Advanced.setIntegrationDone(error_t error) {}
  default event void HalTsl2561Advanced.setPersistenceDone(error_t error) {}
  default event void HalTsl2561Advanced.setTLowDone(error_t error) {}
  default event void HalTsl2561Advanced.setTHighDone(error_t error) {}
  default event void HalTsl2561Advanced.enableAlertDone(error_t error) {}
  default event void HalTsl2561Advanced.alertThreshold() {}
  */
}
