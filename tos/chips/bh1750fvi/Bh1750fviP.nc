/*
* Copyright (c) 2010, University of Szeged
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Author: Zsolt Szabo, Andras Biro
*/

module Bh1750fviP {
  provides interface Read<uint16_t> as Light;
  
  uses interface I2CPacket<TI2CBasicAddr>;
  uses interface Timer<TMilli>;
  uses interface Resource as I2CResource;
  uses interface BusPowerManager;
  provides interface Init;
}
implementation {
  enum {
    BH1750FVI_POWER_DOWN  = 0x00,
    BH1750FVI_POWER_ON  = 0x01,
    BH1750FVI_RESET         =       0x07,
    BH1750FVI_CONT_H_RES    =       0x10,
    BH1750FVI_CONT_H2_RES   =       0x11,
    BH1750FVI_CONT_L_RES    =       0x13,
    BH1750FVI_ONE_SHOT_H_RES        =       0x20,
    BH1750FVI_ONE_SHOT_H2_RES       =       0x21,
    BH1750FVI_ONE_SHOT_L_RES        =       0x23,
  } bh1750fviCommand;

  enum {
    BH1750FVI_TIMEOUT_H_RES =       180, // max 180
    BH1750FVI_TIMEOUT_H2_RES=       180, // max 180
    BH1750FVI_TIMEOUT_L_RES =        24, // max 24
    BH1750FVI_TIMEOUT_BOOT = 11,
  } bh1750fviTimeout;

  enum {
    BH1750FVI_ADDRESS =       0x23,//0x46/0x47,  //if addr== H then it would be 0xb8/0xb9   
  } bh1750fviHeader;
  
  uint8_t  i2cBuffer[2];
  norace error_t lastError;

  enum {
    S_OFF = 0,
    S_IDLE,
    S_BUSY_CMD,
    S_BUSY_MEAS,
  };
  
  uint8_t state = S_OFF;
  
  command error_t Init.init(){
    call BusPowerManager.configure(BH1750FVI_TIMEOUT_BOOT,BH1750FVI_TIMEOUT_BOOT);
    return SUCCESS;
  }

  command error_t Light.read() {
    uint8_t prevState=state;
    if(state == S_BUSY_MEAS || state == S_BUSY_CMD) return EBUSY;
    state = S_BUSY_CMD;
    call BusPowerManager.requestPower();
    if(prevState == S_IDLE)
      call I2CResource.request();
    return SUCCESS;
  }
  
  event void BusPowerManager.powerOn(){
    if(state == S_BUSY_CMD)
      call I2CResource.request();
    else
      state = S_IDLE;
  }
  
  task void signalReadDone() {
    state= S_IDLE;
    call BusPowerManager.releasePower();
    signal Light.readDone(lastError, ((i2cBuffer[0]<<8) | i2cBuffer[1]) );
  }
  
  event void I2CResource.granted() {
    if(state == S_BUSY_CMD){
      i2cBuffer[0]=BH1750FVI_ONE_SHOT_H_RES;
      lastError = call I2CPacket.write(I2C_START | I2C_STOP, BH1750FVI_ADDRESS, 1, i2cBuffer);
    } else {
      lastError=call I2CPacket.read(I2C_START | I2C_STOP, BH1750FVI_ADDRESS, 2, i2cBuffer);
    }
    if(lastError!=SUCCESS){
      call I2CResource.release();
      post signalReadDone();
    }
  }
  
  task void startTimeout() {
    state=S_BUSY_MEAS;
    call Timer.startOneShot(BH1750FVI_TIMEOUT_H_RES);
  }

  async event void I2CPacket.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data) {
    call I2CResource.release();
    if(error != SUCCESS) {
      lastError = error;
      post signalReadDone();
    }
    else {
      post startTimeout();
    }
  }
  
  event void Timer.fired() {
    call I2CResource.request();
  }
  
  async event void I2CPacket.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data) {
    lastError = error;
    call I2CResource.release();
    post signalReadDone();
  }

  event void BusPowerManager.powerOff(){
    state=S_OFF;
  }

  default event void Light.readDone(error_t error, uint16_t val) { }
}
