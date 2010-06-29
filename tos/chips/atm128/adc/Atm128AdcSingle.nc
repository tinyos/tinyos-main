/// $Id: Atm128AdcSingle.nc,v 1.6 2010-06-29 22:07:43 scipio Exp $

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
 *
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Hardware Abstraction Layer interface of Atmega128 for acquiring
 * a single sample from a channel.
 *
 * @author Hu Siquan <husq@xbow.com>
 * @author David Gay
 */

#include "Atm128Adc.h"

interface Atm128AdcSingle
{
  /**
   * Initiates an ADC conversion on a given channel.
   *
   * @param channel A/D conversion channel.
   * @param refVoltage Select reference voltage for A/D conversion. See
   *   the ATM128_ADC_VREF_xxx constants in Atm128ADC.h
   * @param leftJustify TRUE to place A/D result in high-order bits 
   *   (i.e., shifted left by 6 bits), low to place it in the low-order bits
   * @param prescaler Prescaler value for the A/D conversion clock. If you 
   *  specify ATM128_ADC_PRESCALE, a prescaler will be chosen that guarantees
   *  full precision. Other prescalers can be used to get faster conversions. 
   *  See the ATmega128 manual for details.
   * @return TRUE if the conversion will be precise, FALSE if it will be 
   *   imprecise (due to a change in refernce voltage, or switching to a
   *   differential input channel)
   */
  async command bool getData(uint8_t channel, uint8_t refVoltage,
			     bool leftJustify, uint8_t prescaler);
  
  /**
   * Indicates a sample has been recorded by the ADC as the result
   * of a <code>getData()</code> command.
   *
   * @param data a 2 byte unsigned data value sampled by the ADC.
   * @param precise if the conversion precise, FALSE if it wasn't. This
   *   values matches the result from the <code>getData</code> call.
   */	
  async event void dataReady(uint16_t data, bool precise);

  /**
   * Cancel an outstanding getData operation. Use with care, to
   * avoid problems with races between the dataReady event and cancel.
   * @return TRUE if a conversion was in-progress or an interrupt
   *   was pending. dataReady will not be signaled. FALSE if the
   *   conversion was already complete. dataReady will be (or has
   *   already been) signaled.
   */
  async command bool cancel();
}
