/// $Id: HplM16c62pAdc.nc,v 1.2 2010-06-29 22:07:45 scipio Exp $

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

#include "M16c62pAdc.h"

/**
 * HPL interface to the M16c62p A/D conversion subsystem. 
 * <p>
 * conversion when the ADC and ADC interrupt are enabled.
 *
 * @author Martin Turon <mturon@xbow.com>
 * @author Hu Siquan <husq@xbow.com>
 * @author David Gay
 */

interface HplM16c62pAdc {
  /**
   * Read the ADCON0 (ADC control register 0)
   * @return Current ADCON0 value
   */
  async command M16c62pADCON0_t getADCON0();
  /**
   * Set the ADCON0 (ADC control register 0)
   * @param adcon0 New ADCON0 value
   */
  async command void setADCON0(M16c62pADCON0_t adcon0);
/////////////////////////////////////////////////////////////////////////////////
  /**
   * Read the ADCON1 (ADC control) register
   * @return Current ADCON1 value
   */
  async command M16c62pADCON1_t getADCON1();
  /**
   * Set the ADCON1 (ADC control) register
   * @param adcon1 New ADCON1 value
   */
  async command void setADCON1(M16c62pADCON1_t adcon1);
//////////////////////////////////////////////////////////////////////////////////   
  /**
   * Read the ADCON2 (ADC control) register
   * @return Current ADCON2 value
   */
  async command M16c62pADCON2_t getADCON2();
  /**
   * Set the ADCON2 (ADC control) register
   * @param adcon2 New ADCON2 value
   */
  async command void setADCON2(M16c62pADCON2_t adcon2);
/////////////////////////////////////////////////////////////////////////////////
  /**
   * Read the latest A/D conversion result
   * @return A/D value
   */
  async command uint16_t getValue();

  /// A/D control utilities. All of these clear any pending A/D interrupt.

  /**
   * Enable ADC sampling
   */
  async command void enableAdc();
  /**
   * Disable ADC sampling
   */
  async command void disableAdc();

  /**
   * Enable ADC interrupt
   */
  async command void enableInterruption();
  /**
   * Disable ADC interrupt
   */
  async command void disableInterruption();
  /**
   * Clear the ADC interrupt flag
   */
  async command void resetInterrupt();

  /**
   * Start ADC conversion. If ADC interrupts are enabled, the dataReady event
   * will be signaled once (in non-continuous mode) or repeatedly (in
   * continuous mode).
   */
  async command void startConversion();
  /**
   * Enable continuous sampling
   */
  async command void setContinuous();
  /**
   * Disable continuous sampling
   */
  async command void setSingle();

  /* A/D status checks */

  /**
   * Is ADC enabled?
   * @return TRUE if the ADC is enabled, FALSE otherwise
   */
  async command bool isEnabled();
  /**
   * Is A/D conversion in progress?
   * @return TRUE if the A/D conversion is in progress, FALSE otherwise
   */
  async command bool isStarted();
  /**
   * Is A/D conversion complete? Note that this flag is automatically
   * cleared when an A/D interrupt occurs.
   * @return TRUE if the A/D conversion is complete, FALSE otherwise
   */
  async command bool isComplete();
  
  
  /**
   * Set ADC precision selection bits
   * @param scale New ADC prescision. Must be one of the M16c62p_ADC_PRECISION_xxx
   *   values from M16c62pAdc.h
   */
  async command void setPrecision(uint8_t precision);
  
  /**
   * Set ADC prescaler selection bits
   * @param scale New ADC prescaler. Must be one of the M16c62p_ADC_PRESCALE_xxx
   *   values from M16c62pAdc.h
   */
  async command void setPrescaler(uint8_t scale);

  /**
   * Cancel A/D conversion and any pending A/D interrupt. Also disables the
   * ADC interruption (otherwise a sample might start at the next sleep
   * instruction). This command can assume that the A/D converter is enabled. 
   * @return TRUE if an A/D conversion was in progress or an A/D interrupt
   *   was pending, FALSE otherwise. In single conversion mode, a return
   *   of TRUE implies that the dataReady event will not be signaled.
   */
  async command bool cancel();

  /**
   * A/D interrupt occured
   * @param data Latest A/D conversion result
   */
  async event void dataReady(uint16_t data);     
}
