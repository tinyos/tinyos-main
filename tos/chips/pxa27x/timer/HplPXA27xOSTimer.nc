/*
 * Copyright (c) 2005 Arched Rock Corporation 
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
 *   Neither the name of the Arched Rock Corporation nor the names of its
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
 * This interface exposes a single OS Timer channel 
 * on the PXA27x processor. Each channel includes a counter register 
 * (OSCRx), a match register (OSMRx), a match control register (OMCRx) 
 * and support for events on each channel. 
 *
 * Do not confuse this HPL interface with the generic 'Timer' interface 
 * provided by TOS 2.x. They are completely different.
 *
 * Channels 0 thru 3 are the PXA25x compatibility timers. There are NO
 * match control register for these channels. 
 * Calls to getOSCR/setOSCR for channels 1 thru 3 are remmaped to OSCR0.
 * 
 * There may be additional configured inter-dependencies between the timer
 * channels. Refer to the PXA27x Developer's Guide for more information.
 *
 * @author Phil Buonadonna
 */

interface HplPXA27xOSTimer
{
  /**
   * Set/initialize the counter register (OSCRx) for the channel
   *
   * @param val Desired value to initialize/reset the counter register to.
   * 
   */
  async command void setOSCR(uint32_t val);

  /**
   * Get the current counter register (OSCRx) value for the channel.
   *
   * @return value The 32-bit value of the counter register.
   */
  async command uint32_t getOSCR();

  /**
   * Set the match register (OSMRx) for the channel.
   *
   * @param val The desired 32-bit match value.
   */
  async command void setOSMR(uint32_t val);

  /**
   * Get the current match register (OSMRx) value for the channel.
   *
   * @return value The 32-bit value of the match register.
   */
  async command uint32_t getOSMR();

  /**
   * Set the timer channel match control register (OMCRx).
   * 
   * @param val The desired OMCR value.
   */
  async command void setOMCR(uint32_t val);

  /**
   * Get the current channel match control register (OMCRx) setting.
   * 
   * @return value The current OMCR value.
   */
  async command uint32_t getOMCR();

  /**
   * Returns the bit value of the OSSR register corresponding to the 
   * channel. Indicates if a match event has ocurred.
   *
   * @return flag TRUE if an event is signaled (OSSR.M{n} is set). 
   * FALSE otherwise 
   *  
   *
   */
  async command bool getOSSRbit();

  /**
   * Clears the bit position of the OSSR register corresponding to the
   * channel. Returns the value of the bit before clearing.
   *
   * @return flag TRUE if an event is signaled (OSSR.M{n} set) prior 
   * to clearing. FALSE otherwise.
   */
  async command bool clearOSSRbit();

  /**
   * Sets the OIER bit corresponding to the timer match channel.
   *
   * @param flag TRUE to set the OIER bit, FALSE to clear.
   */
  async command void setOIERbit(bool flag);

  /**
   * Returns the setting of the OIER bit corresponding to the timer
   * match channel.
   * 
   * @return flag TRUE if set, FALSE if not set.
   */
  async command bool getOIERbit();

  /** 
   * Get the snapshot register (OSNR) value. 
   * Any parameterization of this function is ignored.
   */
  async command uint32_t getOSNR();

  /**
   * Timer channel interrupt. Fired when the channel match register matches 
   * configured 
   */
  async event void fired();

}
