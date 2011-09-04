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
* Author: Zsolt Szabo
*/

#include "Sht21.h"

module Sht21DriverP {
  provides interface Read<uint16_t> as Temperature;
  provides interface Read<uint16_t> as Humidity;
  
  provides interface SplitControl;
  uses interface I2CPacket<TI2CBasicAddr>;
  uses interface Timer<TMilli>;
  uses interface Resource as I2CResource;
}
implementation {
  uint8_t res[2];
  norace error_t lastError;
  enum {
    S_OFF = 0,
    S_STARTING,
    S_IDLE,
    S_READ_TEMP,
    S_READ_HUMIDITY,
  };
  
  uint8_t state = S_OFF;
  
  bool stopRequested = FALSE;
  bool otherSensorRequested=FALSE;    
  
  command error_t SplitControl.start() {
    if(state == S_STARTING) return EBUSY;
    if(state != S_OFF) return EALREADY;
    
    state=S_STARTING;
    call Timer.startOneShot(TIMEOUT_RESET);
    return SUCCESS;
  }

  task void signalStopDone(){
    signal SplitControl.stopDone(SUCCESS);
  }
  
  command error_t SplitControl.stop() {
    if(stopRequested) return EBUSY;    
    if(state == S_OFF) return EALREADY;
    if(state == S_IDLE) {
      state = S_OFF;
      post signalStopDone();
    } else {
      stopRequested = TRUE;
    }
    return SUCCESS;
  }
  
  inline void sendCommand(){
    if(state == S_READ_TEMP) {
      res[0]=TRIGGER_T_MEASUREMENT_NO_HOLD_MASTER;
    } else if (state == S_READ_HUMIDITY) {
      res[0]=TRIGGER_RH_MEASUREMENT_NO_HOLD_MASTER;
    } else
			return;
    call I2CPacket.write(I2C_START, I2C_ADDRESS, 1, res);
  }

  command error_t Temperature.read() { 
    if(state==S_OFF||stopRequested) return EOFF;
    if(state==S_READ_HUMIDITY&&!otherSensorRequested){
      otherSensorRequested=TRUE;
      return SUCCESS;    
    } else if(state!=S_IDLE)
      return EBUSY;

    state = S_READ_TEMP;    
    call I2CResource.request();
    return SUCCESS;
  }

  command error_t Humidity.read() {
    if(state==S_OFF||stopRequested) return EOFF;
    if(state==S_READ_TEMP&&!otherSensorRequested){
      otherSensorRequested=TRUE;
      return SUCCESS;
    } else if(state!=S_IDLE)
      return EBUSY;

    state = S_READ_HUMIDITY;    
    call I2CResource.request();
    return SUCCESS;
  }

  event void Timer.fired() {
    if(state==S_STARTING){
      state = S_IDLE;
      signal SplitControl.startDone(SUCCESS);
    } else {
        call I2CPacket.read(I2C_START | I2C_STOP, I2C_ADDRESS, 2, res);
    }
  }

  task void signalReadDone()
  {
    uint16_t result=(res[0]<<8)+(res[1]&0xfc);
    uint8_t signalState=state;
    //restore state, *Requested variables, release bus
    if(otherSensorRequested){
      if(state==S_READ_HUMIDITY)
        state = S_READ_TEMP;
      else
        state = S_READ_HUMIDITY;
      
      otherSensorRequested=FALSE;
    } else {
      call I2CResource.release();
      if(!stopRequested)
        state=S_IDLE;
      else{
        stopRequested=FALSE;
        state=S_OFF;
      }
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
      sendCommand();
    } else if(state==S_OFF){
      post signalStopDone();
    }
    
  }

  async event void I2CPacket.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data) {
    lastError=error;
    post signalReadDone();
  }
  
  task void startTimeout()
  {
    if(state == S_READ_TEMP) call Timer.startOneShot(TIMEOUT_14BIT);
    if(state == S_READ_HUMIDITY) call Timer.startOneShot(TIMEOUT_12BIT);
  }
  

  async event void I2CPacket.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data) {
    if(error==SUCCESS)
      post startTimeout(); 
    else{
      lastError=error;
      post signalReadDone();
    }
  }

  event void I2CResource.granted() {
    sendCommand();
  }
  
  

  default event void Temperature.readDone(error_t error, uint16_t val) {}
  default event void Humidity.readDone(error_t error, uint16_t val) {}
  default event void SplitControl.startDone(error_t error) { }
  default event void SplitControl.stopDone(error_t error) { }
}
