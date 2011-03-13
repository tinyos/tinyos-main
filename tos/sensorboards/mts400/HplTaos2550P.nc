/** Copyright (c) 2009, University of Szeged
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
* Author: Zoltan Kincses
*/

#include"Taos2550.h"

module HplTaos2550P {
	provides interface SplitControl;
	uses interface Channel as ChannelLightPower;
	uses interface Timer<TMilli> as Timer;
	uses interface I2CPacket<TI2CBasicAddr>;
	uses interface Resource as I2CResource;
	uses interface Resource;
}
implementation {

	enum{
		IDLE=0,
		START,
		STOP,
	};
	norace uint8_t state=IDLE;
	uint8_t cmd=TAOS_START;
	
	task void failTask();
	task void startTimer();
	
	
	command error_t SplitControl.start() {
		state=START;
		return call Resource.request();
	}
	
	event void Resource.granted(){
		error_t err;
		if(state==START){
			if((err=call ChannelLightPower.open())==SUCCESS){
				return;
			}
		}else{
			if((err=call ChannelLightPower.close())==SUCCESS){
				return;
			}
		}
		state=IDLE;
		call Resource.release();
		signal SplitControl.startDone(err);
	}
	
	event void ChannelLightPower.openDone(error_t err){
		if(err==SUCCESS){
			if((err=call I2CResource.request())==SUCCESS){
				return;
			}
		}
		state=IDLE;
		call Resource.release();
		signal SplitControl.startDone(err);
	}
	
	event void I2CResource.granted(){
		error_t err;
		if((err=call I2CPacket.write((I2C_START|I2C_STOP|I2C_ACK_END),TAOS_I2C_ADDR,1,&cmd))!=SUCCESS){
			state=IDLE;
			call Resource.release();
			call I2CResource.release();
			signal SplitControl.startDone(err);
		}
	}
	
	async event void I2CPacket.writeDone(error_t error, uint16_t addr,uint8_t length, uint8_t* data){
		state=IDLE;
		call Resource.release();
		call I2CResource.release();
		if(error!=SUCCESS){
			post failTask();
		}else{
			post startTimer();
		}
	}
	
	event void Timer.fired(){
		signal SplitControl.startDone(SUCCESS);
	}
	
	command error_t SplitControl.stop() {
		state=STOP;
		return  call Resource.request();
	}
	
	event void ChannelLightPower.closeDone(error_t err)	{
		state=IDLE;
		call Resource.release();
		signal SplitControl.stopDone(err);
	}
	
	task void failTask(){
		signal SplitControl.startDone(FAIL);
	}
	
	task void startTimer(){
		call Timer.startOneShot(WARM_UP_TIME);
	}
	
	async event void I2CPacket.readDone(error_t error, uint16_t addr,uint8_t length, uint8_t* data){}
}
