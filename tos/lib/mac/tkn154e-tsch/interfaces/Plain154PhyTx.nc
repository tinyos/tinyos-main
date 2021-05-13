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
 * Based on lib/mac/tkn154/interfaces/private/RadioTx.nc (Revision 1.3) 
 * by Jan Hauer.
 *
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 * ========================================================================
 */
#include "plain154_message_structs.h"
#include "Timer.h"

/**
 * The Plain154PhyTx interface parameterised like the Alarm interface 
 * to indicate the properties of the internally used Alarm.
 */
interface Plain154PhyTx<precision_tag, size_type>
{
  /** 
   * Transmits a frame at time <tt>t0 + dt</tt> or immediately if <tt>t0 +
   * dt</tt> lies in the past. The frame is transmitted regardless of the
   * channel condition (without prior CCA). Analogous to the <tt>Timer</tt> 
   * interface <tt>t0</tt> is interpreted as a time in the past. If 
   * <tt>dt</tt> is zero then the frame is transmitted immediately. This
   * command will fail, if the radio is currently not in state RADIO_OFF.
   *
   * The radio will go back to RADIO_OFF after the transmission. If an ACK 
   * is requested the MAC has to enable receiving afterwards itself.
   *
   * @param frame The frame to transmit
   *
   * @param t0 Reference time for transmission
   *
   * @param dt A positive offset relative to <tt>t0</tt>
   * 
   * @return SUCCESS if the transmission was triggered successfully and only
   * then <tt>transmitDone()</tt> will be signalled; FAIL, if the command was
   * not accepted, because the radio is currently not in the state RADIO_OFF;
   * EINVAL if <tt>frame</tt> or a pointer therein is invalid, or the length
   * of the frame is invalid
   */
  async command error_t transmit(plain154_txframe_t *frame, size_type t0, size_type dt);

  /**
   * Signalled in response to a call to <tt>transmit()</tt> and completing 
   * the transmission of a frame. The radio is now back in state RADIO_OFF. 
   * The time of the transmission -- the point in time when the first bit of the
   * PPDU was transmitted -- is given by <tt>timestamp</tt>. Since the
   * frame was transmitted without CCA the transmission can only have
   * failed if no acknowledgement was received although one was requested.
   *
   * @param frame The frame that was transmitted.  
   *
   * @param result SUCCESS if the frame was transmitted (and a matching
   * acknowledgement was received, if requested); ENOACK if the frame was 
   * transmitted, but no matching acknowledgement was received although one
   * was requested     
   **/
  async event void transmitDone(plain154_txframe_t *frame, error_t result);


  /**
   * Return the current time.
   * @return Current time.
   */
  async command size_type getNow();

}
