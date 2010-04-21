/*
 * Copyright (c) 2009 Communication Group and Eislab at
 * Lulea University of Technology
 *
 * Contact: Laurynas Riliskis, LTU
 * Mail: laurynas.riliskis@ltu.se
 * All rights reserved.
 *
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
 * - Neither the name of Communication Group at Lulea University of Technology
 *   nor the names of its contributors may be used to endorse or promote
 *    products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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
 * HplDS2782LogicP is the driver for the Dallas DS2782. It requires 
 * I2C packet and resource interfaces and provides the HplDS2782 HPL interface.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com> 
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 */

#include "DS2782.h"
#include "I2C.h"

generic module HplDS2782LogicP(uint16_t devAddr)
{
  provides interface StdControl;
  provides interface HplDS2782;

  uses interface I2CPacket<TI2CBasicAddr>;
  uses interface Resource as I2CResource;

}

implementation {

  enum {
    STATE_IDLE,
    STATE_STOPPED,
    STATE_SETCONFIG,
    STATE_READTEMP,
    STATE_READVOLTAGE,
    STATE_READCURRENT,
    STATE_READACCCURRENT,
    STATE_SETBIAS,
    STATE_SETACCBIAS,
    STATE_ALLOWSLEEP
  };

  uint8_t mI2CBuffer[4];
  uint8_t mState = STATE_STOPPED;
  bool read;

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
    read = true;
    error = call I2CResource.request();

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

    read = false;
    error = call I2CResource.request();

    if (error)
      atomic mState = STATE_IDLE;

    return error;
  }

  command error_t StdControl.start() {
    error_t error = SUCCESS;
    atomic {
      if (mState == STATE_STOPPED) { 
        mState = STATE_IDLE; 
      }
      else {
        error = EBUSY;
      }
    }
    return error;
  }

  command error_t StdControl.stop() {
    error_t error = SUCCESS;
    atomic {
      if (mState == STATE_IDLE) {
        mState = STATE_STOPPED;
      }
      else {
        error = EBUSY;
      }
    }
    return error;
  }

  command error_t HplDS2782.setConfig(uint8_t val) {
    return doSetReg(STATE_SETCONFIG,DS2782_PTR_SC,val);
  }

  command error_t HplDS2782.allowSleep(bool allow) {
    if (allow)
      return doSetReg(STATE_ALLOWSLEEP,DS2782_PTR_CONTROL,0x60);
    else 
      return doSetReg(STATE_ALLOWSLEEP,DS2782_PTR_CONTROL,0x0);
  }

  command error_t HplDS2782.measureTemperature() { 
    return doReadReg(STATE_READTEMP,DS2782_PTR_TEMPMSB);
  }

  command error_t HplDS2782.measureVoltage() { 
    return doReadReg(STATE_READVOLTAGE,DS2782_PTR_VOLTMSB);
  }

  command error_t HplDS2782.measureCurrent() { 
    return doReadReg(STATE_READCURRENT,DS2782_PTR_CURRMSB);
  }

  command error_t HplDS2782.measureAccCurrent() { 
    return doReadReg(STATE_READTEMP,DS2782_PTR_ACCURMSB);
  }

  command error_t HplDS2782.setOffsetBias(int8_t val) { 
    return doSetReg(STATE_SETBIAS,DS2782_PTR_OFFSETBIAS,val); 
  }

  command error_t HplDS2782.setAccOffsetBias(int8_t val) {
    return doSetReg(STATE_SETACCBIAS,DS2782_PTR_ACCBIAS,val); 
  }

  async event void I2CPacket.readDone(error_t i2c_error, uint16_t chipAddr, uint8_t len, uint8_t *buf) {
    uint16_t tempVal;
    tempVal = buf[0];
    tempVal = ((tempVal << 8) | buf[1]);

    atomic switch (mState) {
      case STATE_READTEMP:
        signal HplDS2782.measureTemperatureDone(i2c_error,tempVal);
        break;
      case STATE_READVOLTAGE:
        signal HplDS2782.measureVoltageDone(i2c_error,tempVal);
        break;
      case STATE_READCURRENT:
        signal HplDS2782.measureCurrentDone(i2c_error,tempVal);
        break;
      case STATE_READACCCURRENT:
        signal HplDS2782.measureAccCurrentDone(i2c_error,tempVal);
        break;
      default:
        break;
    }
    call I2CResource.release();
    atomic mState = STATE_IDLE;
    return;
  }

  event void I2CResource.granted() {
    if (read) {
      call I2CPacket.write(I2C_START | I2C_STOP,devAddr,1,mI2CBuffer);
    } else {
      call I2CPacket.write(I2C_START | I2C_STOP,devAddr,2,mI2CBuffer);
    }
  }

  async event void I2CPacket.writeDone(error_t i2c_error, uint16_t chipAddr, uint8_t len, uint8_t *buf) {
    error_t error = i2c_error;

    atomic switch (mState) {
      case STATE_SETCONFIG:
        call I2CResource.release();
        atomic mState = STATE_IDLE;
        signal HplDS2782.setConfigDone(error);
        break;     
      case STATE_READTEMP:
        if (error) 
          signal HplDS2782.measureTemperatureDone(error,0);
        else
          error = call I2CPacket.read((I2C_START | I2C_STOP),devAddr,2,mI2CBuffer);
        break;
      case STATE_READVOLTAGE:
        if (error) 
          signal HplDS2782.measureVoltageDone(error,0);
        else
          error = call I2CPacket.read((I2C_START | I2C_STOP),devAddr,2,mI2CBuffer);
        break;
      case STATE_READCURRENT:
        if (error) 
          signal HplDS2782.measureCurrentDone(error,0);
        else 
          error = call I2CPacket.read((I2C_START | I2C_STOP),devAddr,2,mI2CBuffer);
        break;
      case STATE_READACCCURRENT:
        if (error) 
          signal HplDS2782.measureAccCurrentDone(error,0);
        else
          error = call I2CPacket.read((I2C_START | I2C_STOP),devAddr,2,mI2CBuffer);
        break;
      case STATE_SETBIAS:
        call I2CResource.release();
        atomic mState = STATE_IDLE;
        signal HplDS2782.setOffsetBiasDone(error);
        break;
      case STATE_SETACCBIAS:
        call I2CResource.release();
        atomic mState = STATE_IDLE;
        signal HplDS2782.setAccOffsetBiasDone(error);
        break;
      case STATE_ALLOWSLEEP:
        call I2CResource.release();
        atomic mState = STATE_IDLE;
        signal HplDS2782.allowSleepDone(error);
        break;
      default:
        call I2CResource.release();
        atomic mState = STATE_IDLE;
        break;
    }
    if (error) {
      call I2CResource.release();
      atomic mState = STATE_IDLE;
    }
    return;
  }

  default async event void HplDS2782.setConfigDone(error_t error) { return; }
  default async event void HplDS2782.allowSleepDone( error_t error ) { return; }
  default async event void HplDS2782.measureTemperatureDone( error_t error, uint16_t val ){ return; }
  default async event void HplDS2782.measureVoltageDone( error_t error, uint16_t val ){ return; }
  default async event void HplDS2782.measureCurrentDone( error_t error, uint16_t val ){ return; }
  default async event void HplDS2782.measureAccCurrentDone( error_t error, uint16_t val ){ return; }
  default async event void HplDS2782.setOffsetBiasDone( error_t error ){ return; }
  default async event void HplDS2782.setAccOffsetBiasDone(error_t error){ return; }
}
