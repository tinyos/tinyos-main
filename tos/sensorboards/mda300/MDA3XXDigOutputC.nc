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
* Wiring for MDA3XXDigOutputC component.
* 
* @author Franco Di Persio, Sestosenso
* @modified September 2012
*/

configuration MDA3XXDigOutputC {
	provides interface DigOutput;
	provides interface Notify<bool>;	//add to activate the interrupt: May 22, 2012
}
implementation {
	
	components new Atm128I2CMasterC() as I2C;
	
	components MDA3XXDigOutputP, LedsC;

	
	DigOutput = MDA3XXDigOutputP.DigOutput;
	Notify = MDA3XXDigOutputP.Notify;		//add to activate the interrupt: May 22, 2012
		
	MDA3XXDigOutputP.I2CPacket -> I2C.I2CPacket;
	MDA3XXDigOutputP.Resource -> I2C.Resource;
	
	
	MDA3XXDigOutputP.Leds -> LedsC.Leds;
		
	components MicaBusC;	// modified
    components new TimerMilliC() as Digital_impuls_Timer;
	MDA3XXDigOutputP.GeneralIO -> MicaBusC.Int0;
	MDA3XXDigOutputP.GpioInterrupt -> MicaBusC.Int0_Interrupt;
	MDA3XXDigOutputP.Digital_impuls_Timer -> Digital_impuls_Timer;
	
}
