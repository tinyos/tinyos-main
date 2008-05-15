/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 */

module DummyLayerP
{
	provides interface LowPowerListening;
}

implementation
{
	command void LowPowerListening.setLocalSleepInterval(uint16_t sleepIntervalMs) { }

	command uint16_t LowPowerListening.getLocalSleepInterval() { return 0; }
  
	command void LowPowerListening.setLocalDutyCycle(uint16_t dutyCycle) { }
  
	command uint16_t LowPowerListening.getLocalDutyCycle() { return 10000; }
  
	command void LowPowerListening.setRxSleepInterval(message_t *msg, uint16_t sleepIntervalMs) { }
  
	command uint16_t LowPowerListening.getRxSleepInterval(message_t *msg) { return 0; }
  
	command void LowPowerListening.setRxDutyCycle(message_t *msg, uint16_t dutyCycle) { }
  
	command uint16_t LowPowerListening.getRxDutyCycle(message_t *msg) { return 10000; }
  
	command uint16_t LowPowerListening.dutyCycleToSleepInterval(uint16_t dutyCycle) { return 0; }

	command uint16_t LowPowerListening.sleepIntervalToDutyCycle(uint16_t sleepInterval) { return 10000; }
}
