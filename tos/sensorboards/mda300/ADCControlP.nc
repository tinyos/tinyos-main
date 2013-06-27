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
*  ADCControlP module converts MDA300ADC commands into Read
*  @author Charles Elliott UOIT 
*  @modified May 2009
*  @modified September 2012 by Franco Di Persio, Sestosenso
*/

generic module ADCControlP()
{
  provides {
	interface Read<uint16_t> as Channel0;
	interface Read<uint16_t> as Channel1;
	interface Read<uint16_t> as Channel2;
	interface Read<uint16_t> as Channel3;
  	interface Read<uint16_t> as Channel4;
	interface Read<uint16_t> as Channel5;
	interface Read<uint16_t> as Channel6;
	interface Read<uint16_t> as Channel7;
	interface Read<uint16_t> as Channel01;
	interface Read<uint16_t> as Channel23;
	interface Read<uint16_t> as Channel45;
	interface Read<uint16_t> as Channel67;
	interface Read<uint16_t> as Channel10;
	interface Read<uint16_t> as Channel32;
	interface Read<uint16_t> as Channel54;
	interface Read<uint16_t> as Channel76;
  }
  uses {    
	interface MDA300ADC;
	interface BusyWait<TMicro,uint16_t>;	
	interface Timer<TMilli> as CoolDown;
	interface Leds;
  }
}
implementation
{
	error_t reply;
	bool shutdown = FALSE; 
	bool cold = TRUE;
		
	void notCoolDown (){
		shutdown = FALSE;
		if (call CoolDown.isRunning())
			call CoolDown.stop();
	}
	
	error_t selectPin(uint8_t channel){
		error_t error;
		uint16_t e = 1240;
		uint8_t i;		
		notCoolDown(); 		
		if (cold == TRUE){
			error = call MDA300ADC.selectPin(channel);
			if (error != SUCCESS){
				return error;
			}
			//for (i = 0; i<32; i++){
				call BusyWait.wait(e);
			//}
			cold = FALSE;	   			     	
	     }
	     error = call MDA300ADC.selectPin(channel);    
	    return error;
    } 
  
  command error_t Channel0.read() {
// 	call Leds.led0Toggle();	
	return selectPin(0x8F);	
  }
  
  command error_t Channel1.read() {	 
    return selectPin(0xCF);
  }
  
  command error_t Channel2.read() {	
    return selectPin(0x9F);
  }
  
  command error_t Channel3.read() {	
    return selectPin(0xDF);
  }
  
  command error_t Channel4.read() {	
    return selectPin(0xAF);
  }
  
  command error_t Channel5.read() {	
    return selectPin(0xEF);
  }
  
  command error_t Channel6.read() {	
    return selectPin(0xBF);
  }
  
  command error_t Channel7.read() {	
    return selectPin(0xFF);
  }
  
  command error_t Channel01.read() {	
    return selectPin(0x0F);
  }
  
  command error_t Channel23.read() {	
    return selectPin(0x1F);
  }
  
  command error_t Channel45.read() {	
    return selectPin(0x2F);
  }
  
  command error_t Channel67.read() {	
    return selectPin(0x3F);
  }
  
  command error_t Channel10.read() {	
    return selectPin(0x4F);
  }
  
  command error_t Channel32.read() {	
    return selectPin(0x5F);
  }
  
  command error_t Channel54.read() {	
    return selectPin(0x6F);
  }
  
  command error_t Channel76.read() {	
     return selectPin(0x7F);
  }
  
  
  
  task void requestRead(){
	if (call MDA300ADC.requestRead() != SUCCESS)
		post requestRead();
  }

  event void MDA300ADC.readyToSet(){
  	if (cold == FALSE)
  		post requestRead();  	
	}  
   	
   	task void ReadReady (){   				
	uint16_t val= call MDA300ADC.read();
	uint8_t channel= call MDA300ADC.get();
	
	if (call CoolDown.isRunning()){
			call CoolDown.stop();
		}	
	
	if (channel >= 0xF0){
			signal Channel7.readDone(SUCCESS, val);
	}else if (channel >= 0xE0){
			signal Channel5.readDone(SUCCESS, val);
	}else if (channel >= 0xD0){
			signal Channel3.readDone(SUCCESS, val);
	}else if (channel >= 0xC0){
			signal Channel1.readDone(SUCCESS, val);
	}else if (channel >= 0xB0){
			signal Channel6.readDone(SUCCESS, val);
	}else if (channel >= 0xA0){
			signal Channel4.readDone(SUCCESS, val);
	}else if (channel >= 0x90){
			signal Channel2.readDone(SUCCESS, val);
	}else if (channel >= 0x80){
			signal Channel0.readDone(SUCCESS, val);
	}else if (channel >= 0x70){
			signal Channel76.readDone(SUCCESS, val);
	}else if (channel >= 0x60){
			signal Channel54.readDone(SUCCESS, val);
	}else if (channel >= 0x50){
			signal Channel32.readDone(SUCCESS, val);
	}else if (channel >= 0x40){
			signal Channel10.readDone(SUCCESS, val);
	}else if (channel >= 0x30){
			signal Channel67.readDone(SUCCESS, val);
	}else if (channel >= 0x20){
			signal Channel45.readDone(SUCCESS, val);
	}else if (channel >= 0x10){
			signal Channel23.readDone(SUCCESS, val);
	}else if (channel < 0x10){ 
			shutdown = TRUE;
			cold = TRUE;
	}
	if (!shutdown){
// 		call CoolDown.startOneShot(4096); 		//to be checked the effectiveness
		}	  		
   	}  	
  
  event void MDA300ADC.readyToRead (){
  	post ReadReady();	
  }
    
  event void CoolDown.fired(){
   	call MDA300ADC.selectPin(0x00);
   }
   

  default event void Channel0.readDone(error_t result, uint16_t val) { }
  default event void Channel1.readDone(error_t result, uint16_t val) { }
  default event void Channel2.readDone(error_t result, uint16_t val) { }
  default event void Channel3.readDone(error_t result, uint16_t val) { }
  default event void Channel4.readDone(error_t result, uint16_t val) { }
  default event void Channel5.readDone(error_t result, uint16_t val) { }
  default event void Channel6.readDone(error_t result, uint16_t val) { }
  default event void Channel7.readDone(error_t result, uint16_t val) { }
  default event void Channel01.readDone(error_t result, uint16_t val) { }
  default event void Channel23.readDone(error_t result, uint16_t val) { }
  default event void Channel45.readDone(error_t result, uint16_t val) { }
  default event void Channel67.readDone(error_t result, uint16_t val) { }
  default event void Channel10.readDone(error_t result, uint16_t val) { }
  default event void Channel32.readDone(error_t result, uint16_t val) { }
  default event void Channel54.readDone(error_t result, uint16_t val) { }
  default event void Channel76.readDone(error_t result, uint16_t val) { }    
}
