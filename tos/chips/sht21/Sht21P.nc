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

#include "Sht21.h"
module Sht21P {
  provides interface Read<uint16_t> as Temperature;
  provides interface Read<uint16_t> as Humidity;
  
  uses interface I2CPacket<TI2CBasicAddr>;
  uses interface Timer<TMilli>;
  uses interface Resource as I2CResource;
  uses interface BusPowerManager;
  provides interface Init;
}
implementation {
  enum {
    SHT21_TRIGGER_T_MEASUREMENT_HOLD_MASTER = 0xE3,
    SHT21_TRIGGER_RH_MEASUREMENT_HOLD_MASTER  = 0xE5,
    SHT21_TRIGGER_T_MEASUREMENT_NO_HOLD_MASTER  = 0xF3,
    SHT21_TRIGGER_RH_MEASUREMENT_NO_HOLD_MASTER = 0xF5,
    SHT21_WRITE_USER_REGISTER     = 0xE6,
    SHT21_READ_USER_REGISTER      =       0xE7,
    SHT21_SOFT_RESET                            =       0xFE,
  } Sht21Command;

  enum {
    SHT21_HEATER_ON     =       0x04,
    SHT21_HEATER_OFF    =       0x00,
  } Sht21Heater;

  enum {
    SHT21_I2C_ADDRESS =  64,
  } Sht21Header;

  enum {
    SHT21_TIMEOUT_14BIT =       85,
    SHT21_TIMEOUT_13BIT =       43,
    SHT21_TIMEOUT_12BIT =       22,
    SHT21_TIMEOUT_11BIT =       11,
    SHT21_TIMEOUT_10BIT =       6,
    SHT21_TIMEOUT_8BIT  =       3,
    SHT21_TIMEOUT_RESET =       15,
  } Sht21Timeout;
  
  uint8_t i2cBuffer[2];
  norace error_t lastError;
  enum {
    S_OFF = 0,
    S_IDLE,
    S_READ_TEMP_CMD,
    S_READ_TEMP,
    S_READ_HUMIDITY_CMD,
    S_READ_HUMIDITY,
  };
  
  uint8_t state = S_OFF;
  
  bool otherSensorRequested=FALSE;    
  
  command error_t Init.init(){
    call BusPowerManager.configure(SHT21_TIMEOUT_RESET,SHT21_TIMEOUT_RESET);
    return SUCCESS;
  }
  
  command error_t Temperature.read() { 
    uint8_t prevState=state;
    if(!otherSensorRequested && (state==S_READ_HUMIDITY || state==S_READ_HUMIDITY_CMD)){
      otherSensorRequested=TRUE;
      return SUCCESS;    
    } else if(state==S_READ_TEMP || state==S_READ_TEMP_CMD)
      return EBUSY;
    
    state=S_READ_TEMP_CMD;
    call BusPowerManager.requestPower();
    if(prevState==S_IDLE)
      call I2CResource.request();
    return SUCCESS;
  }

  command error_t Humidity.read() {
    uint8_t prevState=state;
    if(!otherSensorRequested && (state==S_READ_TEMP || state==S_READ_TEMP_CMD)){
      otherSensorRequested=TRUE;
      return SUCCESS;    
    } else if(state==S_READ_HUMIDITY || state==S_READ_HUMIDITY_CMD)
      return EBUSY;
    
    state = S_READ_HUMIDITY_CMD;
    call BusPowerManager.requestPower();
    if(prevState==S_IDLE)
      call I2CResource.request();      
    return SUCCESS;
  }
  
  event void BusPowerManager.powerOn(){
    if(state==S_OFF)
      state=S_IDLE;
    else
      call I2CResource.request();
  }
  
  event void BusPowerManager.powerOff(){
    state=S_OFF;
  }
  
  inline error_t sendCommand(){
    switch(state){
      case S_READ_TEMP:
      case S_READ_HUMIDITY:
        return call I2CPacket.read(I2C_START | I2C_STOP, SHT21_I2C_ADDRESS, 2, i2cBuffer);
        break;
      case S_READ_TEMP_CMD:
        i2cBuffer[0]=SHT21_TRIGGER_T_MEASUREMENT_NO_HOLD_MASTER;
        break;
      case S_READ_HUMIDITY_CMD:
        i2cBuffer[0]=SHT21_TRIGGER_RH_MEASUREMENT_NO_HOLD_MASTER;
        break;
    }
    return call I2CPacket.write(I2C_START, SHT21_I2C_ADDRESS, 1, i2cBuffer);
  }
  
  task void signalReadDone()
  {
    uint16_t result=(i2cBuffer[0]<<8)+(i2cBuffer[1]&0xfc);
    uint8_t signalState=state;
    //restore state, *Requested variables, release bus
    if(otherSensorRequested){
      if(state==S_READ_HUMIDITY)
        state = S_READ_TEMP;
      else
        state = S_READ_HUMIDITY;
      
      otherSensorRequested=FALSE;
    } else {
      state=S_IDLE;
      call I2CResource.release();
      call BusPowerManager.releasePower();
    }
    //signaling
    if(signalState == S_READ_TEMP) {
      signal Temperature.readDone(lastError, result);
    }
    if(signalState == S_READ_HUMIDITY){
      signal Humidity.readDone(lastError, result);
    }
    //run *Requested operations
    if(state==S_READ_HUMIDITY||state==S_READ_TEMP){
      lastError = sendCommand();
      if(lastError != SUCCESS)
        post signalReadDone();
    }    
  }
  
  event void I2CResource.granted() {
    lastError = sendCommand();
    if(lastError != SUCCESS){
      post signalReadDone();
    }
  }
  
  task void startTimer(){
    switch(state){
      case S_READ_TEMP_CMD:
        state=S_READ_TEMP;
        call Timer.startOneShot(SHT21_TIMEOUT_14BIT);
      break;
      case S_READ_HUMIDITY_CMD:
        state=S_READ_HUMIDITY;
        call Timer.startOneShot(SHT21_TIMEOUT_12BIT);
      break;
    }
  }
  
  async event void I2CPacket.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data) {
    call I2CResource.release();
    if(error==SUCCESS){
      post startTimer();
    } else {
      lastError=error;
      post signalReadDone();
    }
  }

  event void Timer.fired() {
    call I2CResource.request();
  }

  async event void I2CPacket.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data) {
    lastError=error;
    post signalReadDone();
  }

  default event void Temperature.readDone(error_t error, uint16_t val) {}
  default event void Humidity.readDone(error_t error, uint16_t val) {}
}
