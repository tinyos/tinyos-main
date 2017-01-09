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
* Author: Zsolt Szabo, Andras Biro
*/

#include "Ms5607.h"

//TODO: norace or atomic (state, i2cBuffer)
//TODO: testing: SetPrecision
module Ms5607P {
  provides interface Read<uint32_t> as ReadTemperature;
  provides interface Read<uint32_t> as ReadPressure;
  provides interface ReadRef<calibration_t> as ReadCalibration;
  provides interface Set<uint8_t> as SetPrecision;
  provides interface Init;
  uses interface Timer<TMilli>;
  uses interface I2CPacket<TI2CBasicAddr>;
  uses interface Resource as I2CResource;
  uses interface BusPowerManager;
}
implementation {
  enum {
    MS5607_ADDRESS = 0x77,
  };

  enum {
    MS5607_ADC_READ = 0x00,
    MS5607_CONVERT_TEMPERATURE = 0x58, //-0..8, depending on precision (OSR)
    MS5607_CONVERT_PRESSURE = 0x48, //-0..8, depending on precision (OSR)
    MS5607_PROM_READ = 0xA0, // +(address << 1)
  } ms5607_command;
  
  enum  {
    MS5607_TIMEOUT_4096=10,
    MS5607_TIMEOUT_2048=5,
    MS5607_TIMEOUT_1024=3,
    MS5607_TIMEOUT_512=2,
    MS5607_TIMEOUT_256=1,
    MS5607_TIMEOUT_RESET=3,
  } ms5607_timeout; //in ms
  
  enum {
    S_OFF = 0,
    S_IDLE = 1,
    S_READ_TEMP_CMD = 2,
    S_READ_TEMP,
    S_READ_PRESSURE_CMD,
    S_READ_PRESSURE,
    S_READ_CALIB_CMD1,
    S_READ_CALIB_CMD2,
    S_READ_CALIB_CMD3,
    S_READ_CALIB_CMD4,
    S_READ_CALIB_CMD5,
    S_READ_CALIB_CMD6,
    S_READ_CALIB,
  };
  
  norace uint8_t state=S_OFF;
  norace uint8_t i2cBuffer[3];
  norace calibration_t *calib;
  norace error_t lastError;
  
  uint8_t precision=MS5607_PRECISION;
  
  command error_t Init.init(){
    call BusPowerManager.configure(MS5607_TIMEOUT_RESET, MS5607_TIMEOUT_RESET);
    return SUCCESS;
  }
  
  command void SetPrecision.set(uint8_t newPrecision){
    if(state<=S_IDLE)
      precision=newPrecision;
  }
  
  task void signalReadDone(){
    switch(state){
      case S_READ_CALIB_CMD1:
      case S_READ_CALIB_CMD2:
      case S_READ_CALIB_CMD3:
      case S_READ_CALIB_CMD4:
      case S_READ_CALIB_CMD5:
      case S_READ_CALIB_CMD6:
      case S_READ_CALIB:{
        state=S_IDLE;
        call BusPowerManager.releasePower();
        signal ReadCalibration.readDone(lastError, calib);
      }break;
      case S_READ_PRESSURE_CMD:
      case S_READ_PRESSURE:{
        uint32_t measurment=((uint32_t)i2cBuffer[0] << 16) | ((uint32_t)i2cBuffer[1] << 8) | i2cBuffer[2];
        state=S_IDLE;
        call BusPowerManager.releasePower();
        signal ReadPressure.readDone(lastError, measurment);
      }break;
      case S_READ_TEMP_CMD:
      case S_READ_TEMP:{
        uint32_t measurment=((uint32_t)i2cBuffer[0] << 16) | ((uint32_t)i2cBuffer[1] << 8) | i2cBuffer[2];
        state=S_IDLE;
        call BusPowerManager.releasePower();
        signal ReadTemperature.readDone(lastError, measurment);
      }break;
    }
  }
  
  command error_t ReadTemperature.read(){
    uint8_t prevState=state;
    if(state > S_IDLE)
      return EBUSY;
    
    state=S_READ_TEMP_CMD;
    call BusPowerManager.requestPower();
    if(prevState==S_IDLE)
      call I2CResource.request();
    return SUCCESS;
  }
  
  command error_t ReadPressure.read(){
    uint8_t prevState=state;
    if(state > S_IDLE)
      return EBUSY;
    
    state=S_READ_PRESSURE_CMD;
    call BusPowerManager.requestPower();
    if(prevState==S_IDLE)
      call I2CResource.request();
    return SUCCESS;
  }
  
  command error_t ReadCalibration.read(calibration_t *cal){
    uint8_t prevState=state;
    if(state > S_IDLE)
      return EBUSY;
    
    state=S_READ_CALIB_CMD1;
    calib=cal;
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
  
  event void I2CResource.granted(){
    uint8_t i2cCond=0;
    switch(state){
      case S_READ_PRESSURE_CMD:{
        i2cCond=I2C_START|I2C_STOP;
        i2cBuffer[0]=MS5607_CONVERT_PRESSURE - (precision & MS5607_PRESSURE_MASK);
      }break;
      case S_READ_TEMP_CMD:{
        i2cCond=I2C_START|I2C_STOP;
        i2cBuffer[0]=MS5607_CONVERT_TEMPERATURE - (precision >> 4);
      }break;
      case S_READ_PRESSURE:
      case S_READ_TEMP:{
        i2cCond=I2C_START;
        i2cBuffer[0]=MS5607_ADC_READ;
      }break;
      case S_READ_CALIB_CMD1:{
        i2cCond=I2C_START;
        i2cBuffer[0]=MS5607_PROM_READ+(1<<1);
      }break;
    }
    lastError = call I2CPacket.write(i2cCond, MS5607_ADDRESS, 1, i2cBuffer) ;
    if( lastError != SUCCESS) {
      call I2CResource.release();
      post signalReadDone();
    }
  }
  
  task void startTimer(){
    //the timeouts are the same for both sensor, so we convert temperature precision to pressure precision
    uint8_t prec=precision;
    if(state==S_READ_TEMP_CMD){
      state=S_READ_TEMP;
      prec=prec>>4;
    }else{
      state=S_READ_PRESSURE;
      prec=prec&MS5607_PRESSURE_MASK;
    }
    switch(prec){
      case MS5607_PRESSURE_4096: 
        call Timer.startOneShot(MS5607_TIMEOUT_4096);
        break;
      case MS5607_PRESSURE_2048:
        call Timer.startOneShot(MS5607_TIMEOUT_2048);
        break;
      case MS5607_PRESSURE_1024:
        call Timer.startOneShot(MS5607_TIMEOUT_1024);
        break;
      case MS5607_PRESSURE_512:
        call Timer.startOneShot(MS5607_TIMEOUT_512);
        break;
      case MS5607_PRESSURE_256:
        call Timer.startOneShot(MS5607_TIMEOUT_256);
        break;
    }
  }
  
  event void Timer.fired(){
    call I2CResource.request();
  }
  
  async event void I2CPacket.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data) {
    uint8_t readLength=0;
    if(error!=SUCCESS){
      lastError=error;
      call I2CResource.release();
      post signalReadDone();
      return;
    }
    switch(state){
      //timer starter states
      case S_READ_PRESSURE_CMD:
      case S_READ_TEMP_CMD:{
        call I2CResource.release();
        post startTimer();
        return;
      }break;
      //read states
      case S_READ_PRESSURE:
      case S_READ_TEMP:{
        readLength=3;
      }break;
      case S_READ_CALIB_CMD1:
      case S_READ_CALIB_CMD2:
      case S_READ_CALIB_CMD3:
      case S_READ_CALIB_CMD4:
      case S_READ_CALIB_CMD5:
      case S_READ_CALIB_CMD6:{
        readLength=2;
      }break;
    }
    lastError = call I2CPacket.read(I2C_START|I2C_STOP, MS5607_ADDRESS, readLength, i2cBuffer);
    if( lastError != SUCCESS) {
      call I2CResource.release();
      lastError=FAIL;
      post signalReadDone();
    }
  }
  
  async event void I2CPacket.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data) {
    lastError=error;
    if(error!=SUCCESS){
      call I2CResource.release();
      post signalReadDone();
      return;
    }
    switch(state){
      case S_READ_PRESSURE:
      case S_READ_TEMP:{
        call I2CResource.release();
        post signalReadDone();
        return;
      }break;
      case S_READ_CALIB_CMD6:{
        call I2CResource.release();
        calib->coefficient[5]=*((nx_uint16_t*)data);//data from the sensor is big endian
        post signalReadDone();
        return;
      }break;
      
      case S_READ_CALIB_CMD1:{
        calib->coefficient[0]=*((nx_uint16_t*)data);//data from the sensor is big endian
        state=S_READ_CALIB_CMD2;
        i2cBuffer[0]=MS5607_PROM_READ+(2<<1);
      }break;
      case S_READ_CALIB_CMD2:{
        calib->coefficient[1]=*((nx_uint16_t*)data);//data from the sensor is big endian
        state=S_READ_CALIB_CMD3;
        i2cBuffer[0]=MS5607_PROM_READ+(3<<1);
      }break;
      case S_READ_CALIB_CMD3:{
        calib->coefficient[2]=*((nx_uint16_t*)data);//data from the sensor is big endian
        state=S_READ_CALIB_CMD4;
        i2cBuffer[0]=MS5607_PROM_READ+(4<<1);
      }break;
      case S_READ_CALIB_CMD4:{
        calib->coefficient[3]=*((nx_uint16_t*)data);//data from the sensor is big endian
        state=S_READ_CALIB_CMD5;
        i2cBuffer[0]=MS5607_PROM_READ+(5<<1);
      }break;        
      case S_READ_CALIB_CMD5:{
        calib->coefficient[4]=*((nx_uint16_t*)data);//data from the sensor is big endian
        state=S_READ_CALIB_CMD6;
        i2cBuffer[0]=MS5607_PROM_READ+(6<<1);
      }break;
    }
    //read the next calibration constant
    lastError = call I2CPacket.write(I2C_START, MS5607_ADDRESS, 1, i2cBuffer);
    if( lastError != SUCCESS) {
      call I2CResource.release();
      post signalReadDone();
    }
  }
  
  default event void ReadCalibration.readDone(error_t err, calibration_t *data){};
  default event void ReadPressure.readDone(error_t err, uint32_t data){};
  default event void ReadTemperature.readDone(error_t err, uint32_t data){};
}

