/*
 * Copyright (c) 2009 DEXMA SENSORS SL
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
 * Implementation of a simple read interface for the TMP102 temperature
 * sensor built-in Zolertia Z1 motes, returns value in celsius degrees
 * multiplied by 10, only 1 digit accuracy.
 *
 * @author: Xavier Orduna <xorduna@dexmatech.com>
 * @author: Jordi Soucheiron <jsoucheiron@dexmatech.com>
 */

#include "TMP102.h"

module SimpleTMP102P {
   provides interface Read<uint16_t>;
   uses {
    interface Timer<TMilli> as TimerSensor;
    interface Timer<TMilli> as TimerFail;
  	interface Resource;
  	interface ResourceRequested;
  	interface I2CPacket<TI2CBasicAddr> as I2CBasicAddr;        
  }
}

implementation {
  
  uint16_t temp;
  uint8_t pointer;
  uint8_t temperaturebuff[2];
  uint16_t tmpaddr;
  
  norace uint8_t tempcmd;
    
  task void calculateTemp(){
    uint16_t tmp = temp;
    #ifdef Z1_TMP102_CELSIUS
      if(tmp > 2047) tmp -= (1<<12);
      atomic tmp *= 0.625;
    #endif
  	signal Read.readDone(SUCCESS, tmp);
  }
  
  command error_t Read.read(){
	atomic P5DIR |= 0x01;
	atomic P5OUT |= 0x01;
	call TimerSensor.startOneShot(100);
	//call TimerFail.startOneShot(1024);
	return SUCCESS;
  }

  event void TimerSensor.fired() {
	call Resource.request();  
  }
  
  event void TimerFail.fired() {
  	signal Read.readDone(SUCCESS, 0);
  }

  event void Resource.granted(){
    error_t error;
    pointer = TMP102_TEMPREG;
    tempcmd = TMP_READ_TMP;
    error= call I2CBasicAddr.write((I2C_START | I2C_STOP), TMP102_ADDRESS, 1, &pointer); 
    if(error){
      call Resource.release();
      signal Read.readDone(error, 0);
    }
  }
  
  async event void I2CBasicAddr.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data){
    if(call Resource.isOwner()) {
	uint16_t tmp;
	for(tmp=0;tmp<0xffff;tmp++);	//delay
	call Resource.release();
	tmp = data[0];
	tmp = tmp << 8;
	tmp = tmp + data[1];
	tmp = tmp >> 4;
	atomic temp = tmp;
	post calculateTemp();
	}
  }

  async event void I2CBasicAddr.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data){
    if(call Resource.isOwner()){
      error_t e;
      e = call I2CBasicAddr.read((I2C_START | I2C_STOP),  TMP102_ADDRESS, 2, temperaturebuff);
      if(e){
        call Resource.release();
        signal Read.readDone(error, 0);
       }
     }
  }   
  
  async event void ResourceRequested.requested(){ }
  async event void ResourceRequested.immediateRequested(){ }	  
  
}
