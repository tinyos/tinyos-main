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

#include "DataMsg.h"

module Mts400TesterP {
	uses interface Boot;
	uses interface Leds;
	uses interface SplitControl;
	uses interface Read<uint16_t> as X_Axis;
	uses interface Read<uint16_t> as Y_Axis;
	uses interface Intersema;
	uses interface Read<uint16_t> as Temperature;
	uses interface Read<uint16_t> as Humidity;
	uses interface Read<uint16_t> as VisibleLight;
	uses interface Read<uint16_t> as InfraredLight;
	uses interface AMSend;
}
implementation {
	
	uint16_t AccelX_data,AccelY_data,Temp_data,Hum_data,VisLight_data;
	int16_t Intersema_data[2];
	
	event void Boot.booted() {
		call SplitControl.start();
	}
	
	event void SplitControl.startDone(error_t err){
		if(err==SUCCESS){
			call X_Axis.read();
			call Leds.led0On();
		}else{
			call SplitControl.start();
		}
	}
	
	event void X_Axis.readDone(error_t err, uint16_t data){
		AccelX_data=data;
		call Y_Axis.read();
	}
	
	event void Y_Axis.readDone(error_t err, uint16_t data){
		AccelY_data=data;
		call Intersema.read();
	}
	
	event void Intersema.readDone(error_t err, int16_t* data){
		Intersema_data[0]=data[0];
		Intersema_data[1]=data[1];
		call Temperature.read();
	}
	
	event void Temperature.readDone(error_t err, uint16_t data){
		Temp_data=data;
		call Humidity.read();
	}
	
	event void Humidity.readDone(error_t err, uint16_t data){
		Hum_data=data;
		call VisibleLight.read();
	}
	
	event void VisibleLight.readDone(error_t err, uint16_t data){
		VisLight_data=data;
		call InfraredLight.read();
	}
	
	message_t message;
	
	event void InfraredLight.readDone(error_t err, uint16_t data){
		datamsg_t* packet = (datamsg_t*)(call AMSend.getPayload(&message, sizeof(datamsg_t)));
		packet-> AccelX_data=AccelX_data;
		packet-> AccelY_data = AccelY_data;
		packet-> Intersema_data[0] = Intersema_data[0];
		packet-> Intersema_data[1] = Intersema_data[1];
		packet-> Temp_data =Temp_data;
		packet-> Hum_data = Hum_data;
		packet-> VisLight_data = VisLight_data;
		packet-> InfLight_data = data;
		call AMSend.send(AM_BROADCAST_ADDR, &message, sizeof(datamsg_t));
	}

	event void AMSend.sendDone(message_t* bufPtr, error_t error){
		call X_Axis.read();
		call Leds.led1Toggle();
	}
	
	event void SplitControl.stopDone(error_t err){}
}
