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


#include "Bh1750fvi.h" 

module Bh1750fviP {
  provides interface Read<uint16_t> as Light;
  provides interface SplitControl;
  
  uses interface I2CPacket<TI2CBasicAddr>;
  uses interface Timer<TMilli>;
  uses interface Resource as I2CResource;

  uses interface DiagMsg;
}
implementation {
  uint16_t mesrslt=0;
  uint8_t  res[2];
  uint8_t cmd;
  error_t lastError;

  enum {
    S_OFF = 0,
    S_STARTING,
    S_STOPPING,
    S_IDLE,
    S_BUSY,
    S_RESET,
  };
  
  norace uint8_t state = S_OFF;
  bool on=0;
  bool stopRequested = FALSE;

  task void failTask() {
    signal Light.readDone(FAIL, 0);
  }

  command error_t SplitControl.start() {
    if(state == S_STARTING) return EBUSY;
    if(state != S_OFF) return EALREADY;
      
    call Timer.startOneShot(11);
    
    return SUCCESS;
  }

  task void signalStopDone() {
    signal SplitControl.stopDone(SUCCESS);
  }
  
  command error_t SplitControl.stop() {
    if(state == S_STOPPING) return EBUSY;
    if(state == S_OFF) return EALREADY;
    if(state == S_IDLE) {
      atomic state = S_OFF;
      post signalStopDone();
    } else {
      stopRequested = TRUE;
    }
    return SUCCESS;
  }  

  command error_t Light.read() {
    if(state == S_OFF) return EOFF;
    if(state != S_IDLE) return EBUSY;

    atomic state = S_RESET;   
    call I2CResource.request();
    return SUCCESS;
  }

  event void Timer.fired() {
    if(state == S_OFF) {
      atomic state = S_IDLE;
      signal SplitControl.startDone(SUCCESS);
    } else if(state == S_BUSY) {
        if(call I2CPacket.read(I2C_START | I2C_STOP, READ_ADDRESS, 2, res) != SUCCESS)
        {
          call I2CResource.release();
          post failTask();
        }

        if(stopRequested) {
          atomic state = S_IDLE;
          call SplitControl.stop();
        }
    }
    else if(state == S_IDLE) {
         call I2CResource.release();
    }
  }
 
  task void signalReadDone() {
    atomic {state= S_IDLE;
    signal Light.readDone(lastError, mesrslt);}
  }

  async event void I2CPacket.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data) {
    lastError = error;
    mesrslt = data[0]<<8;
    mesrslt |= data[1];
    call I2CResource.release();
   
    post signalReadDone();
  }
  
  task void startTimeout() {
    if(state == S_IDLE) call Timer.startOneShot(TIMEOUT_H_RES);
    else if(state == S_BUSY) call Timer.startOneShot(TIMEOUT_H_RES);
  }

  async event void I2CPacket.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data) {
    if(error != SUCCESS) {
      call I2CResource.release();
      post failTask();
    }
    else {
      if (state == S_RESET) {
        state = S_BUSY;
        call I2CResource.release();
        return (void)call I2CResource.request();
      }
      post startTimeout();
    }
  }

  event void I2CResource.granted() {
    if(state == S_STARTING || state == S_RESET) {
      cmd=POWER_ON;
      if(call I2CPacket.write(I2C_START | I2C_STOP, WRITE_ADDRESS, 1, &cmd) != SUCCESS) {
        call I2CResource.release();
        post failTask();
      }
    } else if(state == S_BUSY) {
      cmd=ONE_SHOT_H_RES;
      if(call I2CPacket.write(I2C_START | I2C_STOP, WRITE_ADDRESS, 1, &cmd) != SUCCESS) {
        call I2CResource.release();
        post failTask();
      }
    }
  }

  default event void Light.readDone(error_t error, uint16_t val) { }
  default event void SplitControl.startDone(error_t error) { }
  default event void SplitControl.stopDone(error_t error) { }
}
