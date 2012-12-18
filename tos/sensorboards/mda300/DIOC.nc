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
* Wiring for DIOC component.
* 
* @author Charles Elliott
* @modified Feb 27, 2009
*  
*  @modified September 2012 by Franco Di Persio, Sestosenso
*/


generic configuration DIOC() {
  provides interface Read<uint8_t> as Read_DIO;
  provides interface Read<uint8_t> as DigChannel_0;
  provides interface Read<uint8_t> as DigChannel_1;
  provides interface Read<uint8_t> as DigChannel_2;
  provides interface Read<uint8_t> as DigChannel_3;
  provides interface Read<uint8_t> as DigChannel_4;
  provides interface Read<uint8_t> as DigChannel_5;
  
  provides interface Relay as Relay_NC;
  provides interface Relay as Relay_NO;
  
  provides interface Notify<bool>;
}
implementation { 
components DIOP, MDA3XXDigOutputC, LedsC;

  Read_DIO 		= DIOP.Read_DIO;
  DigChannel_0 	= DIOP.DigChannel_0;
  DigChannel_1 	= DIOP.DigChannel_1;
  DigChannel_2 	= DIOP.DigChannel_2;
  DigChannel_3 	= DIOP.DigChannel_3;
  DigChannel_4 	= DIOP.DigChannel_4;
  DigChannel_5 	= DIOP.DigChannel_5;
  
  Relay_NC = DIOP.Relay_NC;
  Relay_NO = DIOP.Relay_NO;
  
  DIOP.Leds -> LedsC.Leds;
  
  DIOP.DigOutput -> MDA3XXDigOutputC;
  
  Notify = MDA3XXDigOutputC;	//add to activate the interrupt: May 22, 2012 
}
