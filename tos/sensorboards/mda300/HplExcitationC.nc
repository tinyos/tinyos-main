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

/**
 * HplExcitationC is a low-level component, intended to provide
 * the physical resources used for turning on and off the
 * Excitation 25, 33 and 50 on the MDA300ca.
 *
 * @author Franco Di Persio, Sestosenso
 * @modified September 2012

 */

 
configuration HplExcitationC {
  	provides {
	  	interface Power as Excitacion_25;
		interface Power as Excitacion_33;
		interface Power as Excitacion_50;
		interface SplitControl as ExcitationControl;
	}
}
implementation {
	components new ExcitationLogicP(), MicaBusC;
  
	Excitacion_25 = ExcitationLogicP.Excitacion_25;
	Excitacion_33 = ExcitationLogicP.Excitacion_33;
	Excitacion_50 = ExcitationLogicP.Excitacion_50;
	ExcitationControl = ExcitationLogicP.ExcitationControl;
	
	ExcitationLogicP.CounterPin -> MicaBusC.PW4;
  	ExcitationLogicP.VOLTAGE_BOOSTER -> MicaBusC.PW1;
  	ExcitationLogicP.VOLTAGE_BUFFER -> MicaBusC.PW2;
 	ExcitationLogicP.THREE_VOLT -> MicaBusC.PW3;
  	ExcitationLogicP.FIVE_VOLT -> MicaBusC.PW5;
  	ExcitationLogicP.AMPLIFIERS -> MicaBusC.PW6;
  	ExcitationLogicP.ExenablePin -> MicaBusC.PW7;
  	  	  	
}
