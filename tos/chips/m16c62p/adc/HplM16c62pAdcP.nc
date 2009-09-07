/// $Id: HplM16c62pAdcP.nc,v 1.1 2009-09-07 14:12:25 r-studio Exp $
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

#include "M16c62pAdc.h"

/**
 * HPL for the M16c62p A/D conversion susbsystem.
 *
 * @author Fan Zhang <fanzha@ltu.se>
 *
 */

module HplM16c62pAdcP
{
  provides interface HplM16c62pAdc;
  uses interface McuPowerState;
}
implementation
{
  //=== Direct read of HW registers. =================================
  async command M16c62pADCON0_t HplM16c62pAdc.getADCON0() { 
    return *(M16c62pADCON0_t*)&ADCON0; 
  }
  async command M16c62pADCON1_t HplM16c62pAdc.getADCON1() { 
    return *(M16c62pADCON1_t*)&ADCON1; 
  }
  async command M16c62pADCON2_t HplM16c62pAdc.getADCON2() { 
    return *(M16c62pADCON2_t*)&ADCON2; 
  }
  async command uint16_t HplM16c62pAdc.getValue() { 
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

  DEFINE_UNION_CAST(ADCON02int, M16c62pADCON0_t, uint8_t); // type change from M16c62pADCON0_t to uint8_t
  DEFINE_UNION_CAST(ADCON12int, M16c62pADCON1_t, uint8_t);
  DEFINE_UNION_CAST(ADCON22int, M16c62pADCON2_t, uint8_t);

  //=== Direct write of HW registers. ================================
  async command void HplM16c62pAdc.setADCON0( M16c62pADCON0_t x ) { 
    ADCON0.BYTE = ADCON02int(x); 
  }
  async command void HplM16c62pAdc.setADCON1( M16c62pADCON1_t x ) { 
    ADCON1.BYTE = ADCON12int(x); 
  }
  async command void HplM16c62pAdc.setADCON2( M16c62pADCON2_t x ) { 
    ADCON2.BYTE = ADCON22int(x); 
  }
  /* precision = 8 or 10, that means 8bit or 10bit */ 
  async command void HplM16c62pAdc.setPrecision(uint8_t precision){
    if(precision == M16c62p_ADC_PRECISION_8BIT)
      ADCON1.BIT.BITS = 0;    
    else if(precision == M16c62p_ADC_PRECISION_10BIT)
      ADCON1.BIT.BITS = 1;
  }
  /* Set ADC prescaler selection bits */
  async command void HplM16c62pAdc.setPrescaler(uint8_t scale){
    
    if(scale == 0x00){ADCON2.BIT.CKS2=0;ADCON1.BIT.CKS1=0;ADCON0.BIT.CKS0=0;} // fAD/4 prescaler
    else if(scale == 0x01){ADCON2.BIT.CKS2=0;ADCON1.BIT.CKS1=0;ADCON0.BIT.CKS0=1;} // fAD/2 prescaler
    else if((scale == 0x02) || (scale == 0x03)){ADCON2.BIT.CKS2=0;ADCON1.BIT.CKS1=1;ADCON0.BIT.CKS0=0;} // fAD prescaler
    else if(scale == 0x04){ADCON2.BIT.CKS2=1;ADCON1.BIT.CKS1=0;ADCON0.BIT.CKS0=0;} // fAD/12 prescaler
    else if(scale == 0x05){ADCON2.BIT.CKS2=1;ADCON1.BIT.CKS1=0;ADCON0.BIT.CKS0=1;} // fAD/6 prescaler
    else if((scale == 0x06) || (scale == 0x07)){ADCON2.BIT.CKS2=1;ADCON1.BIT.CKS1=1;ADCON0.BIT.CKS0=0;} // fAD/3 prescaler
    
  }

  // Individual bit manipulation. These all clear any pending A/D interrupt.
  async command void HplM16c62pAdc.enableAdc() {
    ADCON1.BIT.VCUT = 1; 
    call McuPowerState.update();
  }
  async command void HplM16c62pAdc.disableAdc() {
    ADCON1.BIT.VCUT = 0; 
    call McuPowerState.update();
  }
  // A/D conversion interrupt control register is ADIC 2009-2-9 by Fan Zhang
  async command void HplM16c62pAdc.enableInterruption() { ADIC.BIT.ILVL2=0;ADIC.BIT.ILVL1=0;ADIC.BIT.ILVL0=1; }
  async command void HplM16c62pAdc.disableInterruption() { ADIC.BIT.ILVL2=0;ADIC.BIT.ILVL1=0;ADIC.BIT.ILVL0=0; }
  async command void HplM16c62pAdc.startConversion() { ADCON0.BIT.ADST=1; } // ADST=6
  async command void HplM16c62pAdc.resetInterrupt() { } // Clear the ADC interrupt flag
  /**
   * Enable continuous sampling, that is repeat sampling mode
   */
  async command void HplM16c62pAdc.setContinuous() {  ADCON0.BIT.MD0=0;ADCON0.BIT.MD1=1;  }
  /**
   * Disable continuous sampling, enable one-shot sampling mode
   */
  async command void HplM16c62pAdc.setSingle() { ADCON0.BIT.MD0=0;ADCON0.BIT.MD1=0; }
  
  /* A/D status checks */
  async command bool HplM16c62pAdc.isEnabled(){       
    // ADCON1.VCUT control the Vref connection, 0 disable connection, 1 connection
    return ADCON1.BIT.VCUT; 
  }

  async command bool HplM16c62pAdc.isStarted() {
    return ADCON0.BIT.ADST; 
  }
  
  async command bool HplM16c62pAdc.isComplete() {
    // interrupt flag bit
    return ADIC.BIT.IR; 
  }
  
  
  /* A/D interrupt handlers. Signals dataReady event with interrupts enabled */
  default async event void HplM16c62pAdc.dataReady(uint16_t done) { }
  M16C_INTERRUPT_HANDLER(M16C_AD)
  {
    uint16_t data = call HplM16c62pAdc.getValue();
    
    __nesc_enable_interrupt();
    signal HplM16c62pAdc.dataReady(data);
  }

  async command bool HplM16c62pAdc.cancel() { 
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
