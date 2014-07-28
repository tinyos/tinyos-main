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
#include "Bma180.h"
#include "UserButton.h"

module UcminiSensorP {
  uses {
    interface Boot;
    interface Read<int16_t> as TempShtRead;
    interface Read<int16_t> as HumiRead;
    interface Read<uint16_t> as LightRead;
    interface Read<uint32_t> as PressRead;
    interface Read<int16_t> as TempMsRead;
    interface Read<int16_t> as TempAtRead;
#if !defined(UCMINI_REV) || UCMINI_REV >= 200
    interface Read<uint16_t> as VoltageRead;
    interface Read<uint8_t> as SwitchRead;
#endif
    interface Get<button_state_t>;
    interface DiagMsg;
    interface AMSend as MeasSend;
    interface Packet;
    interface Timer<TMilli>;
    interface Leds;
    interface SplitControl;
  }
}
implementation {  
  measurement_t *meas;
  message_t message[2];
  message_t *currentMessage = &message[0];
  bool starting=TRUE;

  event void Boot.booted() {
    meas = (measurement_t*)call Packet.getPayload(currentMessage, sizeof(measurement_t));
    call Timer.startPeriodic(512);
  }
  

  event void Timer.fired(){
    if(!starting) {
      if( currentMessage == &message[0] ){
        currentMessage = &message[1];
      } else {
        currentMessage = &message[0];
      }
      meas = (measurement_t*)call Packet.getPayload(currentMessage, sizeof(measurement_t));
      call SplitControl.start();
    } else
      starting=FALSE;
    call TempShtRead.read();
    call HumiRead.read();
    call LightRead.read();
    call PressRead.read();
    call TempMsRead.read();
    call TempAtRead.read();
#if !defined(UCMINI_REV) || UCMINI_REV >= 200
    call VoltageRead.read();
    call SwitchRead.read();
#endif
    meas->button = call Get.get();
  }

  event void TempShtRead.readDone(error_t error, int16_t data){
    if(error==SUCCESS){
      meas->temp_sht21=data;
    } else
      call Leds.led3Toggle();
  }

  event void HumiRead.readDone(error_t error, int16_t data) { 
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
  
  event void TempMsRead.readDone(error_t error, int16_t data) { 
    if(error==SUCCESS){
      meas->temp_ms5607=data;
    } else
      call Leds.led3Toggle();
    
  }
  
#if !defined(UCMINI_REV) || UCMINI_REV >= 200
  event void VoltageRead.readDone(error_t error, uint16_t data) { 
    if(error==SUCCESS){
      meas->voltage=data;
    } else
      call Leds.led3Toggle();
  }
  
  event void SwitchRead.readDone(error_t error, uint8_t data){
    if(error==SUCCESS){
      meas->batswitch=data;
    } else
      call Leds.led3Toggle();
  }
#endif

  event void TempAtRead.readDone(error_t error, int16_t data) { 
    if(error==SUCCESS){
      meas->temp_atmel=data;
    } else
      call Leds.led3Toggle();
  }
  
  event void SplitControl.startDone(error_t err){
    if( currentMessage == &message[0] ){
      call MeasSend.send(AM_BROADCAST_ADDR, &message[1], sizeof(measurement_t));
    } else {
      call MeasSend.send(AM_BROADCAST_ADDR, &message[0], sizeof(measurement_t));
    }
  }
  
  event void MeasSend.sendDone(message_t* msg, error_t error){
    call SplitControl.stop();
  }
  
  event void SplitControl.stopDone(error_t err){}
    
}
