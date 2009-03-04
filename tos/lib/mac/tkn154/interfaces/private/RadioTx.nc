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
 * - Revision -------------------------------------------------------------
 * $Revision: 1.3 $
 * $Date: 2009-03-04 18:31:44 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
#include "TKN154_MAC.h"
#include "TKN154_platform.h"

interface RadioTx 
{
  /** 
   * Transmits a frame at time <tt>t0 + dt</tt> or immediately if <tt>t0 +
   * dt</tt> lies in the past. The frame is transmitted in any case (without
   * prior CCA). Analogous to the <tt>Timer</tt> interface <tt>t0</tt> is
   * interpreted as a time in the past. If <tt>t0</tt> is NULL or if
   * <tt>dt</tt> is zero then the frame is transmitted immediately. This
   * command will fail, if the radio is currently not in state RADIO_OFF.
   *
   * Iff the ACK_REQUESTED flag is set in the frame's header a successful
   * transmission will include an acknowledgement from the destination; then,
   * the callee will perform the necessary steps for receiving this
   * acknowledgement following the specification in IEEE 802.15.4-2006 Sect.
   * 7.5.6.4. 
   *
   * @param frame The frame to transmit
   *
   * @param t0 Reference time for transmission, NULL means frame will be 
   * transmitted immediately
   *
   * @param dt A positive offset relative to <tt>t0</tt>, ignored
   * if <tt>t0</tt> is NULL
   * 
   * @return SUCCESS if the transmission was triggered successfully and only
   * then <tt>transmitDone()</tt> will be signalled; FAIL, if the command was
   * not accepted, because the radio is currently not in the state RADIO_OFF;
   * EINVAL if <tt>frame</tt> or a pointer therein is invalid, or the length
   * of the frame is invalid
   */
  async command error_t transmit(ieee154_txframe_t *frame, const ieee154_timestamp_t *t0, uint32_t dt);

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
   * @param timestamp The point in time when the first bit of the PPDU
   * was received or NULL if a timestamp is not available. The 
   * timestamp's data type is platform-specific, you can use the 
   * <tt>IEEE154Frame.getTimestamp()</tt> command to get a platform-
   * independent variant (uint32_t) of the timestamp. This pointer
   * is only valid while the event is signalled and no reference must
   * be kept to it afterwards.
   *
   * @param result SUCCESS if the frame was transmitted (and a matching
   * acknowledgement was received, if requested); ENOACK if the frame was 
   * transmitted, but no matching acknowledgement was received although one
   * was requested     
   **/
  async event void transmitDone(ieee154_txframe_t *frame, const ieee154_timestamp_t *timestamp, error_t result);
}
