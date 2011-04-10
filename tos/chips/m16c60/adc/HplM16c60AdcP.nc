/// $Id: HplM16c60AdcP.nc,v 1.3 2010-06-29 22:07:45 scipio Exp $
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

#include "M16c60Adc.h"

/**
 * HPL for the M16c60 A/D conversion susbsystem.
 *
 * @author Fan Zhang <fanzha@ltu.se>
 *
 */

module HplM16c60AdcP
{
  provides interface HplM16c60Adc;
  uses interface McuPowerState;
  
#ifdef THREADS
  uses interface PlatformInterrupt;
#define POST_AMBLE() call PlatformInterrupt.postAmble()
#else 
#define POST_AMBLE()
#endif 
}
implementation
{
  //=== Direct read of HW registers. =================================
  async command M16c60ADCON0_t HplM16c60Adc.getADCON0() { 
    return *(M16c60ADCON0_t*)&ADCON0; 
  }
  async command M16c60ADCON1_t HplM16c60Adc.getADCON1() { 
    return *(M16c60ADCON1_t*)&ADCON1; 
  }
  async command M16c60ADCON2_t HplM16c60Adc.getADCON2() { 
    return *(M16c60ADCON2_t*)&ADCON2; 
  }
  async command uint16_t HplM16c60Adc.getValue() { 
    uint8_t channel = ADCON0.BYTE&0x07;
    if(channel==0x00){return AD0.WORD;}
    else if(channel==0x01){return AD1.WORD;}
    else if(channel==0x02){return AD2.WORD;}
    else if(channel==0x03){return AD3.WORD;}
    else if(channel==0x04){return AD4.WORD;}
    else if(channel==0x05){return AD5.WORD;}
    else if(channel==0x06){return AD6.WORD;}
    else {return AD7.WORD;}
     
  }

  DEFINE_UNION_CAST(ADCON02int, M16c60ADCON0_t, uint8_t); // type change from M16c60ADCON0_t to uint8_t
  DEFINE_UNION_CAST(ADCON12int, M16c60ADCON1_t, uint8_t);
  DEFINE_UNION_CAST(ADCON22int, M16c60ADCON2_t, uint8_t);

  //=== Direct write of HW registers. ================================
  async command void HplM16c60Adc.setADCON0( M16c60ADCON0_t x ) { 
    ADCON0.BYTE = ADCON02int(x); 
  }
  async command void HplM16c60Adc.setADCON1( M16c60ADCON1_t x ) { 
    ADCON1.BYTE = ADCON12int(x); 
  }
  async command void HplM16c60Adc.setADCON2( M16c60ADCON2_t x ) { 
    ADCON2.BYTE = ADCON22int(x); 
  }
  /* write the precision bit in the ADCON1 register, not supported on all models */ 
  async command void HplM16c60Adc.setPrecision(uint8_t precision){
    WRITE_BIT(ADCON1.BYTE, 3, precision);
  }
  /* Set ADC prescaler selection bits */
  async command void HplM16c60Adc.setPrescaler(uint8_t scale){
    
    if(scale == 0x00){ADCON2.BIT.CKS2=0;ADCON1.BIT.CKS1=0;ADCON0.BIT.CKS0=0;} // fAD/4 prescaler
    else if(scale == 0x01){ADCON2.BIT.CKS2=0;ADCON1.BIT.CKS1=0;ADCON0.BIT.CKS0=1;} // fAD/2 prescaler
    else if((scale == 0x02) || (scale == 0x03)){ADCON2.BIT.CKS2=0;ADCON1.BIT.CKS1=1;ADCON0.BIT.CKS0=0;} // fAD prescaler
    else if(scale == 0x04){ADCON2.BIT.CKS2=1;ADCON1.BIT.CKS1=0;ADCON0.BIT.CKS0=0;} // fAD/12 prescaler
    else if(scale == 0x05){ADCON2.BIT.CKS2=1;ADCON1.BIT.CKS1=0;ADCON0.BIT.CKS0=1;} // fAD/6 prescaler
    else if((scale == 0x06) || (scale == 0x07)){ADCON2.BIT.CKS2=1;ADCON1.BIT.CKS1=1;ADCON0.BIT.CKS0=0;} // fAD/3 prescaler
    
  }

  // Individual bit manipulation. These all clear any pending A/D interrupt.
  async command void HplM16c60Adc.enableAdc() {
    SET_BIT(ADCON1.BYTE, 5); 
    call McuPowerState.update();
  }
  async command void HplM16c60Adc.disableAdc() {
    CLR_BIT(ADCON1.BYTE, 5); 
    call McuPowerState.update();
  }
  // A/D conversion interrupt control register is ADIC 2009-2-9 by Fan Zhang
  async command void HplM16c60Adc.enableInterruption() { ADIC.BIT.ILVL2=0;ADIC.BIT.ILVL1=0;ADIC.BIT.ILVL0=1; }
  async command void HplM16c60Adc.disableInterruption() { ADIC.BIT.ILVL2=0;ADIC.BIT.ILVL1=0;ADIC.BIT.ILVL0=0; }
  async command void HplM16c60Adc.startConversion() { ADCON0.BIT.ADST=1; } // ADST=6
  async command void HplM16c60Adc.resetInterrupt() { } // Clear the ADC interrupt flag
  /**
   * Enable continuous sampling, that is repeat sampling mode
   */
  async command void HplM16c60Adc.setContinuous() {  ADCON0.BIT.MD0=0;ADCON0.BIT.MD1=1;  }
  /**
   * Disable continuous sampling, enable one-shot sampling mode
   */
  async command void HplM16c60Adc.setSingle() { ADCON0.BIT.MD0=0;ADCON0.BIT.MD1=0; }
  
  /* A/D status checks */
  async command bool HplM16c60Adc.isEnabled(){       
    // ADCON1 bit 5 controls the ADC, 0 disable connection, 1 connection
    return READ_BIT(ADCON1.BYTE, 5); 
  }

  async command bool HplM16c60Adc.isStarted() {
    return ADCON0.BIT.ADST; 
  }
  
  async command bool HplM16c60Adc.isComplete() {
    // interrupt flag bit
    return ADIC.BIT.IR; 
  }
  
  
  /* A/D interrupt handlers. Signals dataReady event with interrupts enabled */
  default async event void HplM16c60Adc.dataReady(uint16_t done) { }
  M16C_INTERRUPT_HANDLER(M16C_AD)
  {
    uint16_t data = call HplM16c60Adc.getValue();
    
    __nesc_enable_interrupt();
    signal HplM16c60Adc.dataReady(data);
    POST_AMBLE();
  }

  async command bool HplM16c60Adc.cancel() { 
    /* This is tricky */
    atomic
    {
	    /* To cancel a conversion, first turn off ADEN, then turn off
	       ADSC. We also cancel any pending interrupt.
	       Finally we reenable the ADC.
	    */
	    //ADCON1.VCUT=0;
	    //ADIC.ILVL2=0;ADIC.ILVL1=0;ADIC.ILVL0=0; /* This disable ADC interrupt... */
	    ADCON0.BIT.ADST=0;
	    //ADCON1.VCUT=1;
	    return TRUE;
     }
  }
}
