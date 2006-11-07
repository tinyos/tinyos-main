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
 * HplTMP175LogicP is the driver for the TI TMP175. It requires an 
 * I2C packet interface and provides the HplTMP175 HPL interface.
 * This module DOES NOT apply any specific configuration to the GpioInterrupt 
 * pin associated with the theshold alerts. This must be handled by an
 * outside configuration/module according to the host platform.
 * 
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * @version $Revision: 1.3 $ $Date: 2006-11-07 19:31:16 $
 */

#include "TMP175.h"
#include "I2C.h"

generic module HplTMP175LogicP(uint16_t devAddr)
{
  provides interface Init;
  provides interface SplitControl;
  provides interface HplTMP175;

  uses interface I2CPacket<TI2CBasicAddr>;
  uses interface GpioInterrupt as AlertInterrupt;
  uses interface GeneralIO as InterruptPin;
}

implementation {

  enum {
    STATE_IDLE,
    STATE_STARTING,
    STATE_STOPPING,
    STATE_STOPPED,
    STATE_READTEMP,
    STATE_SETCONFIG,
    STATE_SETTHIGH,
    STATE_SETTLOW,
  };

  bool mfPtrReset;
  uint8_t mI2CBuffer[4];
  uint8_t mState;
  uint8_t mConfigRegVal;
  norace error_t mSSError;

  static error_t doSetReg(uint8_t nextState, uint8_t reg, uint8_t val) {
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

  static error_t doSetRegWord(uint8_t nextState, uint8_t reg, uint16_t val) {
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
    mI2CBuffer[1] = (val >> 8) & 0xFF;
    mI2CBuffer[2] = val & 0xFF;

    error = call I2CPacket.write((I2C_START | I2C_STOP),devAddr,3,mI2CBuffer);
    
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
    // careful! this can be changed via polarity I believe
    call InterruptPin.makeInput();
    call AlertInterrupt.enableRisingEdge();
    mfPtrReset = FALSE;
    mConfigRegVal = 0;
    mState = STATE_STOPPED;
    return SUCCESS;
  }

  command error_t SplitControl.start() {
    error_t error = SUCCESS;
    atomic {
      if (mState == STATE_STOPPED) { 
	mState = STATE_IDLE; 
      }
      else {
	error = EBUSY;
      }
    }
    
    if (error)
      return error;
    
    return doSetReg(STATE_STARTING,TMP175_PTR_CFG,(mConfigRegVal & ~TMP175_CFG_SD));
  }

  command error_t SplitControl.stop() {
    return doSetReg(STATE_STOPPING,TMP175_PTR_CFG,(mConfigRegVal | TMP175_CFG_SD));
  }
  
  command error_t HplTMP175.measureTemperature() { 
    error_t error = SUCCESS;

    atomic {
      if (mState == STATE_IDLE) {
	mState = STATE_READTEMP;
      }
      else {
	error = EBUSY;
      }
    }
    if (error)
      return error;

    mI2CBuffer[0] = mI2CBuffer[1] = 0;

    error = call I2CPacket.read(I2C_START | I2C_STOP, devAddr,2,mI2CBuffer);

    if (error)
      atomic mState = STATE_IDLE;

    return error;

  }

  command error_t HplTMP175.setConfigReg( uint8_t val ){
    return doSetReg(STATE_SETCONFIG,TMP175_PTR_CFG,val);
  }
  
  command error_t HplTMP175.setTLowReg(uint16_t val){ 
    return doSetRegWord(STATE_SETTLOW,TMP175_PTR_TLOW,val);  
  }

  command error_t HplTMP175.setTHighReg(uint16_t val){
    return doSetRegWord(STATE_SETTHIGH,TMP175_PTR_THIGH,val); 
  }

  async event void I2CPacket.readDone(error_t i2c_error, uint16_t chipAddr, uint8_t len, uint8_t *buf) {
    uint16_t tempVal;

    switch (mState) {
    case STATE_READTEMP:
      tempVal = buf[0];
      tempVal = ((tempVal << 8) | buf[1]);
      mState = STATE_IDLE;
      signal HplTMP175.measureTemperatureDone(i2c_error,tempVal);
      break;
    default:
      break;
    }

    return;
  }

  async event void I2CPacket.writeDone(error_t i2c_error, uint16_t chipAddr, uint8_t len, uint8_t *buf) {
    error_t error = i2c_error;

    if (mfPtrReset) {
      mfPtrReset = FALSE;
      switch (mState) {
      case STATE_STARTING:
	mSSError = error;
	post StartDone();
	break;
      case STATE_STOPPING:
	mSSError = error;
	post StopDone();
	break;
      case STATE_READTEMP:
	// Should never get here.
	break;
      case STATE_SETCONFIG:
	mState = STATE_IDLE;
	signal HplTMP175.setConfigRegDone(error);
	break;
      case STATE_SETTHIGH:
	mState = STATE_IDLE;
	signal HplTMP175.setTHighRegDone(error);
	break;
      case STATE_SETTLOW:
	mState = STATE_IDLE;
	signal HplTMP175.setTLowRegDone(error);
	break;
      default:
	mState = STATE_IDLE;
	break;
      }
    }
    else {
      // Reset the PTR register back to the temperature register
      mI2CBuffer[0] = TMP175_PTR_TEMP;
      mfPtrReset = TRUE;
      call I2CPacket.write(I2C_START | I2C_STOP, devAddr,1,mI2CBuffer);
    } 

    return;
  }

  async event void AlertInterrupt.fired() {
    // This alert is decoupled from whatever state the TMP175 is in. 
    // Upper layers must handle dealing with this alert appropriately.
    signal HplTMP175.alertThreshold();
    return;
  }

  default event void SplitControl.startDone( error_t error ) { return; }
  default event void SplitControl.stopDone( error_t error ) { return; }
  default async event void HplTMP175.measureTemperatureDone( error_t error, uint16_t val ){ return; }
  default async event void HplTMP175.setConfigRegDone( error_t error ){ return; }
  default async event void HplTMP175.setTHighRegDone(error_t error){ return; }
  default async event void HplTMP175.setTLowRegDone(error_t error){ return; }
  default async event void HplTMP175.alertThreshold(){ return; }

}
