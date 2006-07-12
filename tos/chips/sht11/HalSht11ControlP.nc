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

#include "SensirionSht11.h"

module HalSht11ControlP {
  provides interface HalSht11Advanced;

  uses interface SensirionSht11;
  uses interface Resource;
}

implementation {
  enum {
    S_IDLE,
    S_GETVOLT,
    S_SETHEAT,
    S_SETRES,
  };
  uint8_t state = S_IDLE;
  uint8_t statusRegisterShadow = 0x0;

  error_t clientResult;
  error_t clientVal;

  task void signal_Task() {
    switch(state) {
    case S_GETVOLT:
      state = S_IDLE;
      call Resource.release();
      signal HalSht11Advanced.getVoltageStatusDone(clientResult, clientVal & SHT11_STATUS_LOW_BATTERY_BIT);
      break;
    case S_SETHEAT:
      state = S_IDLE;
      call Resource.release();
      signal HalSht11Advanced.setHeaterDone(clientResult);
      break;
    case S_SETRES:
      state = S_IDLE;
      call Resource.release();
      signal HalSht11Advanced.setResolutionDone(clientResult);
      break;
    default:
      break;
    }
  }

  command error_t HalSht11Advanced.getVoltageStatus() {
    error_t status;
    if(state != S_IDLE)
      return FAIL;
    status = call Resource.immediateRequest();
    if(status != SUCCESS)
      return status;
    state = S_GETVOLT;

    call SensirionSht11.readStatusReg();
    return SUCCESS;
  }

  command error_t HalSht11Advanced.setHeater(bool isOn) {
    error_t status;
    if(state != S_IDLE)
      return FAIL;
    status = call Resource.immediateRequest();
    if(status != SUCCESS)
      return status;
    state = S_SETHEAT;

    if(isOn)
      statusRegisterShadow |= SHT11_STATUS_HEATER_ON_BIT;
    else
      statusRegisterShadow &= ~SHT11_STATUS_HEATER_ON_BIT;

    call SensirionSht11.writeStatusReg(statusRegisterShadow);
    return SUCCESS;
  }

  command error_t HalSht11Advanced.setResolution(bool resolution) {
    error_t status;
    if(state != S_IDLE)
      return FAIL;
    status = call Resource.immediateRequest();
    if(status != SUCCESS)
      return status;
    state = S_SETRES;

    if(resolution)
      statusRegisterShadow |= SHT11_STATUS_LOW_RES_BIT;
    else
      statusRegisterShadow &= ~SHT11_STATUS_LOW_RES_BIT;

    call SensirionSht11.writeStatusReg(statusRegisterShadow);
    return SUCCESS;    
  }

  event void SensirionSht11.readStatusRegDone( error_t result, uint8_t val ) {
    clientResult = result;
    clientVal = val;
    post signal_Task();
  }

  event void SensirionSht11.writeStatusRegDone( error_t result ) {
    clientResult = result;
    post signal_Task();
  }

  event void Resource.granted() { /* intentionally left blank */ }
  event void SensirionSht11.resetDone( error_t result ) {}
  event void SensirionSht11.measureTemperatureDone( error_t result, uint16_t val ) {}
  event void SensirionSht11.measureHumidityDone( error_t result, uint16_t val ) {}

}
