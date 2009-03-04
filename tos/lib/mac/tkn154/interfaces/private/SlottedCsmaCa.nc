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
 * $Revision: 1.1 $
 * $Date: 2009-03-04 18:31:45 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
#include "TKN154_MAC.h"
#include "TKN154_PHY.h"

interface SlottedCsmaCa 
{
  /** 
   * Transmits a frame using the slotted CSMA-CA algorithm as specified in IEEE
   * 802.15.4-2006 standard Sect. 7.5.1.4. This command will fail if the
   * current state of the radio is not RADIO_OFF. The initial CSMA-CA
   * parameters are passed as a parameter and may be modified by the callee.
   * The caller must not access <tt>csma</tt> until the <tt>transmitDone</tt>
   * event has been signalled.
   *
   * <tt>slot0Time</tt> defines the beginning of the first slot in the CAP.
   * Any transmission must commence on a backoff slot boundary relative to
   * <tt>slot0Time</tt>. The last possible time for transmission is defined by
   * <tt>slot0Time+dtMax</tt>. If the transmission cannot commence at or before
   * <tt>slot0Time+dtMax</tt> then an event <tt>transmitDone()</tt> with error
   * code ERETRY will be signalled and <tt>csma</tt> will reflect the current
   * state of the CSMA-CA algorithm. The caller can then resume the
   * transmission of this frame in the next CAP based on the
   * <tt>remainingBackoff</tt> passed in the <tt>transmitDone()</tt> event, by
   * setting <tt>resume</tt> to TRUE in the <tt>transmit()</tt> call.
   *
   * Iff the ACK_REQUESTED flag is set in the frame's header a successful
   * transmission will include an acknowledgement from the destination; then,
   * the callee will perform the necessary steps for receiving this
   * acknowledgement following the specification in IEEE 802.15.4-2006 Sect.
   * 7.5.6.4. 
   * 
   * @param frame The frame to transmit.
   *
   * @param csma Initial parameters for the slotted CSMA-CA algorithm. 
   *
   * @param slot0Time Reference time for the backoff slot boundaries  
   *
   * @param dtMax <tt>slot0Time+dtMax</tt> is the last time the frame may be 
   *              transmitted.
   *
   * @param resume TRUE means that the initial backoff is defined by the
   *               <tt>remainingBackoff</tt> parameter, FALSE means the 
   *               <tt>remainingBackoff</tt> is to be ignored.
   *
   * @param remainingBackoff initial backoff (ignored if <tt>resume</tt>
   * is FALSE.
   *
   * @return SUCCESS if the slotted CSMA-CA was triggered successfully;
   * EINVAL if <tt>frame</tt> or a pointer therein is invalid; FAIL otherwise.
   */
  async command error_t transmit(ieee154_txframe_t *frame, ieee154_csma_t *csma,
      const ieee154_timestamp_t *slot0Time, uint32_t dtMax, bool resume, uint16_t remainingBackoff);

  /**
   * Signalled in response to a call to <tt>transmit()</tt>. This event
   * completes the <tt>transmit</tt> operation. A transmission failed if either
   * the channel was never idle during any of the <tt>macMaxCsmaBackoffs+1</tt>
   * transmission attempts, if no acknowledgement was received although one was
   * requested or if the frame could not be transmitted before the specified
   * deadline (<tt>slot0Time+dtMax</tt>).
   *
   * @param frame The frame that was to be transmitted.  
   *
   * @param csma Parameters for the slotted CSMA-CA algorithm; this pointer is
   * identical to the one passed to the <tt>transmit</tt> command, the content,
   * however, may have changed.
   *
   * @param ackPendingFlag TRUE if an acknowledgement was received and the
   * "pending" flag is set in the header of the ACK frame, FALSE otherwise
   * (this is typically only relevant for indirect transmissions)
   * 
   * @param remainingBackoff Only valid if <tt>result = ERETRY</tt>, and
   * then it describes the remaining backoff time (in symbols) to be used
   * for the transmission of the frame in the following CAP.   
   *
   * @result result SUCCESS if the the frame was transmitted (and a matching
   * acknowledgement was received, if requested); FAIL if the CSMA-CA algorithm
   * failed because NB > macMaxCsmaBackoffs; ERETRY if the frame could not be 
   * transmitted because transmission would have started later than 
   * <tt>slot0Time+dtMax</tt>
   */
  async event void transmitDone(ieee154_txframe_t *frame, ieee154_csma_t *csma, 
      bool ackPendingFlag,  uint16_t remainingBackoff, error_t result);
}
