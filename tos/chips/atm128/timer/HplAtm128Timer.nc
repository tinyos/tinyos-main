/// $Id: HplAtm128Timer.nc,v 1.4 2006-12-12 18:23:04 vlahan Exp $

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
