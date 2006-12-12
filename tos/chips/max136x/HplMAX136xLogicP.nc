/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * MAX136xLogicP is the driver for the MAXIM 136x series ADC chip. 
 * It requires an I2C packet interface and provides the HplMAX136x HPL
 * interface.
 *
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * @version $Revision: 1.4 $ $Date: 2006-12-12 18:23:06 $
 */

#include "I2C.h"

generic module HplMAX136xLogicP(uint16_t devAddr)
{
  provides interface Init;
  provides interface SplitControl;
  provides interface HplMAX136x;

  uses interface I2CPacket<TI2CBasicAddr>;
  uses interface GpioInterrupt as InterruptAlert;
  uses interface GeneralIO as InterruptPin;
}

implementation {

  enum {
    STATE_IDLE,
    STATE_STARTING,
    STATE_STOPPING,
    STATE_STOPPED,
    STATE_READCH,
    STATE_SETCONFIG,
    STATE_READSTATUS,
    STATE_ERROR,
  };

  uint8_t mState;
  bool mStopRequested;
  norace error_t mSSError;

  static error_t doWrite(uint8_t nextState, uint8_t *buf, uint8_t len) {
    error_t error = SUCCESS;

    atomic {
      if (mState == STATE_IDLE) { 
	mState = nextState;
      }
      else {
	error = EBUSY; 
      }
    }
    if (error)
      return error;

    error = call I2CPacket.write(I2C_START | I2C_STOP, devAddr,len,buf);
    
    if (error) 
      atomic mState = STATE_IDLE;

    return error;
  }

  static error_t doRead(uint8_t nextState, uint8_t *buf, uint8_t len) {
    error_t error = SUCCESS;

    atomic {
      if (mState == STATE_IDLE) {
	mState = nextState;
      }
      else {
	error = EBUSY;
      }
    }
    if (error)
      return error;

    error = call I2CPacket.read(I2C_START | I2C_STOP, devAddr,len,buf);

    if (error)
      atomic mState = STATE_IDLE;

    return error;
  }

  task void StartDone() {
    atomic mState = STATE_IDLE;
    signal SplitControl.startDone(SUCCESS);
    return;
  }

  task void StopDone() {
    atomic mState = STATE_STOPPED;
    signal SplitControl.stopDone(mSSError);
    return;
  }

  command error_t Init.init() {
    call InterruptPin.makeInput();
    call InterruptAlert.enableFallingEdge();
    atomic {
      mStopRequested = FALSE;
      mState = STATE_STOPPED;
    }
    return SUCCESS;
  }

  command error_t SplitControl.start() {
    error_t error = SUCCESS;
    atomic {
      if (mState == STATE_STOPPED) { 
	mState = STATE_STARTING;
      }
      else {
	error = EBUSY;
      }
    }
    if (error) 
      return error;
    
    return post StartDone();
  }

  command error_t SplitControl.stop() {
    error_t error = SUCCESS;

    atomic {
      if (mState == STATE_IDLE) {
	mState = STATE_STOPPING;
      }
      else { 
	error = EBUSY;
      }
    }
    if (error)
      return error;

    return post StopDone();
  }

  command error_t HplMAX136x.readStatus(uint8_t *buf, uint8_t len) {
    return doRead(STATE_READSTATUS,buf,len);
  }
  
  command error_t HplMAX136x.measureChannels(uint8_t *buf, uint8_t len) { 
    return doRead(STATE_READCH,buf,len);
  }

  command error_t HplMAX136x.setConfig(uint8_t *configbuf, uint8_t len) {
    return doWrite(STATE_SETCONFIG,configbuf,len);
  }

  async event void I2CPacket.readDone(error_t i2c_error, uint16_t chipAddr, uint8_t len, uint8_t *buf) {
    error_t error = i2c_error;

    switch (mState) {
    case STATE_READCH:
      mState = STATE_IDLE;
      signal HplMAX136x.measureChannelsDone(error, buf, len);
      break;
    case STATE_READSTATUS:
      mState = STATE_IDLE;
      signal HplMAX136x.readStatusDone(error, buf);
      break;
    default:
      mState = STATE_IDLE;
      break;
    }
    return;
  }

  async event void I2CPacket.writeDone(error_t i2c_error, uint16_t chipAddr, uint8_t len, uint8_t *buf) {
    error_t error = i2c_error;

    switch (mState) {
    case STATE_SETCONFIG:
      mState = STATE_IDLE;
      signal HplMAX136x.setConfigDone(error,buf,len);
      break;
    default:
      mState = STATE_IDLE;
      break;
    }
    return;
  }

  async event void InterruptAlert.fired() {
    // This alert is decoupled from whatever state the MAX136x is in. 
    // Upper layers must handle dealing with this alert appropriately.
    signal HplMAX136x.alertThreshold();
    return;
  }

  default event void SplitControl.startDone( error_t error ) { return; }
  default event void SplitControl.stopDone( error_t error ) { return; }

  default async event void HplMAX136x.alertThreshold(){ return; }

}
