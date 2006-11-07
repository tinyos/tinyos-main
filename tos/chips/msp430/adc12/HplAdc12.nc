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
 * $Revision: 1.3 $
 * $Date: 2006-11-07 19:30:56 $
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
#include <Msp430Adc12.h>
interface HplAdc12
{
  /** 
   * Sets the ADC12 control register ADC12CTL0.
   * @param control0 ADC12CTL0 register data.
   **/
  async command void setCtl0(adc12ctl0_t control0); 
  
  /** 
   * Sets the ADC12 control register ADC12CTL1. 
   * @param control1 ADC12CTL1 register data.
   **/
  async command void setCtl1(adc12ctl1_t control1);

  /** 
   * Returns the ADC12 control register ADC12CTL0.
   * @return ADC12CTL0
   **/
  async command adc12ctl0_t getCtl0(); 

  /** Returns the ADC12 control register ADC12CTL1. 
   *  @return ADC12CTL1
   **/
  async command adc12ctl1_t getCtl1(); 
  
  /** 
   * Sets the ADC12 conversion memory control register ADC12MCTLx.
   * @param index The register index (the 'x' in ADC12MCTLx) [0..15] 
   * @param memControl ADC12MCTLx register data.
   */
  async command void setMCtl(uint8_t index, adc12memctl_t memControl); 
  
  /** 
   * Returns the ADC12 conversion memory control register ADC12MCTLx.
   * @param index The register index (the 'x' in ADC12MCTLx) [0..15] 
   * @return memControl ADC12MCTLx register data.
   */
  async command adc12memctl_t getMCtl(uint8_t index); 

  /** 
   * Returns the ADC12 conversion memory register ADC12MEMx.
   * @param index The register index (the 'x' in ADC12MEMx) [0..15] 
   * @return ADC12MEMx 
   */  
  async command uint16_t getMem(uint8_t index); 

  /** 
   * Sets the ADC12 interrupt enable register, ADC12IE.
   * @param mask Bitmask (0 means interrupt disabled, 1 menas interrupt enabled) 
   */
  async command void setIEFlags(uint16_t mask); 

  /** 
   * Returns the ADC12 interrupt enable register, ADC12IE.
   * @return ADC12IE
   */  
  async command uint16_t getIEFlags(); 
  
  /** 
   * Resets the ADC12 interrupt flag register, ADC12IFG.
   */
  async command void resetIFGs(); 

  /** 
   * Signals an ADC12MEMx overflow.
   */ 
  async event void memOverflow();

  /** 
   * Signals a Conversion time overflow.
   */ 
  async event void conversionTimeOverflow();

  /** 
   * Signals a conversion result. 
   * @param iv ADC12 interrupt vector value 0x6, 0x8, ... , 0x24
   */ 
  async event void conversionDone(uint16_t iv);

  /** 
   * Returns the ADC12 BUSY flag.
   * @return ADC12BUSY 
   */ 
  async command bool isBusy();

  /**
   * Stops a conversion.
   */
  async command void stopConversion();

  /**
   * Starts a conversion.
   */
  async command void startConversion();

}

