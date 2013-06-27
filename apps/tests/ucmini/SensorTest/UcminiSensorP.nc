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
* Author: Andras Biro
*/ 

#include "Ms5607.h"

module UcminiSensorP {
  uses {
    interface Boot;
    interface Read<uint16_t> as TempRead;
    interface Read<uint16_t> as HumiRead;
    interface Read<uint16_t> as LightRead;
    interface Read<uint32_t> as PressRead;
    interface Read<int16_t> as Temp2Read;
    interface Read<uint16_t> as Temp3Read;
    interface Read<uint16_t> as VoltageRead;
    interface ReadRef<calibration_t>;
    interface DiagMsg;
    interface AMSend as CalibSend;
    interface AMSend as MeasSend;
    interface Receive;
    interface Packet;
    interface Timer<TMilli>;
    interface Leds;
  }
}
implementation {  
  measurement_t *meas;
  message_t message, calibmessage;
  calibration_t *calib;
  bool starting=TRUE;

  event void Boot.booted() {
    calib = (calibration_t*)call Packet.getPayload(&calibmessage, sizeof(calibration_t));
    meas = (measurement_t*)call Packet.getPayload(&message, sizeof(measurement_t));
    call ReadRef.read(calib);
  }
  
  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
    if(!starting)
      call CalibSend.send(AM_BROADCAST_ADDR, &calibmessage, sizeof(calibration_t));
    return msg;
  }
  
  event void ReadRef.readDone(error_t error, calibration_t *data){
    call CalibSend.send(AM_BROADCAST_ADDR, &calibmessage, sizeof(calibration_t));
  }
  
  event void CalibSend.sendDone(message_t* msg, error_t error){
    if(starting)
      call Timer.startPeriodic(512);
  }

  event void Timer.fired(){
    if(!starting)
      call MeasSend.send(AM_BROADCAST_ADDR, &message, sizeof(measurement_t));
    else
      starting=FALSE;
    
    call TempRead.read();
    call HumiRead.read();
    call LightRead.read();
    call PressRead.read();
    call Temp2Read.read();
    call Temp3Read.read();
    call VoltageRead.read();
  }
  
  event void TempRead.readDone(error_t error, uint16_t data){
    if(error==SUCCESS){
      meas->temp=data;
    } else
      call Leds.led3Toggle();
  }

  event void HumiRead.readDone(error_t error, uint16_t data) { 
    if(error==SUCCESS){
      meas->humi=data;
    } else
      call Leds.led3Toggle();
  }
  
  event void LightRead.readDone(error_t error, uint16_t data) { 
    if(error==SUCCESS){
      meas->light=data;
    } else
      call Leds.led3Toggle();
    
  }
  
  event void PressRead.readDone(error_t error, uint32_t data) { 
    if(error==SUCCESS){
      meas->press=data;
    } else
      call Leds.led3Toggle();
    
  }
  
  event void Temp2Read.readDone(error_t error, int16_t data) { 
    if(error==SUCCESS){
      meas->temp2=data;
    } else
      call Leds.led3Toggle();
    
  }
  
  event void VoltageRead.readDone(error_t error, uint16_t data) { 
    if(error==SUCCESS){
      meas->voltage=data;
    } else
      call Leds.led3Toggle();
  }
  
  event void Temp3Read.readDone(error_t error, uint16_t data) { 
    if(error==SUCCESS){
      meas->temp3=data;
    } else
      call Leds.led3Toggle();
  }
  
  event void MeasSend.sendDone(message_t* msg, error_t error){}
}

