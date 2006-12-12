/*
 * Copyright (c) 2006, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.4 $
 * $Date: 2006-12-12 18:23:07 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#include <Msp430Adc12.h> 
configuration Msp430Adc12P 
{ 
  provides {
    interface Resource[uint8_t id]; 
    interface Msp430Adc12SingleChannel as SingleChannel[uint8_t id]; 
    interface Msp430Adc12MultiChannel as MultiChannel[uint8_t id]; 
    interface Msp430Adc12Overflow as Overflow[uint8_t id]; 
    interface AsyncStdControl as DMAExtension[uint8_t id];
  }
} implementation { 
  components Msp430Adc12ImplP, HplAdc12P, Msp430TimerC, MainC, HplMsp430GeneralIOC, 
             new SimpleRoundRobinArbiterC(MSP430ADC12_RESOURCE) as Arbiter;

  Resource = Arbiter;
  SingleChannel = Msp430Adc12ImplP.SingleChannel;
  MultiChannel= Msp430Adc12ImplP.MultiChannel;
  Overflow = Msp430Adc12ImplP.Overflow;
  DMAExtension = Msp430Adc12ImplP.DMAExtension;
  
  Msp430Adc12ImplP.Init <- MainC;
  Msp430Adc12ImplP.ADCArbiterInfo -> Arbiter;
  Msp430Adc12ImplP.HplAdc12 -> HplAdc12P;
  Msp430Adc12ImplP.Port60 -> HplMsp430GeneralIOC.Port60;
  Msp430Adc12ImplP.Port61 -> HplMsp430GeneralIOC.Port61;
  Msp430Adc12ImplP.Port62 -> HplMsp430GeneralIOC.Port62;
  Msp430Adc12ImplP.Port63 -> HplMsp430GeneralIOC.Port63;
  Msp430Adc12ImplP.Port64 -> HplMsp430GeneralIOC.Port64;
  Msp430Adc12ImplP.Port65 -> HplMsp430GeneralIOC.Port65;
  Msp430Adc12ImplP.Port66 -> HplMsp430GeneralIOC.Port66;
  Msp430Adc12ImplP.Port67 -> HplMsp430GeneralIOC.Port67;

  Msp430Adc12ImplP.TimerA -> Msp430TimerC.TimerA;
  Msp430Adc12ImplP.ControlA0 -> Msp430TimerC.ControlA0;
  Msp430Adc12ImplP.ControlA1 -> Msp430TimerC.ControlA1;
  Msp430Adc12ImplP.CompareA0 -> Msp430TimerC.CompareA0;
  Msp430Adc12ImplP.CompareA1 -> Msp430TimerC.CompareA1;
}

