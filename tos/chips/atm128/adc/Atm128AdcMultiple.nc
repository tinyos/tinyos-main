/// $Id: Atm128AdcMultiple.nc,v 1.5 2008-06-11 00:42:13 razvanm Exp $

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
 * Hardware Abstraction Layer interface of Atmega128 for acquiring data
 * from multiple channels using the ATmega128's free-running mode.
 * <p>
 * Because of the possibility that samples may be imprecise after 
 * switching channels and/or reference voltages, and because there
 * is a one sample delay on swithcing channels and reference voltages,
 * Atm128ADCMultiple is complex. Two straightforward uses are:
 * <ol type="A">
 * <li>Acquire N samples from channel C:
 *    <ol>
 *    <li>call getData to start sampling on channel C at the desired rate
 *       (note that the choice of prescalers is very limited, so you
 *       don't have many choices for sampling rate)
 *    <li>ignore the first dataReady event
 *    <li>use the results of the next N dataReady() events, return FALSE
 *       on the last one
 *    </ol>
 * <li>Acquire one sample each from channels C1, ..., Cn (this pseudocode
 *    assumes that none of these channels are differential)
 *    <ol>
 *    <li>call getData to start sampling on channel C1
 *    <li>on the ith dataReady event switch to channel Ci+1 by changing
 *       *newChannel
 *    <li>the data passed to the ith dataReady event is for channel Ci-1
 *       (the data from the first dataReady event is ignored)
 *    </ol>
 * </ol>
 *
 * @author Hu Siquan <husq@xbow.com>
 * @author David Gay
 */        

#include "Atm128Adc.h"

interface Atm128AdcMultiple
{
  /**
   * Initiates free-running ADC conversions, with the ability to switch 
   * channels and reference-voltage with a one sample delay.
   *
   * @param channel Initial A/D conversion channel. The channel can 
   *   be changed in the dataReady event, though these changes happen
   *   with a one-sample delay (this is a hardware restriction).
   * @param refVoltage Initial A/D reference voltage. See the
   *   ATM128_ADC_VREF_xxx constants in Atm128ADC.h. Like the channel,
   *   the reference voltage can be changed in the dataReady event with
   *   a one-sample delay.
   * @param leftJustify TRUE to place A/D result in high-order bits 
   *   (i.e., shifted left by 6 bits), low to place it in the low-order bits
   * @param prescaler Prescaler value for the A/D conversion clock. If you 
   *  specify ATM128_ADC_PRESCALE, a prescaler will be chosen that guarantees
   *  full precision. Other prescalers can be used to get faster conversions. 
   *  See the ATmega128 manual for details.
   * @return TRUE if the conversion will be precise, FALSE if it will be 
   *   imprecise (due to a change in reference voltage, or switching to a
   *   differential input channel)
   */
  async command bool getData(uint8_t channel, uint8_t refVoltage,
			     bool leftJustify, uint8_t prescaler);
  
  /**
   * Returns the next sample in a free-running conversion. Allow the user
   * to switch channels and/or reference voltages with a one sample delay.
   *
   * @param data a 2 byte unsigned data value sampled by the ADC.
   * @param precise if this conversion was precise, FALSE if it wasn't 
   *   (we assume that the second conversion after a change of reference
   *   voltage or after switching to a differential channel is precise)
   * @param channel Channel this sample was from.
   * @param newChannel Change this parameter to switch to a new channel
   *   for the second next sample.
   * @param newRefVoltage Change this parameter to change the reference 
   *   voltage for the second next sample.
   *
   * @return TRUE to continue sampling, FALSE to stop.
   */	
  async event bool dataReady(uint16_t data, bool precise, uint8_t channel,
			     uint8_t *newChannel, uint8_t *newRefVoltage);


  /* Note: there is no cancel in free-running mode because you cannot tell
     from a successful (or unsuccessful) cancellation whether there will
     be another dataReady event. Thus you cannot tell when you can safely
     reuse the ADC (short of waiting one ADC conversion period, in which
     case you might as well use the result of dataReady to cancel).
  */
}
