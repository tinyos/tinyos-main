/*
 * Copyright (c) 2004, Technische Universitaet Berlin
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
 * $Revision: 1.8 $
 * $Date: 2008-06-20 10:30:28 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/**
 * The HplAdc12 interface exports low-level access to the ADC12 registers
 * of the MSP430 MCU.
 *
 * @author Jan Hauer
 * @see  Please refer to TEP 101 for more information about this component and its
 *          intended use.
 */

module HplAdc12P {
  provides interface HplAdc12;
}
implementation
{
 
  MSP430REG_NORACE(ADC12CTL0);
  MSP430REG_NORACE(ADC12CTL1);
  MSP430REG_NORACE(ADC12IFG);
  MSP430REG_NORACE(ADC12IE);
  MSP430REG_NORACE(ADC12IV);

  // SFRs are accessed directly or cast to a pointer, both works fine
  // (we don't access all SFRs directly, because that would result in
  // much higher memory footprint)
  
  async command void HplAdc12.setCtl0(adc12ctl0_t control0){
    ADC12CTL0 = *((uint16_t*) &control0); 
  }
  
  async command void HplAdc12.setCtl1(adc12ctl1_t control1){
    ADC12CTL1 = *((uint16_t*) &control1); 
  }
  
  async command adc12ctl0_t HplAdc12.getCtl0(){ 
    return *((adc12ctl0_t*) &ADC12CTL0); 
  }
  
  async command adc12ctl1_t HplAdc12.getCtl1(){
    return *((adc12ctl1_t*) &ADC12CTL1); 
  }
  
  async command void HplAdc12.setMCtl(uint8_t i, adc12memctl_t memControl){
    uint8_t *memCtlPtr = (uint8_t*) ADC12MCTL;
    memCtlPtr += i;
    *memCtlPtr = *(uint8_t*)&memControl; 
  }
   
  async command adc12memctl_t HplAdc12.getMCtl(uint8_t i){
    adc12memctl_t x = {inch: 0, sref: 0, eos: 0 };    
    uint8_t *memCtlPtr = (uint8_t*) ADC12MCTL;
    memCtlPtr += i;
    x = *(adc12memctl_t*) memCtlPtr;
    return x;
  }  
  
  async command uint16_t HplAdc12.getMem(uint8_t i){
    return *((uint16_t*) ADC12MEM + i);
  }

  async command void HplAdc12.setIEFlags(uint16_t mask){ ADC12IE = mask; } 
  async command uint16_t HplAdc12.getIEFlags(){ return (uint16_t) ADC12IE; } 
  
  async command void HplAdc12.resetIFGs(){ 
    ADC12IV = 0; 
    ADC12IFG = 0;
  } 
  
  async command void HplAdc12.startConversion(){ 
    ADC12CTL0 |= ADC12ON; 
    ADC12CTL0 |= (ADC12SC + ENC); 
  }
  
  async command void HplAdc12.stopConversion(){
    // stop conversion mode immediately, conversion data is unreliable
    uint16_t ctl1 = ADC12CTL1;
    ADC12CTL1 &= ~(CONSEQ0 | CONSEQ1);
    ADC12CTL0 &= ~(ADC12SC + ENC); 
    ADC12CTL0 &= ~(ADC12ON);
    ADC12CTL1 |= (ctl1 & (CONSEQ0 | CONSEQ1));
  }
  
  async command void HplAdc12.enableConversion(){ 
    ADC12CTL0 |= ENC; 
  }
    
  async command bool HplAdc12.isBusy(){ return ADC12CTL1 & ADC12BUSY; }

  TOSH_SIGNAL(ADC_VECTOR) {
    signal HplAdc12.conversionDone(ADC12IV);
  }
}

