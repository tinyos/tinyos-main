/// $Id: HplAtm128AdcP.nc,v 1.2 2010-06-29 22:07:51 scipio Exp $
/*
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of Crossbow Technology nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "Atm128Adc.h"

/**
 * HPL for the Atmega128 A/D conversion susbsystem.
 *
 * @author Martin Turon <mturon@xbow.com>
 * @author Hu Siquan <husq@xbow.com>
 * @author David Gay
 */

module HplAtm128AdcP {
  provides interface HplAtm128Adc;
  uses interface McuPowerState;
  uses interface PlatformInterrupt;
}
implementation {
  //=== Direct read of HW registers. =================================
  async command Atm128Admux_t HplAtm128Adc.getAdmux() { 
    return *(Atm128Admux_t*)&ADMUX; 
  }
  async command Atm128Adcsra_t HplAtm128Adc.getAdcsra() { 
    return *(Atm128Adcsra_t*)&ADCSRA; 
  }
  async command uint16_t HplAtm128Adc.getValue() { 
    return ADC; 
  }

  DEFINE_UNION_CAST(Admux2int, Atm128Admux_t, uint8_t);
  DEFINE_UNION_CAST(Adcsra2int, Atm128Adcsra_t, uint8_t);

  //=== Direct write of HW registers. ================================
  async command void HplAtm128Adc.setAdmux( Atm128Admux_t x ) { 
    ADMUX = Admux2int(x); 
  }
  async command void HplAtm128Adc.setAdcsra( Atm128Adcsra_t x ) { 
    ADCSRA = Adcsra2int(x); 
  }

  async command void HplAtm128Adc.setPrescaler(uint8_t scale){
    Atm128Adcsra_t  current_val = call HplAtm128Adc.getAdcsra(); 
    current_val.adif = FALSE;
    current_val.adps = scale;
    call HplAtm128Adc.setAdcsra(current_val);
  }

  // Individual bit manipulation. These all clear any pending A/D interrupt.
  async command void HplAtm128Adc.enableAdc() {
    SET_BIT(ADCSRA, ADEN); 
    call McuPowerState.update();
  }
  async command void HplAtm128Adc.disableAdc() {
    CLR_BIT(ADCSRA, ADEN); 
    call McuPowerState.update();
  }
  async command void HplAtm128Adc.enableInterruption() { SET_BIT(ADCSRA, ADIE); }
  async command void HplAtm128Adc.disableInterruption() { CLR_BIT(ADCSRA, ADIE); }
  async command void HplAtm128Adc.setContinuous() { SET_BIT(ADCSRA, ADFR); }
  async command void HplAtm128Adc.setSingle() { CLR_BIT(ADCSRA, ADFR); }
  async command void HplAtm128Adc.resetInterrupt() { SET_BIT(ADCSRA, ADIF); }
  async command void HplAtm128Adc.startConversion() { SET_BIT(ADCSRA, ADSC); }


  /* A/D status checks */
  async command bool HplAtm128Adc.isEnabled()     {       
    return (call HplAtm128Adc.getAdcsra()).aden; 
  }

  async command bool HplAtm128Adc.isStarted()     {
    return (call HplAtm128Adc.getAdcsra()).adsc; 
  }
  
  async command bool HplAtm128Adc.isComplete()    {
    return (call HplAtm128Adc.getAdcsra()).adif; 
  }

  /* A/D interrupt handlers. Signals dataReady event with interrupts enabled */
  AVR_ATOMIC_HANDLER(SIG_ADC) {
    uint16_t data = call HplAtm128Adc.getValue();
    
    __nesc_enable_interrupt();
    signal HplAtm128Adc.dataReady(data);
    call PlatformInterrupt.postAmble();
  }

  default async event void HplAtm128Adc.dataReady(uint16_t done) { }

  async command bool HplAtm128Adc.cancel() { 
    /* This is tricky */
    atomic
      {
	Atm128Adcsra_t oldSr = call HplAtm128Adc.getAdcsra(), newSr;

	/* To cancel a conversion, first turn off ADEN, then turn off
	   ADSC. We also cancel any pending interrupt.
	   Finally we reenable the ADC.
	*/
	newSr = oldSr;
	newSr.aden = FALSE;
	newSr.adif = TRUE; /* This clears a pending interrupt... */
	newSr.adie = FALSE; /* We don't want to start sampling again at the
			       next sleep */
	call HplAtm128Adc.setAdcsra(newSr);
	newSr.adsc = FALSE;
	call HplAtm128Adc.setAdcsra(newSr);
	newSr.aden = TRUE;
	call HplAtm128Adc.setAdcsra(newSr);

	return oldSr.adif || oldSr.adsc;
      }
  }
}
