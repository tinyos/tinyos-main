// $Id: Leds.nc,v 1.1 2010-05-19 15:28:16 ayer1 Exp $

/*
 * "Copyright (c) 2005-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
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
