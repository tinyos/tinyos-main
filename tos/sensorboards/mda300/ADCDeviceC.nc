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
* Wiring for ADCDeviceC component.
* 
* @author Charles Elliott
* @modified Feb 27, 2009
*/

#include "mda300.h"

configuration ADCDeviceC
{ 
  provides interface Read<uint16_t> as Channel0;
  provides interface Read<uint16_t> as Channel1;
  provides interface Read<uint16_t> as Channel2;
  provides interface Read<uint16_t> as Channel3;
  provides interface Read<uint16_t> as Channel4;
  provides interface Read<uint16_t> as Channel5;
  provides interface Read<uint16_t> as Channel6;
  provides interface Read<uint16_t> as Channel7;
  provides interface Read<uint16_t> as Channel01;
  provides interface Read<uint16_t> as Channel23;
  provides interface Read<uint16_t> as Channel45;
  provides interface Read<uint16_t> as Channel67;
  provides interface Read<uint16_t> as Channel10;
  provides interface Read<uint16_t> as Channel32;
  provides interface Read<uint16_t> as Channel54;
  provides interface Read<uint16_t> as Channel76;
}
implementation
{
  components    
    new ADCControlP() as ADCControl, MDA3XXADCC, 
   	new TimerMilliC()as CoolDown, LedsC, NoLedsC,
    BusyWaitMicroC;
 
  ADCControl.MDA300ADC -> MDA3XXADCC;  
  ADCControl.CoolDown -> CoolDown;
  ADCControl.Leds -> LedsC.Leds;
  ADCControl.BusyWait -> BusyWaitMicroC;  
  Channel0 = ADCControl.Channel0;
  Channel1 = ADCControl.Channel1;
  Channel2 = ADCControl.Channel2;
  Channel3 = ADCControl.Channel3;
  Channel4 = ADCControl.Channel4;
  Channel5 = ADCControl.Channel5;
  Channel6 = ADCControl.Channel6;
  Channel7 = ADCControl.Channel7;
  Channel01 = ADCControl.Channel01;
  Channel23 = ADCControl.Channel23;
  Channel45 = ADCControl.Channel45;
  Channel67 = ADCControl.Channel67;
  Channel10 = ADCControl.Channel10;
  Channel32 = ADCControl.Channel32;
  Channel54 = ADCControl.Channel54;
  Channel76 = ADCControl.Channel76;  
}
