/*
 * Copyright (c) 2012 Sestosenso
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Sestosenso nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * SESTOSENSO OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/**
* DIOP module passes commands between the DigOutput and Read interfaces
* 
* @author Charles Elliott
* @modified Feb 27, 2009
*  
*  @modified September 2012 by Franco Di Persio, Sestosenso

*/

module DIOP {
  provides 
  {
	interface Read<uint8_t>  as Read_DIO;
	interface Read<uint8_t> as DigChannel_0;
	interface Read<uint8_t> as DigChannel_1;
	interface Read<uint8_t> as DigChannel_2;
	interface Read<uint8_t> as DigChannel_3;
  	interface Read<uint8_t> as DigChannel_4;
	interface Read<uint8_t> as DigChannel_5;
	
	interface Relay as Relay_NC;
	interface Relay as Relay_NO;
	
  }
  uses
  {
	interface DigOutput;
	interface Leds;
  }
}
implementation {
	uint8_t bitmap = 0x00;
	uint8_t i2c_data = 0xFF;
	
	#define  testbit(var, bit)   ((var) & (1 <<(bit)))      //if zero then return zero and if one not equal zero
	#define  setbit(var, bit)    ((var) |= (1 << (bit)))
	#define  clrbit(var, bit)    ((var) &= ~(1 << (bit)))

	task void set_bit_low();
	task void set_bit_high();
	task void set_bit_toggle();
		
	command error_t Read_DIO.read() {    
    return call DigOutput.requestRead();
	}	
  
	event void DigOutput.readyToRead (){
		uint8_t channel;
		channel = call DigOutput.read();
		channel = channel | 0xC0;		//to consider only the least significant 6 bit. 0xC0 = 1100 0000
				
		if (channel == 0xFE){
			signal DigChannel_0.readDone(SUCCESS, channel);
		}else if (channel == 0xFD){
			signal DigChannel_1.readDone(SUCCESS, channel);
		}else if (channel == 0xFB){
			signal DigChannel_2.readDone(SUCCESS, channel);
		}else if (channel == 0xF7){
			signal DigChannel_3.readDone(SUCCESS, channel);
		}else if (channel == 0xEF){
			signal DigChannel_4.readDone(SUCCESS, channel);
		}else if (channel == 0xDF){
			signal DigChannel_5.readDone(SUCCESS, channel);
		}else if (channel == 0xFF){
			signal Read_DIO.readDone(SUCCESS, channel);
		}
	}
	
	command error_t DigChannel_0.read() {    
    return SUCCESS;
	}	
	command error_t DigChannel_1.read() {    
    return SUCCESS;
	}	
	command error_t DigChannel_2.read() {    
    return SUCCESS;
	}	
	command error_t DigChannel_3.read() {    
    return SUCCESS;
	}	
	command error_t DigChannel_4.read() {    
    return SUCCESS;
	}	
	command error_t DigChannel_5.read() {    
    return SUCCESS;
	}
	
	command error_t Relay_NC.open() {   
    	setbit(bitmap,7);				//only considering the 7th bit. Port P7 on the PCA8574A
    	post set_bit_low();
		return call DigOutput.setAll(i2c_data);
	}
	
	command error_t Relay_NC.close() {   
    	setbit(bitmap,7);				//only considering the 7th bit. Port P7 on the PCA8574A
    	post set_bit_high();
		return call DigOutput.setAll(i2c_data);
	}
	
	command error_t Relay_NO.open() {   
    	setbit(bitmap,6);				//only considering the 6th bit. Port P6 on the PCA8574A
    	post set_bit_high();
		return call DigOutput.setAll(i2c_data);
	}
	
	command error_t Relay_NO.close() {   
    	setbit(bitmap,6);				//only considering the 6th bit. Port P6 on the PCA8574A
    	post set_bit_low();
		return call DigOutput.setAll(i2c_data);
	}
	
	command error_t Relay_NO.toggle() {   
    	setbit(bitmap,6);				//only considering the 6th bit. Port P6 on the PCA8574A
    	post set_bit_toggle();
		return call DigOutput.setAll(i2c_data);
	}
	
	command error_t Relay_NC.toggle() {   
    	setbit(bitmap,7);				//only considering the 6th bit. Port P6 on the PCA8574A
    	post set_bit_toggle();
		return call DigOutput.setAll(i2c_data);
	}
	
	task void set_bit_low() {
		uint8_t i;
		for (i=0;i<=7;i++) {
			if testbit(bitmap,i) {
				clrbit(i2c_data,i);
			}
		}
		bitmap = 0x00;
	}
	
	task void set_bit_high() {
		uint8_t i;
		for (i=0;i<=7;i++) {
			if testbit(bitmap,i) {
				setbit(i2c_data,i);
			}
		}
		bitmap = 0x00;
	}
	
	task void set_bit_toggle() {
		uint8_t i;
		for (i=0;i<=7;i++) {
			if testbit(bitmap,i) {
				if testbit (i2c_data,i) {
					clrbit(i2c_data,i);
				} else {
					setbit(i2c_data,i);
				}
			}
		}
		bitmap = 0x00;
	}

	event void DigOutput.readyToSet(){
// 		call Leds.led0Toggle();
	}
	
	
}
