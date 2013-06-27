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
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

#include "Timer.h"

/**
 * ExcitationLogicP contains the actual driver logic needed to
 * turn on and off the Excitation 25, 33 and 50 on the MDA300ca.
 *
 * @author Franco Di Persio, Sestosenso
 * @modified September 2012
 */

generic module ExcitationLogicP() {
  provides interface Power as Excitacion_25;
  provides interface Power as Excitacion_33;
  provides interface Power as Excitacion_50;
  provides interface SplitControl as ExcitationControl;;
  
  uses {
	interface GeneralIO as CounterPin;
	interface GeneralIO as ExenablePin;
	interface GeneralIO as VOLTAGE_BOOSTER;
	interface GeneralIO as VOLTAGE_BUFFER;
	interface GeneralIO as THREE_VOLT;
	interface GeneralIO as FIVE_VOLT;
	interface GeneralIO as AMPLIFIERS;
		
	}
}
implementation {

  	
  command error_t ExcitationControl.start() {
    	atomic {
//       		call CounterPin.makeOutput();
//       		call AMPLIFIERS.makeOutput();
      		call VOLTAGE_BOOSTER.makeOutput();
      		call VOLTAGE_BUFFER.makeOutput();
//       		call ExenablePin.makeOutput();
      		call FIVE_VOLT.makeOutput();
      		call THREE_VOLT.makeOutput();
//       		call AMPLIFIERS.clr();
      		call VOLTAGE_BOOSTER.set();
      		call VOLTAGE_BUFFER.clr();
      		call THREE_VOLT.clr();
      		call FIVE_VOLT.clr();
      		
   			signal ExcitationControl.startDone( SUCCESS );

    	}
    return SUCCESS;
  }
  
    command error_t ExcitationControl.stop() {
    	atomic {
//       		call CounterPin.makeOutput();
//       		call AMPLIFIERS.makeOutput();
      		call VOLTAGE_BOOSTER.makeOutput();
      		call VOLTAGE_BUFFER.makeOutput();
//       		call ExenablePin.makeOutput();
      		call FIVE_VOLT.makeOutput();
      		call THREE_VOLT.makeOutput();
//       		call AMPLIFIERS.clr();
      		call VOLTAGE_BOOSTER.set();
      		call VOLTAGE_BUFFER.clr();
      		call THREE_VOLT.clr();
      		call FIVE_VOLT.clr();
      		
      		signal ExcitationControl.stopDone( SUCCESS );

    	}
    return SUCCESS;
  }


  void Excitation_Control_25(bool Status){
	  if(Status){
		  atomic {
			  call VOLTAGE_BOOSTER.makeOutput();
			  call VOLTAGE_BUFFER.makeOutput();
			  call VOLTAGE_BOOSTER.clr();
			  call VOLTAGE_BUFFER.set();
			  signal Excitacion_25.ExctDone( SUCCESS );
		  }
	} else {
		atomic {
			call VOLTAGE_BOOSTER.set();
			call VOLTAGE_BUFFER.clr();
		}
	}
  }
  
  void Excitation_Control_33(bool Status){
	  if(Status){
		  atomic {
// 			  call VOLTAGE_BUFFER.makeOutput();
			  call VOLTAGE_BOOSTER.makeOutput();
			  call THREE_VOLT.makeOutput();
			  call VOLTAGE_BOOSTER.clr();
// 			  call VOLTAGE_BUFFER.set();
			  call THREE_VOLT.set();
			  signal Excitacion_33.ExctDone( SUCCESS );
		  }
	} else {
		atomic {
			call VOLTAGE_BOOSTER.set();
			call THREE_VOLT.clr();
		}
	}
  }
  
  void Excitation_Control_50(bool Status){
	  if(Status){
		  atomic {
// 			  call ExenablePin.makeOutput();
// 			  call VOLTAGE_BUFFER.makeOutput();
			  call VOLTAGE_BOOSTER.makeOutput();
			  call FIVE_VOLT.makeOutput();
// 			  call ExenablePin.set();
			  call VOLTAGE_BOOSTER.clr();
// 			  call VOLTAGE_BUFFER.set();
			  call FIVE_VOLT.set();
// 			  post Excit50Task();
		  }
		  signal Excitacion_50.ExctDone( SUCCESS );
	} else {
		atomic {
			call VOLTAGE_BOOSTER.set();
// 			call VOLTAGE_BUFFER.clr();
			call FIVE_VOLT.clr();
		}
	}
  }
  
  
/*==========================================*/  
  
  command void Excitacion_25.on(){
	  	
	  	Excitation_Control_25(TRUE);
  	}	
  
  command void Excitacion_25.off(){
		
		Excitation_Control_25(FALSE);
  	}
 
/*==========================================*/  	 	

  command void Excitacion_33.on(){
	  	
	  	Excitation_Control_33(TRUE);	
  	}	
  
  command void Excitacion_33.off(){
		
		Excitation_Control_33(FALSE);
  	}

/*==========================================*/   
	
  command void Excitacion_50.on(){
	  	
	  	Excitation_Control_50(TRUE);
  	}	
  
  command void Excitacion_50.off(){
		
		Excitation_Control_50(FALSE);
  	}
  	
/*==========================================*/   

}

