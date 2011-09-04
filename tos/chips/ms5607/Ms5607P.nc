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

#include "Ms5607.h" 

module Ms5607P  {
  provides interface Read<uint32_t> as Pressure;
  provides interface Read<int16_t> as Temperature;
  provides interface SplitControl;
  
  uses interface Timer<TMilli>;
  uses interface Read<uint32_t> as RawTemp;
  uses interface Read<uint32_t> as RawPress;
  uses interface Calibration as Cal;

  uses interface Leds;
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

  uint8_t res[3];
  uint32_t mesres;
  uint8_t state = S_OFF;
  uint16_t c1,c2,c3,c4,c5,c6,OFF,SENS;
  int32_t dT,P, tmpt;
  int16_t TEMP;

  int64_t tmp, mul;
  int64_t mul64, tmp64;

  bool stopRequested = FALSE;
  bool otherSensorRequested = FALSE;
  bool setup = TRUE;


  command error_t SplitControl.start() {
    if(state == S_STARTING) return EBUSY;
    if(state != S_OFF) return EALREADY;
    
    call Timer.startOneShot(3);

    return SUCCESS;
  }
  
  task void signalStopDone() {
    signal SplitControl.stopDone(SUCCESS);
  }

  command error_t SplitControl.stop() {
    if(state == S_STOPPING) return EBUSY;
    if(state == S_OFF) return EALREADY;
    if(state == S_ON) {
      state = S_OFF;
      post signalStopDone();
    } else {
      stopRequested = TRUE;
    }
    return SUCCESS;
  }  

  event void Cal.dataReady(error_t error, uint16_t* calibration) {
    c1 = calibration[1];
    c2 = calibration[2];
    c3 = calibration[3];
    c4 = calibration[4];
    c5 = calibration[5];
    c6 = calibration[6];

    signal SplitControl.startDone(error);
  }

  command error_t Pressure.read() {
    if(state == S_OFF) return EOFF;
    if(state == S_READ_TEMP) {
      otherSensorRequested = TRUE;
      return SUCCESS;
    }
    if(state != S_ON) return EBUSY;
/*i2c */
    state = S_READ_PRESS;
    call RawPress.read();
    return SUCCESS;
  }

  command error_t Temperature.read() {
    if(state == S_OFF) return EOFF;
    if(state == S_READ_PRESS) {
      otherSensorRequested = TRUE;
      return SUCCESS;
    }
    if(state != S_ON) return EBUSY;

    state = S_READ_TEMP;

    call RawTemp.read();
    return SUCCESS;
  }

  event void Timer.fired() {
    if(state == S_OFF) {
      state = S_ON;
      if(setup)
        call Cal.getData();
      setup = FALSE;
    }  
  }

  task void signalReadDone() {
    signal Pressure.readDone(SUCCESS, mesres);
  }

  event void RawTemp.readDone(error_t error, uint32_t val) {
    if(error == SUCCESS) {
     /* dT = val - (c5 << 8);
      TEMP = 2000 + (dT * (uint32_t)c6 >> 23);
    */
     tmpt= c5;
     tmpt <<= 8;
     dT = val - tmpt; 
   
      tmp= c6;
      mul= dT;
      mul *= tmp;
      mul >>= 23;
   
   
      TEMP = 2000;
      TEMP += mul;
    
      if(TEMP<2000) {
        int32_t T2 = ((int64_t)dT * dT) >> 31;
        TEMP -= T2;
      }
    }
    state = S_ON;
    signal Temperature.readDone(error, TEMP);
  }

  event void RawPress.readDone(error_t error, uint32_t rawpress) {
    int64_t offset, sensitivity;
    /*offset = ((uint64_t)c2 << 17) + (((int64_t)c4 * dT) >> 6); // <<17     >>6
    sensitivity = ((uint32_t)c1 << 16) + (( (int64_t)c3 * dT) >> 7);// <<16   >>7
    P = ( (int64_t)val * (sensitivity >> 21) - offset) >> 15;// >>21    >>15
    */
    tmp64 = c2;
   tmp64 <<= 17;
   
   mul64 = c4;
   mul64 *= dT;
   mul64 >>= 6;
   
   offset = mul64;
    offset += tmp64;
    tmp64 = c1;
    tmp64 <<= 16;
    
    mul64 = c3;
    mul64 *= dT;
    mul64 >>= 7;
    sensitivity = tmp64;
    sensitivity += mul64;
    //sensitivity = ((uint32_t)c1 << 16) + (((int64_t)c3 * dT) >> 7);
    
    tmp64 = sensitivity;
    tmp64 >>= 21;
    tmp64 *= rawpress;
    tmp64 -= offset;
    tmp64 >>= 15;
    P = tmp64;
    
    state = S_ON;
    signal Pressure.readDone(error, P);   
  }

  default event void Pressure.readDone(error_t error, uint32_t val) { }
  default event void Temperature.readDone(error_t error, int16_t val) { }
  default event void SplitControl.startDone(error_t error) { }
  default event void SplitControl.stopDone(error_t error) { }
}
