/* 
 * Copyright (c) 2008, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Based on lib/mac/tkn154/interfaces/private/RadioRx.nc (Revision 1.3) 
 * by Jan Hauer. However the receive() event has different semantics.
 *
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "Timer.h"
#include "message.h"

/**
 * The Plain154PhyRx interface parameterised like the Alarm interface 
 * to indicate the properties of the internally used Alarm.
 */
interface Plain154PhyRx<precision_tag, size_type>
{
  /** 
   * Switches the radio to receive mode at time <tt>t0 + dt</tt> or immediately
   * if <tt>t0 + dt</tt> lies in the past. Analogous to the <tt>Timer</tt>
   * interface <tt>t0</tt> is interpreted as a time in the past. Consequently,
   * if <tt>dt = 0</tt> then the radio is always switched to receive mode
   * immediately. This command will fail, if the radio is currently not in
   * state RADIO_OFF. Once the radio is in receive mode an event
   * <tt>enableRxDone</tt> will be signalled.
   *
   * @param t0 Reference time for receive operation  
   *
   * @param dt A positive offset relative to <tt>t0</tt>.  
   *
   * @return SUCCESS if the command was accepted and only then the
   * <tt>enableRxDone()</tt> event will be signalled; FAIL, if the command was
   * not accepted, because the radio is currently not in the state RADIO_OFF.
   */
  async command error_t enableRx(size_type t0, size_type dt);

  /** 
   * Signalled in response to a successful call to <tt>enableRx()</tt>. This
   * event is completing the <tt>enableRx()</tt> operation, the radio is now in
   * the state RECEIVING. It will stay in receive mode until it is switched off
   * through the <tt>RadioOff</tt> interface. Received frames will be signalled
   * through the <tt>received()</tt> event.
   **/    
  async event void enableRxDone(); 

  /**
   * Tells whether the radio is in state RECEIVING, i.e. in receive
   * mode.
   *
   * @return TRUE if the radio is in the state RECEIVING, FALSE otherwise 
   */
  async command bool isReceiving();

  /** 
   * A frame was received and passed the first level filter (FCS correct) 
   * described in IEEE 802.15.4-2011 Sec. 5.1.6.2 ("Reception and rejection").
   *
   * @param frame The received frame  
   *
   * @return            a buffer to be used by the driver for the next 
   *                    incoming frame 
   */
  async event message_t* received(message_t *frame); 

  /**
   * Return the current time.
   * @return Current time.
   */
  async command size_type getNow();

}
