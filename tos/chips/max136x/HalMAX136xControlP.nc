/* $Id: HalMAX136xControlP.nc,v 1.4 2006-12-12 18:23:06 vlahan Exp $ */
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

module HalMAX136xControlP {
  provides interface HalMAX136xAdvanced;

  uses interface Resource;
  uses interface HplMAX136x;
}

implementation {
  enum {
    S_IDLE,
    S_SETSCANMODE,
    S_SETMONMODE,
    S_SETCONVMODE,
    S_SETCLK,
    S_SETREF,
    S_ENALERT,
    S_GETSTATUS,
  };
  uint8_t state = S_IDLE;

  uint8_t mI2CBuffer[8];
  uint8_t configByteShadow = 0x01;
  uint8_t setupByteShadow = 0x83; // 0x82 actually, but we want extended monitor write
  uint8_t monitorByteShadow = 0x0;

  error_t clientResult;

  task void alert_Task() {
    signal HalMAX136xAdvanced.alertThreshold();
  }

  task void signalDone_Task() {
    switch(state) {
    case S_SETSCANMODE:
      state = S_IDLE;
      call Resource.release();
      signal HalMAX136xAdvanced.setScanModeDone(clientResult);
      break;
    case S_SETMONMODE:
      state = S_IDLE;
      call Resource.release();
      signal HalMAX136xAdvanced.setMonitorModeDone(clientResult);
      break;
    case S_SETCONVMODE:
      state = S_IDLE;
      call Resource.release();
      signal HalMAX136xAdvanced.setConversionModeDone(clientResult);
      break;
    case S_SETCLK:
      state = S_IDLE;
      call Resource.release();
      signal HalMAX136xAdvanced.setClockDone(clientResult);
      break;
    case S_SETREF:
      state = S_IDLE;
      call Resource.release();
      signal HalMAX136xAdvanced.setRefDone(clientResult);
      break;
    case S_ENALERT:
      state = S_IDLE;
      call Resource.release();
      signal HalMAX136xAdvanced.enableAlertDone(clientResult);
      break;
    case S_GETSTATUS:
      state = S_IDLE;
      call Resource.release();
      signal HalMAX136xAdvanced.getStatusDone(clientResult, mI2CBuffer[0], 0);
      break;
    default:
      break;
    }
  }

  command error_t HalMAX136xAdvanced.setScanMode(max136x_scanflag_t mode, uint8_t chanlow, uint8_t chanhigh) {
    // chanlow is always 0 no matter what client says
    error_t status;
    if(state != S_IDLE)
      return FAIL;
    status = call Resource.immediateRequest();
    if(status != SUCCESS)
      return status;
    state = S_SETSCANMODE;

    configByteShadow &= ~(MAX136X_CONFIG_SCAN(0x3) | MAX136X_CONFIG_CS(0xF));
    configByteShadow |= MAX136X_CONFIG_SCAN(0x0);
    configByteShadow |= MAX136X_CONFIG_CS(chanhigh);

    mI2CBuffer[0] = configByteShadow;

    call HplMAX136x.setConfig(mI2CBuffer, 1);
    return SUCCESS;
  }

  command error_t HalMAX136xAdvanced.setMonitorMode(uint8_t chanlow, uint8_t chanhigh, max136x_delayflag_t delay, uint8_t thresholds[12]) {
    // chanlow is always 0 no matter what client says
    uint8_t i;
    error_t status;
    if(state != S_IDLE)
      return FAIL;
    status = call Resource.immediateRequest();
    if(status != SUCCESS)
      return status;
    state = S_SETMONMODE;

    configByteShadow &= ~(MAX136X_CONFIG_SCAN(0x3) | MAX136X_CONFIG_CS(0xF));
    configByteShadow |= MAX136X_CONFIG_SCAN(0x2);
    configByteShadow |= MAX136X_CONFIG_CS(chanhigh);

    monitorByteShadow &= ~MAX136X_MONITOR_DELAY(7);
    monitorByteShadow |= MAX136X_MONITOR_DELAY(delay);

    mI2CBuffer[0] = configByteShadow;
    mI2CBuffer[1] = setupByteShadow;
    mI2CBuffer[2] = monitorByteShadow;
    for(i = 0; i < 12; i++)
      mI2CBuffer[i+3] = thresholds[i];
    
    call HplMAX136x.setConfig(mI2CBuffer, 15);
    return SUCCESS;
  } 

  command error_t HalMAX136xAdvanced.setConversionMode(bool bDifferential, bool bBipolar) {
    error_t status;
    if(state != S_IDLE)
      return FAIL;
    status = call Resource.immediateRequest();
    if(status != SUCCESS)
      return status;
    state = S_SETCONVMODE;

    if(bDifferential)
      configByteShadow &= ~MAX136X_CONFIG_SE;
    else
      configByteShadow |= MAX136X_CONFIG_SE;

    if(bBipolar)
      setupByteShadow |= MAX136X_SETUP_BIP;
    else
      setupByteShadow &= ~MAX136X_SETUP_BIP;

    mI2CBuffer[0] = configByteShadow;
    mI2CBuffer[1] = setupByteShadow;
    call HplMAX136x.setConfig(mI2CBuffer, 2);
    return SUCCESS;
  }

  command error_t HalMAX136xAdvanced.setClock(bool bExtClk) {
    error_t status;
    if(state != S_IDLE)
      return FAIL;
    status = call Resource.immediateRequest();
    if(status != SUCCESS)
      return status;
    state = S_SETCLK;

    if(bExtClk)
      setupByteShadow |= MAX136X_SETUP_EXTCLK;
    else
      setupByteShadow &= ~MAX136X_SETUP_EXTCLK;

    mI2CBuffer[0] = setupByteShadow;
    call HplMAX136x.setConfig(mI2CBuffer, 1);
    return SUCCESS;
  }
  
  command error_t HalMAX136xAdvanced.setRef(max136x_selflag_t sel, bool bInRefPwr) {    error_t status;
    if(state != S_IDLE)
      return FAIL;
    status = call Resource.immediateRequest();
    if(status != SUCCESS)
      return status;
    state = S_SETREF;
    
    if(bInRefPwr)
      setupByteShadow |= MAX136X_SETUP_INTREFOFF;
    else
      setupByteShadow &= ~MAX136X_SETUP_INTREFOFF;

    setupByteShadow &=  ~MAX136X_SETUP_REFAIN3SEL(3);
    setupByteShadow |= MAX136X_SETUP_REFAIN3SEL(sel);

    mI2CBuffer[0] = setupByteShadow;
    call HplMAX136x.setConfig(mI2CBuffer, 1);
    return SUCCESS;
  }

  command error_t HalMAX136xAdvanced.getStatus() {
    error_t status;
    if(state != S_IDLE)
      return FAIL;
    status = call Resource.immediateRequest();
    if(status != SUCCESS)
      return status;
    state = S_GETSTATUS;
    
    return call HplMAX136x.readStatus(mI2CBuffer, 2);
  }

  command error_t HalMAX136xAdvanced.enableAlert(bool bEnable) {
    error_t status;
    if(state != S_IDLE)
      return FAIL;
    status = call Resource.immediateRequest();
    if(status != SUCCESS)
      return status;
    state = S_ENALERT;

    if(bEnable)
      monitorByteShadow |= MAX136X_MONITOR_INTEN;
    else
      monitorByteShadow &= ~MAX136X_MONITOR_INTEN;

    mI2CBuffer[0] = setupByteShadow;
    mI2CBuffer[1] = (0xF0 | monitorByteShadow);
    
    call HplMAX136x.setConfig(mI2CBuffer, 2);
    return SUCCESS;
  }

  event void Resource.granted() {
    // intentionally left blank
  }

  async event void HplMAX136x.readStatusDone(error_t error, uint8_t* buf) {
    clientResult = error;
    post signalDone_Task();
  }

  async event void HplMAX136x.measureChannelsDone( error_t error, uint8_t *buf, uint8_t len ) { /* intentionally left blank */ }
  async event void HplMAX136x.setConfigDone( error_t error , uint8_t *cfgbuf, uint8_t len) {
    clientResult = error;
    post signalDone_Task();
  }
  async event void HplMAX136x.alertThreshold() {
    post alert_Task();
  }
}
