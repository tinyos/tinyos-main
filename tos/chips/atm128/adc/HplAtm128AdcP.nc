/// $Id: HplAtm128AdcP.nc,v 1.3 2006-11-07 00:33:30 scipio Exp $
/*
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. 
 *
 * CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS 
 * ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS ANY 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
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
  // It's not clear these are that useful...
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
