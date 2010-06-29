/* $Id: M16c62pAdcP.nc,v 1.2 2010-06-29 22:07:45 scipio Exp $
 * Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
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
 * - Neither the name of the University of California nor the names of
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
 *
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 *
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

#include "M16c62pAdc.h"

/**
 * Internal component of the M16c62p A/D HAL.
 *
 * @author Fan Zhang
 */

module M16c62pAdcP
{
  provides {
    interface Init;
    interface AsyncStdControl;
    interface M16c62pAdcSingle;
    interface M16c62pAdcMultiple;
  }
  uses {
    interface HplM16c62pAdc;
    //interface M16c62pCalibrate;
  }
}
implementation
{  
  /* type change from uint8_t to M16c62pADCON0_t, this function is defined at m16c62phardware.h */
  DEFINE_UNION_CAST(int2ADCON0, uint8_t, M16c62pADCON0_t); // 
  DEFINE_UNION_CAST(int2ADCON1, uint8_t, M16c62pADCON1_t);
  DEFINE_UNION_CAST(int2ADCON2, uint8_t, M16c62pADCON2_t);
  command error_t Init.init() {
    atomic
    {
	    M16c62pADCON0_t adcon_0;
	    M16c62pADCON1_t adcon_1;
	    M16c62pADCON2_t adcon_2;

	    adcon_0 = int2ADCON0(0x00);
	    adcon_0 = int2ADCON0(0x20);
	    adcon_0 = int2ADCON0(0x01); 
	
	    call HplM16c62pAdc.setADCON0(adcon_0);
        call HplM16c62pAdc.setADCON1(adcon_1);
        call HplM16c62pAdc.setADCON2(adcon_2);
    }
    return SUCCESS;
  }

  /* We enable the A/D when start is called, and disable it when stop is
     called. This drops A/D conversion latency by a factor of two (but
     increases idle mode power consumption a little). 
  */
  async command error_t AsyncStdControl.start() {
    atomic call HplM16c62pAdc.enableAdc();
    return SUCCESS;
  }

  async command error_t AsyncStdControl.stop() {
    atomic call HplM16c62pAdc.disableAdc();

    return SUCCESS;
  }

  /* Return TRUE if switching to 'channel' with reference voltage 'refVoltage'
     will give a precise result (the first sample after changing reference
     voltage or switching to/between a differential channel is imprecise)
  */
  inline bool isPrecise(uint8_t admux, uint8_t channel, uint8_t refVoltage) {
    return TRUE;
  }
  
  /**
   * Indicates a sample has been recorded by the ADC as the result
   * of a ADC interrupt.
   *
   * @param data a 2 byte unsigned data value sampled by the ADC.
   * @param precise if the conversion precise, FALSE if it wasn't. 
   */	
  async event void HplM16c62pAdc.dataReady(uint16_t data) {
    
    /* A single sample. Disable the ADC interrupt to avoid starting
	   a new sample at the next "sleep" instruction. */
	call HplM16c62pAdc.disableInterruption();
	call HplM16c62pAdc.disableAdc(); 
	signal M16c62pAdcSingle.dataReady(data, TRUE);
	
  }

  /* Start sampling based on request parameters 
   * one-shot mode default
   * refVoltage default
   */
  void getData(uint8_t channel,uint8_t precision, uint8_t prescaler) {
    M16c62pADCON0_t adcon0_t;
    M16c62pADCON1_t adcon1_t;
    M16c62pADCON2_t adcon2_t;

    if(channel < M16c62p_ADC_CHL_AN10)
    {
        adcon2_t.adgsel01 = 0;
    }
    else if((channel > M16c62p_ADC_CHL_AN7) && (channel <= M16c62p_ADC_CHL_AN17))
    {
        adcon2_t.adgsel01 = 2;
        channel=channel-8;
    }
    adcon0_t.ch012 = channel;
    
    adcon0_t.md01 = 0;
    adcon0_t.trg = 0;
    adcon0_t.adst = M16c62p_ADC_START_CONVERSION_ON;
    
    adcon1_t.md2 = 0;
    if(precision == M16c62p_ADC_PRECISION_10BIT)     // 10-bit mode
    {
        adcon1_t.bits = 1;
    }
    else
    {
        adcon1_t.bits = 0;
    }
    adcon1_t.vcut = M16c62p_ADC_ENABLE_ON;
    adcon1_t.opa01 = 0;
    
    adcon2_t.smp = 1; // sample and hold
    
    if(prescaler == 0x00){adcon2_t.cks2=0;adcon1_t.cks1=0;adcon0_t.cks0=0;} // fAD/4 prescaler
    else if(prescaler == 0x01){adcon2_t.cks2=0;adcon1_t.cks1=0;adcon0_t.cks0=1;} // fAD/2 prescaler
    else if((prescaler == 0x02) || (prescaler == 0x03)){adcon2_t.cks2=0;adcon1_t.cks1=1;adcon0_t.cks0=0;} // fAD prescaler
    else if(prescaler == 0x04){adcon2_t.cks2=1;adcon1_t.cks1=0;adcon0_t.cks0=0;} // fAD/12 prescaler
    else if(prescaler == 0x05){adcon2_t.cks2=1;adcon1_t.cks1=0;adcon0_t.cks0=1;} // fAD/6 prescaler
    else if((prescaler == 0x06) || (prescaler == 0x07)){adcon2_t.cks2=1;adcon1_t.cks1=1;adcon0_t.cks0=0;} // fAD/3 prescaler

    call HplM16c62pAdc.enableInterruption();
    
    call HplM16c62pAdc.setADCON2(adcon2_t);
    call HplM16c62pAdc.setADCON1(adcon1_t);
    call HplM16c62pAdc.setADCON0(adcon0_t);
  }

  async command bool M16c62pAdcSingle.getData(uint8_t channel,
					     uint8_t precision, uint8_t prescaler) {
    atomic
    {
		getData(channel, precision, prescaler);
		return TRUE;
    }
  }

  async command bool M16c62pAdcSingle.cancel() 
  {
    /* There is no M16c62pAdcMultiple.cancel, for reasons discussed in that
       interface */
    return call HplM16c62pAdc.cancel();
  }

  async command bool M16c62pAdcMultiple.getData(uint8_t channel, uint8_t precision, uint8_t prescaler)
  {
    atomic
    {
		getData(channel, precision, prescaler);

		return TRUE;
      }
  }

  default async event void M16c62pAdcSingle.dataReady(uint16_t data, bool precise) {
  }

  default async event bool M16c62pAdcMultiple.dataReady(uint16_t data, bool precise, uint8_t channel,
						       uint8_t *newChannel, uint8_t *newRefVoltage) {
    return FALSE; // stop conversion if we somehow end up here.
  }
}
