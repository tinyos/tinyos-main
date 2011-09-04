#include "Ms5607.h"

/*
* Copyright (c) 2011, University of Szeged
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

generic module RomReaderP(bool morePrecise) {
  provides interface Read<uint32_t> as RawTemperature;
  provides interface Read<uint32_t> as RawPressure;
  provides interface Calibration as Cal;
  uses interface Timer<TMilli>;
  uses interface I2CPacket<TI2CBasicAddr>;
  uses interface Resource as I2CResource;
}
implementation {
  enum {
    S_OFF = 0,
    S_STARTING,
    S_STOPPING,
    S_ON,
    S_READ_TEMP,
    S_READ_PRESS,
  };
  bool norace accessingROM = FALSE;
  bool norace readingADC = FALSE;
  uint8_t norace num;
  error_t norace lastError;
  uint8_t reg[2];
  uint16_t mesres[7] ;
  uint8_t rawres[3];
  uint32_t norace rawret;
  uint8_t state = S_ON;
  uint8_t cmd;

  task void failTask() {
    switch(cmd) {
      case CONVERT_TEMPERATURE_FAST:
      case CONVERT_TEMPERATURE_SLOW:
        signal RawTemperature.readDone(FAIL, 0);
        break;
      case CONVERT_PRESSURE_FAST:
      case CONVERT_PRESSURE_SLOW:
        signal RawPressure.readDone(FAIL, 0);
        break;
      case ADC_READ:
      if(state == S_READ_TEMP) {
        signal RawTemperature.readDone(FAIL, 0);
      }
      else {
        signal RawPressure.readDone(FAIL, 0);
      }
      default:
        signal Cal.dataReady(FAIL, 0);
    }
  }

  command error_t RawTemperature.read() {
    state = S_READ_TEMP;
    call I2CResource.request();
    return SUCCESS;
  }

  command error_t RawPressure.read() {
    state = S_READ_PRESS;
    call I2CResource.request();
    return SUCCESS;
  }

  event void Timer.fired() {
    if((state == S_READ_TEMP) || (state == S_READ_PRESS)) {
      if(readingADC) {
        call I2CPacket.read(I2C_START | I2C_STOP, ADDRESS, 3, rawres);
      } else {
        readingADC=TRUE;
        cmd = ADC_READ;
        if(call I2CPacket.write(I2C_START , ADDRESS, 1, &cmd) != SUCCESS) {
          call I2CResource.release();
          post failTask();
        }
      }
    }
  }

  task void signalReadDone() {
    if(accessingROM) {
      if(num == 6) { 
        accessingROM = FALSE;
        call I2CResource.release();
        signal Cal.dataReady(lastError, mesres);
        return;
      }
      num++; call I2CResource.release(); call I2CResource.request();
    } else if(readingADC) {
      readingADC = FALSE;
      
      call I2CResource.release();

      switch(state) {
        case S_READ_TEMP:
          state = S_ON;
          signal RawTemperature.readDone(lastError, rawret);
          break;
        case S_READ_PRESS:
          state = S_ON;
          signal RawPressure.readDone(lastError, rawret);
          break;
      }
    }
  }

  async event void I2CPacket.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data) {
    uint32_t tmp;
    lastError = error;
    if(accessingROM) {
      mesres[num] = data[0] << 8;
      mesres[num] = mesres[num] | data[1];
    } else if(readingADC) {
      tmp = data[0];
      tmp <<= 16;
      rawret = tmp;
      tmp = data[1];
      tmp <<= 8;
      rawret |= tmp;
      rawret|= data[2];
    }
    
    post signalReadDone();
  }

  task void readTask() {
    if(accessingROM) {
      if(call I2CPacket.read(I2C_START | I2C_STOP, ADDRESS, 2, reg) != SUCCESS) {
        call I2CResource.release();
        post failTask();
      }
    }
    if(readingADC) {
      call Timer.startOneShot(2);
    } else
    if(state == S_READ_TEMP) {
      call Timer.startOneShot((morePrecise)?SLOW_WAIT:FAST_WAIT);
    }
    if(state == S_READ_PRESS) {
      call Timer.startOneShot((morePrecise)?SLOW_WAIT:FAST_WAIT);
    }
  }

  async event void I2CPacket.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data) {
    lastError = error;
    if(lastError != SUCCESS) {
      call I2CResource.release();
      post failTask();
    }
    else {
      post readTask();
    }
  }

  event void I2CResource.granted() {
    if((num <=6) && accessingROM) {
      cmd = PROM_READ_MASK | (num << 1);
      if(call I2CPacket.write(I2C_START | I2C_STOP, ADDRESS, 1, &cmd) != SUCCESS) {
        call I2CResource.release();
        post failTask();
      }
    } else if(state == S_READ_TEMP) {
      cmd = (morePrecise)?CONVERT_TEMPERATURE_SLOW:CONVERT_TEMPERATURE_FAST;
      if(call I2CPacket.write(I2C_START | I2C_STOP, ADDRESS, 1, &cmd) != SUCCESS) {
        call I2CResource.release();
        post failTask();
      }
    } else if(state == S_READ_PRESS) {
      cmd = (morePrecise)?CONVERT_PRESSURE_SLOW:CONVERT_PRESSURE_FAST;
      if(call I2CPacket.write(I2C_START | I2C_STOP, ADDRESS, 1, &cmd) != SUCCESS) {
        call I2CResource.release();
        post failTask();
      }
    }    
  }

  command error_t Cal.getData() {
    if(!accessingROM) {
    accessingROM = TRUE;
    num=0;
    call I2CResource.request();
    } else return FAIL;
    return lastError;
  }
 
  default event void RawTemperature.readDone(error_t error, uint32_t val) { }
  default event void RawPressure.readDone(error_t error, uint32_t val) { } 
}
