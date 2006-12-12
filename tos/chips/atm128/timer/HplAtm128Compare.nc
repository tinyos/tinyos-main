/// $Id: HplAtm128Compare.nc,v 1.4 2006-12-12 18:23:04 vlahan Exp $

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
 * HPL Interface to Atmega128 compare registers.
 * @param size_type Integer type of compare register
 *
 * @author Martin Turon <mturon@xbow.com>
 */

interface HplAtm128Compare<size_type>
{
  // ==== Compare value register: Direct access ======================
  /** 
   * Get the compare time to fire on.
   * @return  the compare time value
   */
  async command size_type get();

  /** 
   * Set the compare time to fire on.
   * @param t     the compare time to set
   */
  async command void set(size_type t);

  // ==== Interrupt signals ==========================================
  /** Signalled on  interrupt. */
  async event void fired();           //<! Signalled on compare interrupt

  // ==== Interrupt flag utilites: Bit level set/clr =================
  /** Clear the compare interrupt flag. */
  async command void reset();         

  /** Enable the compare interrupt. */
  async command void start();         

  /** Turn off comparee interrupts. */
  async command void stop();          

  /** 
   * Did compare interrupt occur? 
   * @return TRUE if compare triggered, FALSE otherwise
   */
  async command bool test();          

  /** 
   * Is compare interrupt on?
   * @return TRUE if compare enabled, FALSE otherwise
   */
  async command bool isOn();
}

