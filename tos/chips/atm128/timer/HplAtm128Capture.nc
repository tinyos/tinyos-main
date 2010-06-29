/// $Id: HplAtm128Capture.nc,v 1.5 2010-06-29 22:07:43 scipio Exp $

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
