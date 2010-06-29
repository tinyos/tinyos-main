/// $Id: HplAtm128Timer.nc,v 1.5 2010-06-29 22:07:43 scipio Exp $

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

/**
 * Basic interface to the hardware timers on an ATmega128.  
 * <p>
 * This interface is designed to be independent of whether the underlying 
 * hardware is an 8-bit or 16-bit wide counter.  As such, timer_size is 
 * specified via a generics parameter.  Because this is exposing a common 
 * subset of functionality that all ATmega128 hardware timers share, all 
 * that is exposed is access to the overflow capability.  Compare and capture
 * functionality are exposed on separate interfaces to allow easy 
 * configurability via wiring.
 * <p>
 * This interface provides four major groups of functionality:<ol>
 *      <li>Timer Value: get/set current time
 *      <li>Overflow Interrupt event
 *      <li>Control of Overflow Interrupt: start/stop/clear...
 *      <li>Timer Initialization: turn on/off clock source
 * </ol>
 *
 * @author Martin Turon <mturon@xbow.com>
 */

interface HplAtm128Timer<timer_size>
{
  /** 
   * Get the current time.
   * @return  the current time
   */
  async command timer_size get();

  /** 
   * Set the current time.
   * @param t     the time to set
   */
  async command void       set( timer_size t );

  /** Signalled on timer overflow interrupt. */
  async event void overflow();

  // ==== Interrupt flag utilites: Bit level set/clr =================

  /** Clear the overflow interrupt flag. */
  async command void reset();

  /** Enable the overflow interrupt. */
  async command void start();

  /** Turn off overflow interrupts. */
  async command void stop();

  /** 
   * Did an overflow interrupt occur?
   * @return TRUE if overflow triggered, FALSE otherwise
   */
  async command bool test();

  /** 
   * Is overflow interrupt on? 
   * @return TRUE if overflow enabled, FALSE otherwise
   */
  async command bool isOn();

  // ==== Clock initialization interface =============================

  /** Turn off the clock. */
  async command void    off();

  /** 
   * Turn on the clock.
   * @param scale   Prescaler setting of clock -- see Atm128Timer.h
   */
  async command void    setScale( uint8_t scale);

  /** 
   * Get prescaler setting.
   * @return  Prescaler setting of clock -- see Atm128Timer.h
   */
  async command uint8_t getScale();
}
