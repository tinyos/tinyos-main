// $Id: Leds.nc,v 1.2 2010-06-29 22:07:54 scipio Exp $

/*
 * Copyright (c) 2005-2005 The Regents of the University  of California.  
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
 * - Neither the name of the University of California nor the names of
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

/**
 * Commands for controlling three LEDs. A platform can provide this
 * interface if it has more than or fewer than three LEDs. In the
 * former case, these commands refer to the first three LEDs. In the
 * latter case, some of the commands are null operations, and the set
 * of non-null operations must be contiguous and start at Led1. That
 * is, on platforms with 2 LEDs, LED 3's commands are null operations,
 * while on platforms with 1 LED, LED 2 and LED 3's commands are null
 * opertations.
 *
 * @author Joe Polastre
 * @author Philip Levis
 *
 * @author Mike Healy
 * @date April 20, 2009 - added support for 4th (green) LED on SHIMMER
 */

#include "Leds.h"

interface Leds {

  /**
   * Turn on LED 0. The color of this LED depends on the platform.
   */
  async command void led0On();

  /**
   * Turn off LED 0. The color of this LED depends on the platform.
   */
  async command void led0Off();

  /**
   * Toggle LED 0; if it was off, turn it on, if was on, turn it off.
   * The color of this LED depends on the platform.
   */
  async command void led0Toggle();

  /**
   * Turn on LED 1. The color of this LED depends on the platform.
   */
  async command void led1On();

  /**
   * Turn off LED 1. The color of this LED depends on the platform.
   */
  async command void led1Off();

   /**
   * Toggle LED 1; if it was off, turn it on, if was on, turn it off.
   * The color of this LED depends on the platform.
   */
  async command void led1Toggle();

 
  /**
   * Turn on LED 2. The color of this LED depends on the platform.
   */
  async command void led2On();

  /**
   * Turn off LED 2. The color of this LED depends on the platform.
   */
  async command void led2Off();

   /**
   * Toggle LED 2; if it was off, turn it on, if was on, turn it off.
   * The color of this LED depends on the platform.
   */
  async command void led2Toggle();
  
  /**
   * Turn on LED 3. The color of this LED depends on the platform.
   */
  async command void led3On();

  /**
   * Turn off LED 3. The color of this LED depends on the platform.
   */
  async command void led3Off();

   /**
   * Toggle LED 3; if it was off, turn it on, if was on, turn it off.
   * The color of this LED depends on the platform.
   */
  async command void led3Toggle();


  /**
   * Get the current LED settings as a bitmask. Each bit corresponds to
   * whether an LED is on; bit 0 is LED 0, bit 1 is LED 1, etc. You can
   * also use the enums LEDS_LED0, LEDS_LED1. For example, this expression
   * will determine whether LED 2 is on:
   *
   * <pre> (call Leds.get() & LEDS_LED2) </pre>
   *
   * This command supports up to 8 LEDs; if a platform has fewer, then
   * those LEDs should always be off (their bit is zero). Also see
   * <tt>set()</tt>.
   *
   * @return a bitmask describing which LEDs are on and which are off
   */ 
  async command uint8_t get();

  
  /**
   * Set the current LED configuration using a bitmask.  Each bit
   * corresponds to whether an LED is on; bit 0 is LED 0, bit 1 is LED
   * 1, etc. You can also use the enums LEDS_LED0, LEDS_LED1. For example,
   * this statement will configure the LEDs so LED 0 and LED 2 are on:
   *
   * <pre> call Leds.set(LEDS_LED0 | LEDS_LED2); </pre>
   *
   * This statement will turn LED 1 on if it was not already:
   *
   * <pre>call Leds.set(call Leds.get() | LEDS_LED1);</pre>
   *
   * @param  val   a bitmask describing the on/off settings of the LEDs
   */
   async command void set(uint8_t val);
  
}
