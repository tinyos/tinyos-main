/*
 * Copyright (c) 2010 People Power Co.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the People Power Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * PEOPLE POWER CO. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */
 
/** An interface to control a series of LEDs.
 *
 * Allows use of a series of LEDs as a visual binary register.  Bit i
 * of the value is a 1 iff LED i is on.
 *
 * This interface is generically implemented by the LedC component.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 */
interface MultiLed {
  
  /** Read the value represented by the on status of the LEDs. */
  async command unsigned int get ();

  /** Set the LEDs to represent the given value. */
  async command void set (unsigned int val);

  /** Invoke the Led.on() function for the specified LED.
   * @param led_id Position of LED to turn on, starting with LED 0 */
  async command void on (unsigned int led_id);

  /** Invoke the Led.off() function for the specified LED.
   * @param led_id Position of LED to turn on, starting with LED 0 */
  async command void off (unsigned int led_id);

  /** Invoke the Led.set() function for the specified LED.
   * @param led_id Position of LED to turn on, starting with LED 0
   * @param turn_on if TRUE, turn LED on; otherwise turn it off */
  async command void setSingle (unsigned int led_id, bool turn_on);

  /** Invoke the Led.toggle() function for the specified LED.
   * @param led_id Position of LED to turn on, starting with LED 0 */
  async command void toggle (unsigned int led_id);
}
