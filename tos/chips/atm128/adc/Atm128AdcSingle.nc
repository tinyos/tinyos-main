/// $Id: Atm128AdcSingle.nc,v 1.4 2006-12-12 18:23:03 vlahan Exp $

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
