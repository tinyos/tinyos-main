/// $Id: HplAtm128Capture.nc,v 1.3 2006-11-07 19:30:45 scipio Exp $

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
 * HPL Interface to Atmega128 capture capabilities.
 * @param size_type Integer type of capture register
 *
 * @author Martin Turon <mturon@xbow.com>
 */
interface HplAtm128Capture<size_type>
{
  // ==== Capture value register: Direct access ======================
  /** 
   * Get the time to be captured.
   * @return  the capture time
   */
  async command size_type get();

  /** 
   * Set the time to be captured.
   * @param t     the time of the next capture event
   */
  async command void      set(size_type t);

  // ==== Interrupt signals ==========================================
  /** 
   * Signalled on capture interrupt.
   * @param t     the time of the capture event
   */
  async event void captured(size_type t);

  // ==== Interrupt flag utilites: Bit level set/clr =================
  /** Clear the capture interrupt flag. */
  async command void reset();

  /** Enable the capture interrupt. */
  async command void start();          

  /** Turn off capture interrupts. */
  async command void stop();

  /** 
   * Did a capture interrupt occur?
   * @return TRUE if capture triggered, FALSE otherwise
   */
  async command bool test();           

  /** 
   * Is capture interrupt on? 
   * @return TRUE if capture enabled, FALSE otherwise
   */
  async command bool isOn();           

  /** 
   * Sets the capture edge.
   * @param up   TRUE = detect rising edge, FALSE = detect falling edge
   */
  async command void setEdge(bool up);
}
