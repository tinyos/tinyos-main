/*
 * Copyright (c) 2011 ZOLERTIA LABS
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Simple driver for the BMP085 sensor, only reads the calibration values and
 * returns the atmospheric pressure level
 *
 * @author: Antonio Linan <alinan@zolertia.com>
 */

#include "PrintfUART.h"
#include "bmp085.h"

module BMP085P{
  provides{
    interface Read<uint16_t> as Pressure;
    interface SplitControl as BMPSwitch;
  }
  uses {
   interface Resource;
   interface ResourceRequested;
   interface I2CPacket<TI2CBasicAddr> as I2CBasicAddr;     
   interface GeneralIO as Reset;
   interface Timer<TMilli> as TimeoutTimer;
  }
}

implementation{

  enum {
    S_STARTED,
    S_STOPPED,
    S_IDLE,
  };

  norace uint8_t state = S_IDLE;
  norace uint8_t bmp085cmd;
  norace uint8_t databuf[22];
  norace error_t error_return= FAIL;
  norace int32_t b5 = 0;
  norace int16_t temp;  
  norace int32_t press = 0;
  norace int16_t pressure = 0;
  norace bool readPres = FALSE;
  norace bool readAlt = FALSE;

  // Calibration registers

  int16_t ac1, ac2, ac3, b1, b2, mb, mc, md = 0;
  uint16_t ac4, ac5, ac6 = 0;

  task void stopTimeout(){
    call TimeoutTimer.stop();
  }

  task void signalEvent(){
    if (error_return == SUCCESS){
      if (call TimeoutTimer.isRunning()) call TimeoutTimer.stop();
    }

    if (call Resource.isOwner()) call Resource.release();

    switch(bmp085cmd){
      case BMPCMD_READ_CALIB:
        if (error_return == SUCCESS) state = S_STARTED;
        signal BMPSwitch.startDone(error_return);
        break;

      case BMPCMD_READ_PRES:
        signal Pressure.readDone(error_return, pressure);
        break;
    }
  }

  void calcTemp(uint32_t tmp){
    int32_t x1, x2 = 0;
    atomic{
      x1 = (((int32_t)tmp - (int32_t)ac6) * (int32_t)ac5) >> 15;
      x2 = ((int32_t)mc << 11) / (x1 + md);
      b5 = x1 + x2;
      temp = (b5 + 8) >> 4;
    }
     #ifdef DEBUG_ZIGLET
       printfUART("[BMP085] Temp [%d.%d C]\n", temp/10, temp<<2);
     #endif
  }

  void calcPres(int32_t tmp){
    uint32_t b4, b7 = 0;
    int32_t x1, x2, x3, b3, b6, p = 0;
    atomic{
      b6 = b5 - 4000; 
      x1 = (b2 * (b6 * b6 >> 12)) >> 11;
      x2 = ac2 * b6 >> 11;
      x3 = x1 + x2;
      b3 = ((((int32_t)ac1) * 4 + x3) + 2) >> 2;

      // printfUART("b6[%ld] x1[%ld] x2[%ld] x3[%ld] b3[%ld]\n", b6, x1, x2, x3, b3);

      x1 = (ac3 * b6) >> 13;
      x2 = (b1 * ((b6 * b6) >> 12)) >> 16;
      x3 = ((x1 + x2) + 2) >> 2;
      b4 = (ac4 * ((uint32_t)(x3 + 32768))) >> 15;
      b7 = ((uint32_t) tmp - b3) * 50000;

      // printfUART("b7[%lu] x1[%ld] x2[%ld] x3[%ld] b4[%lu]\n", b7, x1, x2, x3, b4);

      if (b7 < 0x80000000){
        p = (b7 << 1) / b4;
      } else {
        p = (b7 / b4) << 1;
      }

      x1 = (p >> 8) * (p >> 8);
      x1 = (x1 * 3038) >> 16;
      x2 = (-7357 * p) >> 16; 
      press = (p + ((x1 + x2 + 3791) >> 4));
      press /= 10;
      pressure = press;
    }
    #ifdef DEBUG_ZIGLET
      printfUART("[BMP085] Pressure [%u mbar]\n", pressure);
    #endif

    readPres = FALSE;
    error_return = SUCCESS;
    post signalEvent();
  }
      
  command error_t BMPSwitch.start(){
    error_t e;
    uint8_t i;
    error_return = FAIL;
    atomic P5DIR |= 0x06;
    call TimeoutTimer.startOneShot(1024);
    if(state != S_STARTED){
      bmp085cmd = BMPCMD_START;
      for (i=0;i<22;i++) databuf[i] = 0;
      e = call Resource.request();
      if (e == SUCCESS) return SUCCESS;
    }
    return e;
  }

  command error_t BMPSwitch.stop(){
    error_t e = FAIL;
    if(state != S_STARTED){
      state = S_STOPPED;
      e = SUCCESS;  
    }
    signal BMPSwitch.stopDone(e);
    return e;
  }

  command error_t Pressure.read(){
    error_t e;
    error_return = FAIL;
    atomic P5DIR |= 0x06;
    call TimeoutTimer.startOneShot(1024);
    if (state == S_STARTED){
      bmp085cmd = BMPCMD_READ_UT;
      readPres = TRUE;
      e = call Resource.request();
      if (e == SUCCESS) return SUCCESS;
    }
    return e;
  }

  event void Resource.granted(){
    error_t e;
    switch(bmp085cmd){
      case BMPCMD_START:
        bmp085cmd = BMPCMD_READ_CALIB;
        databuf[0] = BMP085_AC1_MSB; // 0xAA	
        e = call I2CBasicAddr.write((I2C_START | I2C_STOP), BMP085_ADDR, 1, databuf);
        #ifdef DEBUG_ZIGLET
          if(e != SUCCESS) printfUART("[BMP085] Error at start (%d)\n", e);
        #endif
        break;

      case BMPCMD_READ_UT:
        databuf[0] = BMP085_CTLREG;   // 0xF4
        databuf[1] = BMP085_UT_NOSRX; // 0x2E	
        e = call I2CBasicAddr.write((I2C_START | I2C_STOP), BMP085_ADDR, 2, databuf);
        #ifdef DEBUG_ZIGLET
          if (e != SUCCESS) printfUART("[BMP085] Error at UT (%d)\n", e);
        #endif
        break;

      case BMPCMD_READ_UP:
        databuf[0] = BMP085_CTLREG;   // 0xF4
        databuf[1] = BMP085_UP_OSRS0; // 0x34
        e = call I2CBasicAddr.write((I2C_START | I2C_STOP), BMP085_ADDR, 2, databuf);
        #ifdef DEBUG_ZIGLET
          if (e != SUCCESS) printfUART("[BMP085] Error at UP (%d)\n", e);
        #endif
        break;
    }
  }

  async event void I2CBasicAddr.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data){
    error_t e;
    if(call Resource.isOwner()){
      switch(bmp085cmd){
        case BMPCMD_READ_UT:
        case BMPCMD_READ_UP:
            if (bmp085cmd == BMPCMD_READ_UT){
              bmp085cmd = BMPCMD_READ_TEMP;
            } else {
              bmp085cmd = BMPCMD_READ_PRES;      
            }
            databuf[0] = BMP085_DATA_MSB;   // 0xF6
            e = call I2CBasicAddr.write((I2C_START | I2C_STOP), BMP085_ADDR, 1, databuf);
          break;

        case BMPCMD_READ_CALIB:
          e = call I2CBasicAddr.read((I2C_START | I2C_STOP), BMP085_ADDR, 22, databuf);  
          break;

        case BMPCMD_READ_TEMP:
        case BMPCMD_READ_PRES:
          e = call I2CBasicAddr.read((I2C_START | I2C_STOP), BMP085_ADDR, 2, databuf);  
          break;
      }
    }
  }


  async event void I2CBasicAddr.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data){
    int16_t utemp = 0;
    int32_t upres = 0;

    if (call Resource.isOwner()){
      switch(bmp085cmd){
        case BMPCMD_READ_CALIB:
          if (error == SUCCESS){
            post stopTimeout();
            atomic {
              ac1 = (data[0]<<8) + data[1];
              ac2 = (data[2]<<8) + data[3];
              ac3 = (data[4]<<8) + data[5];
              ac4 = (data[6]<<8) + data[7];
              ac5 = (data[8]<<8) + data[9];
              ac6 = (data[10]<<8) + data[11];
              b1 = (data[12]<<8) + data[13];
              b2 = (data[14]<<8) + data[15];
              mb = (data[16]<<8) + data[17];
              mc = (data[18]<<8) + data[19];
              md = (data[20]<<8) + data[21];
              error_return = SUCCESS;
            }
          }
          post signalEvent(); 
          break;

       case BMPCMD_READ_TEMP:
         utemp = (data[0]<<8) + data[1];
         calcTemp(utemp);
         break;

       case BMPCMD_READ_PRES:
         upres = ((int32_t)data[0] << 8) + (int32_t)data[1];
         calcPres(upres);
         break;
      }
      call Resource.release();
      if (readPres){
        bmp085cmd = BMPCMD_READ_UP;
        call Resource.request();
      }
    }
  }

  event void TimeoutTimer.fired(){
    post signalEvent();
  }
  
  async event void ResourceRequested.requested(){}  
  async event void ResourceRequested.immediateRequested(){}
  default event void Pressure.readDone(error_t error, uint16_t data){ return; }
}
