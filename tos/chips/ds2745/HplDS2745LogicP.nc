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
 * - Neither the name of the Arched Rock Corporation nor the names of
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
 * HplDS2745LogicP is the driver for the Dallas DS2745. It requires an 
 * I2C packet interface and provides the HplTMP175 HPL interface.
 * 
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * @version $Revision: 1.4 $ $Date: 2006-12-12 18:23:06 $
 */

#include "DS2745.h"
#include "I2C.h"

generic module HplDS2745LogicP(uint16_t devAddr)
{
  provides interface Init;
  provides interface SplitControl;
  provides interface HplDS2745;

  uses interface I2CPacket<TI2CBasicAddr>;

}

implementation {

  enum {
    STATE_IDLE,
    STATE_STARTING,
    STATE_STOPPING,
    STATE_STOPPED,
    STATE_SETCONFIG,
    STATE_READTEMP,
    STATE_READVOLTAGE,
    STATE_READCURRENT,
    STATE_READACCCURRENT,
    STATE_SETBIAS,
    STATE_SETACCBIAS
  };

  uint8_t mI2CBuffer[4];
  uint8_t mState;
  norace error_t mSSError = SUCCESS;

  static error_t doReadReg(uint8_t nextState, uint8_t reg) {
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

    mI2CBuffer[0] = reg;

    error = call I2CPacket.write(I2C_START,devAddr,1,mI2CBuffer);
    
    if (error) 
      atomic mState = STATE_IDLE;

    return error;

  }

  static error_t doSetReg(uint8_t nextState, uint8_t reg, uint16_t val) {
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

    mI2CBuffer[0] = reg;
    mI2CBuffer[1] = val;

    error = call I2CPacket.write((I2C_START | I2C_STOP),devAddr,2,mI2CBuffer);
    
    if (error) 
      atomic mState = STATE_IDLE;

    return error;
  }

  task void StartDone() {
    atomic mState = STATE_IDLE;
    signal SplitControl.startDone(mSSError);
    return;
  }

  task void StopDone() {
    atomic mState = STATE_STOPPED;
    signal SplitControl.stopDone(mSSError);
    return;
  }

  command error_t Init.init() {
    mState = STATE_STOPPED;
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
    if (!error)
      post StartDone();

    return error;
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
    if (!error)
      post StopDone();

    return error;
  }
  
  command error_t HplDS2745.setConfig(uint8_t val) {
    return doSetReg(STATE_SETCONFIG,DS2745_PTR_SC,val);
  }

  command error_t HplDS2745.measureTemperature() { 
    return doReadReg(STATE_READTEMP,DS2745_PTR_TEMPMSB);
  }

  command error_t HplDS2745.measureVoltage() { 
    return doReadReg(STATE_READVOLTAGE,DS2745_PTR_VOLTMSB);
  }

  command error_t HplDS2745.measureCurrent() { 
    return doReadReg(STATE_READCURRENT,DS2745_PTR_CURRMSB);
  }

  command error_t HplDS2745.measureAccCurrent() { 
    return doReadReg(STATE_READTEMP,DS2745_PTR_ACCURMSB);
  }

  command error_t HplDS2745.setOffsetBias(int8_t val) { 
    return doSetReg(STATE_SETBIAS,DS2745_PTR_OFFSETBIAS,val); 
  }

  command error_t HplDS2745.setAccOffsetBias(int8_t val) {
    return doSetReg(STATE_SETACCBIAS,DS2745_PTR_ACCBIAS,val); 
  }

  async event void I2CPacket.readDone(error_t i2c_error, uint16_t chipAddr, uint8_t len, uint8_t *buf) {
    uint16_t tempVal;
    tempVal = buf[0];
    tempVal = ((tempVal << 8) | buf[1]);

    switch (mState) {
    case STATE_READTEMP:
      signal HplDS2745.measureTemperatureDone(i2c_error,tempVal);
      break;
    case STATE_READVOLTAGE:
      signal HplDS2745.measureVoltageDone(i2c_error,tempVal);
      break;
    case STATE_READCURRENT:
      signal HplDS2745.measureCurrentDone(i2c_error,tempVal);
      break;
    case STATE_READACCCURRENT:
      signal HplDS2745.measureAccCurrentDone(i2c_error,tempVal);
      break;
    default:
      break;
    }
    atomic mState = STATE_IDLE;
    return;
  }

  async event void I2CPacket.writeDone(error_t i2c_error, uint16_t chipAddr, uint8_t len, uint8_t *buf) {
    error_t error = i2c_error;

    switch (mState) {
    case STATE_SETCONFIG:
      atomic mState = STATE_IDLE;
      signal HplDS2745.setConfigDone(error);
      break;     
    case STATE_READTEMP:
      if (error) 
	signal HplDS2745.measureTemperatureDone(error,0);
      else
	error = call I2CPacket.read((I2C_START | I2C_STOP),devAddr,2,mI2CBuffer);
      break;
    case STATE_READVOLTAGE:
      if (error) 
	signal HplDS2745.measureVoltageDone(error,0);
      else
	error = call I2CPacket.read((I2C_START | I2C_STOP),devAddr,2,mI2CBuffer);
      break;
    case STATE_READCURRENT:
      if (error) 
	signal HplDS2745.measureCurrentDone(error,0);
      else 
	error = call I2CPacket.read((I2C_START | I2C_STOP),devAddr,2,mI2CBuffer);
      break;
    case STATE_READACCCURRENT:
      if (error) 
	signal HplDS2745.measureAccCurrentDone(error,0);
      else
	error = call I2CPacket.read((I2C_START | I2C_STOP),devAddr,2,mI2CBuffer);
      break;
    case STATE_SETBIAS:
      atomic mState = STATE_IDLE;
      signal HplDS2745.setOffsetBiasDone(error);
      break;
    case STATE_SETACCBIAS:
      atomic mState = STATE_IDLE;
      signal HplDS2745.setAccOffsetBiasDone(error);
      break;
    default:
      atomic mState = STATE_IDLE;
      break;
    }
    if (error)
      atomic mState = STATE_IDLE;
    return;
  }
  
  default event void SplitControl.startDone( error_t error ) { return; }
  default event void SplitControl.stopDone( error_t error ) { return; }
  default async event void HplDS2745.setConfigDone(error_t error) {return; }
  default async event void HplDS2745.measureTemperatureDone( error_t error, uint16_t val ){ return; }
  default async event void HplDS2745.measureVoltageDone( error_t error, uint16_t val ){ return; }
  default async event void HplDS2745.measureCurrentDone( error_t error, uint16_t val ){ return; }
  default async event void HplDS2745.measureAccCurrentDone( error_t error, uint16_t val ){ return; }
  default async event void HplDS2745.setOffsetBiasDone( error_t error ){ return; }
  default async event void HplDS2745.setAccOffsetBiasDone(error_t error){ return; }
}
