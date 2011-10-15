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

#include "Bma180.h"
module BmaReadP
{
  provides {
    interface Read<bma180_data_t>;
    interface StdControl as BmaControl;
    interface Init;
  }
  uses {
    interface Leds;
    interface Timer<TMilli>;
    interface LocalTime<TMilli>;
    interface DiagMsg;
    interface FastSpiByte;
    interface Resource;
    interface GeneralIO as CSN;
    interface GeneralIO as PWR;
  }
}

implementation
{
  enum{
    S_OFF = 0,
    S_STARTING,
    S_CONFIG,
    S_RESTART,
    S_IDLE,
  };

  bma180_data_t s_res;
  uint16_t x,y,z;
  norace uint8_t temp, state=S_OFF;

  void writeRegister(uint8_t, uint8_t);
  uint8_t readRegister(uint8_t);

  command error_t Init.init() {
    call CSN.set();
    call CSN.makeOutput();
    return SUCCESS;
  }
	
  command error_t BmaControl.start() {
    if(state == S_STARTING) return EBUSY;
    if(state != S_OFF) return EALREADY;

    state = S_STARTING;
    call PWR.makeOutput();
    call PWR.set();
    state = S_CONFIG;
    return SUCCESS;
  }

  command error_t BmaControl.stop() {
    call PWR.makeOutput();
    call PWR.clr();
    return SUCCESS;
  }

  void setLeds(uint8_t data)
  {
    if( (data & 0x01) != 0 )
      call Leds.led0On();
    else
      call Leds.led0Off();

    if( (data & 0x02) != 0 )
      call Leds.led1On();
    else
      call Leds.led1Off();

    if( (data & 0x04) != 0 )
      call Leds.led2On();
    else
      call Leds.led2Off();
  }

  command error_t Read.read() {
    call Resource.request();
    return SUCCESS;
  }

  uint8_t readRegister(uint8_t address) {
    uint8_t ret;
    call CSN.clr();
    call FastSpiByte.write(0x80 | address);
    ret = call FastSpiByte.write(0);
    call CSN.set();
    return ret;
  }

  void writeRegister(uint8_t address, uint8_t newValue) {
    call CSN.clr();
    call FastSpiByte.write(0x7F & address);
    call FastSpiByte.write(newValue);
    call CSN.set();
  }  

  void setup_params(){
      temp = readRegister(0xD); //ctrl_reg0
      temp |= 0x10;                  // enable ee_w; needed for writing to addresses 0x20 .. 0x3B
      writeRegister(0xD, temp);

      temp = readRegister(0x35); //offset_lsb1
      temp &= 0xF1;                  // clear range bits
      temp |= (BMA_RANGE<<1);
      writeRegister(0x35, temp);

      temp = readRegister(0x30); //tco_z
      temp &= 0xFC;                 // clear mode bits
      temp |= BMA_MODE;
      writeRegister(0x30, temp);

      temp = readRegister(0x20); // bw_tcs
      temp &= 0x0F;
      temp |= (BMA_BW<<4);
      writeRegister(0x20, temp);

      temp = readRegister(0x21); //ctrl_reg3
      temp = BMA_CTRL_REG3;
      writeRegister(0x21, temp);  
  }
  
  event void Timer.fired()
  {
    if(state==S_CONFIG){
      setup_params();

      temp = readRegister(0xD); //ctrl_reg0
      temp &= 0x02;
      temp |= (1<<1);   //sleep control;  1:enable sleep   
      writeRegister(0xD, temp);

      state = S_IDLE;
      call Timer.startOneShot(1);
    }

    else if(state == S_RESTART) {
      setup_params();
      state = S_IDLE;
      call Timer.startOneShot(10);
    }
    else if(state == S_IDLE) {

    call Leds.led3Toggle();

    //check if the sensor is in sleep mode
    temp = readRegister(0xD);
    temp &= 0x02;
    //if so, then wake it up
    if(temp){
      temp &=~ (1<<1);   //sleep control;  1:enable sleep   
      writeRegister(0xD, temp);
      
      state = S_RESTART;
      return call Timer.startOneShot(10);
    }    

    //chipSelect
    call CSN.clr();

    // read registers
		
    call FastSpiByte.write(0x80 | 0x02);
    x = call FastSpiByte.write(0x00);//x
    x |= (call FastSpiByte.write(0) << 8);
    y = call FastSpiByte.write(0);//y
    y |= (call FastSpiByte.write(0) << 8);
    z = call FastSpiByte.write(0);//z
    z |= (call FastSpiByte.write(0) << 8);
    s_res.bma180_temperature = (int8_t)(call FastSpiByte.write(0));
    s_res.bma180_short_timestamp = (uint8_t)(call LocalTime.get());

    //chipDeselect
    call CSN.set();
    
    s_res.bma180_accel_x = ( ((int16_t)x)>>2)*convRatio[BMA_RANGE];
    s_res.bma180_accel_y = ( ((int16_t)y)>>2)*convRatio[BMA_RANGE];
    s_res.bma180_accel_z = ( ((int16_t)z)>>2)*convRatio[BMA_RANGE];
    call Resource.release();
    signal Read.readDone(SUCCESS, s_res);
    //setLeds(x);
    }
  }

  event void Resource.granted() {
    call Timer.startOneShot(BMA_SAMPLING_TIME_MS);
  }

}
