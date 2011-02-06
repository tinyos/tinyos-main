/*
 * Copyright (c) 2011 University of Utah. 
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
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * This currently only implements a very minimal subset of the PWM peripheral
 * capabilities to drive the event lines going to the ADC and DAC. The PWM
 * unit can do many many more things.
 *
 * @author Thomas Schmid
 */

interface Sam3sPwm
{
  /**
   * @param frequency Frequency in Herz at which the counter should count.
   */
  async command error_t configure(
          uint32_t frequency
      );

  /**
   * @param period Interval period in tics at which the channel 0 will reset.
   */
  async command void setPeriod(uint16_t period);

  /**
   * This command returns the actual frequency that the counter is set to. Not
   * all frequencies are possible.
   */
  async command uint32_t getFrequency();

  /**
   * @param compareNumber Specifies which compare to enable
   * @param compareValue Sets the compare value at which we match
   */
  async command error_t enableCompare(uint8_t compareNumber, uint16_t compareValue);

  async command error_t disableCompare(uint8_t compareNumber);

  /**
   * @param eventNumber indicates which event channel should be enabled
   * @param compares Indicates which compares this event is sensitive to.
   */
  async command error_t setEventCompares(uint8_t eventNumber, uint8_t comparers);
}
