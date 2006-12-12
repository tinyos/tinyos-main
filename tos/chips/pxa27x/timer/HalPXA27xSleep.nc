/*
 * Copyright (c) 2005 Arch Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arch Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/**
 *
 * This interfaces provides HAL level sleep functionality for the PXA27x. 
 *
 * @author Kaisen Lin
 * @author Phil Buonadonna
 *
 */

interface HalPXA27xSleep {
  /**
   * Sleep for a given number of milliseconds. Only standard 
   * sleep mode is used. This function supports
   * sleep times up to 65534ms. Larger sleep durations must
   * use one of the other methods. 
   *
   * @param time Sleep duration in milliseconds up to 65534.
   * 
   */
  async command void sleepMillis(uint16_t time);

  /**
   * Sleep for a given number of seconds up to 62859 sec.
   * If the function is passed a value greater than 62859, it
   * will default to the maximum. For sleep durations greater
   * than 30 secs, the processor will be placed into deep sleep
   * mode. Otherwise standard sleep mode is used.
   *
   * @param time Sleep duration in seconds.
   *
   */
  async command void sleepSeconds(uint32_t time);

  /**
   * Sleep for a given number of minutes up to 1439 min. Deep
   * sleep mode is used. If the function is passed a value 
   * greater than 1439, it will default to the maximum. 
   *
   * @param time Sleep duration in minutes.
   */
  async command void sleepMinutes(uint32_t time);

  /**
   * Sleep for a given number of hours up to 23 hours. Deep
   * sleep mode is used. If the function is passed a value 
   * greater than 23, it will default to the maximum. 
   *
   * @param time Sleep duration in hours
   */
  async command void sleepHours(uint16_t time);
}
