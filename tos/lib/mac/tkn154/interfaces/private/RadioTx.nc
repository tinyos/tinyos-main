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
 * $Date: 2008-06-16 18:00:33 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
#include "TKN154_MAC.h"
#include "TKN154_PHY.h"

interface RadioTx 
{

  /** 
   * Prepares the transmission of a frame. This command will fail, if the
   * radio is neither in state RADIO_OFF nor in state TX_LOADED. The actual
   * transmission will be triggered through a call to <tt>transmit()</tt>. Any
   * frame that was previously prepared for transmission ("loaded") will be
   * overwritten.  The <tt>loadDone()</tt> event signals the completion of the
   * <tt>load()</tt> command.  
   *
   * The frame will be loaded (and the radio will stay in the state
   * TX_LOADED) until either the transmission was successful, i.e.
   * <tt>transmitDone()</tt> was signalled with a status IEEE154_SUCCESS, or
   * the radio is explicitly switched off through the <tt>RadioOff</tt>
   * interface. Until then the callee might have to reserve certain resources
   * (e.g. the bus connected to the radio), so the caller should keep the time
   * while a frame is loaded as short as possible.
   *
   * @param frame The frame to transmit.
   * 
   * @return SUCCESS if the command was accepted and <tt>loadDone()</tt> will 
   * be signalled; FAIL otherwise
   **/ 
  async command error_t load(ieee154_txframe_t *frame); 

  /** 
   * Signalled in response to a successful call to <tt>load()</tt>. This  
   * event is completing the preparation of a transmission, the radio is
   * now in the state TX_LOADED. The actual transmission is triggered 
   * through a call to <tt>transmit()</tt>.
   **/  
  async event void loadDone(); 

  /** 
   * If the radio is in state TX_LOADED then this commands returns the
   * the frame that was loaded last; it returns NULL otherwise.
   *
   * @return last frame loaded if radio is in the state TX_LOADED, 
   * NULL otherwise
   **/  
  async command ieee154_txframe_t* getLoadedFrame();

  /** 
   * Transmits the frame whose transmission has previously been prepared
   * through a call to <tt>load()</tt>. The actual time of transmission -- the
   * point in time when the first symbol of the PPDU is transmitted -- is
   * defined by: <tt>t0 + dt</tt>. The data type of the <tt>t0</tt> parameter
   * is platform-specific (symbol precision or better) while <tt>dt</tt> is
   * expressed in 802.15.4 symbols. If <tt>t0</tt> is NULL, then the callee
   * interprets <tt>t0</tt> as the current time. The caller guarantees (through
   * platform-specific guard times and by calling <tt>transmit</tt> in an
   * atomic block) that the callee can start the transmission on time, taking
   * any prior clear channel assesment(s) into consideration. 
   *
   * A transmission may require 0, 1 or 2 prior clear channel assesments
   * (<tt>numCCA</tt> parameter) to be performed 0, 20 or 40 symbols,
   * respectively, before the actual transmission. If a CCA determines a busy
   * channel, then the frame will not be transmitted. 
   *
   * A successful transmission may also require an acknowledgement from the
   * destination (indicated through the <tt>ackRequest</tt> parameter); then,
   * the callee has to perform the necessary steps for receiving that
   * acknowledgement (switching the radio to Rx mode immediately after
   * transmission, etc.; for details see IEEE 802.15.4-2006).
   *
   * The <tt>transmit()</tt> command will succeed iff the radio is in state
   * TX_LOADED. The <tt>transmitDone()</tt> event will then signal the result
   * of the transmission.
   *
   * @param t0 Reference time for transmission (NULL means now)  
   *
   * @param dt A positive offset relative to <tt>t0</tt>.  
   *
   * @param numCCA Number of clear channel assesments.
   *
   * @param ackRequest TRUE means an acknowledgement is required, FALSE means
   * no acknowledgement is not required
   *
   * @return SUCCESS if the transmission was triggered successfully and only
   * then <tt>transmitDone()</tt> will be signalled; FAIL, if the transmission
   * was not triggered because no frame was loaded.
   */  
  async command error_t transmit(ieee154_reftime_t *t0, uint32_t dt, 
      uint8_t numCCA, bool ackRequest);

  /**
   * Signalled in response to a call to <tt>transmit()</tt>. Depending on the
   * <tt>error</tt> parameter the radio is now in state RADIO_OFF
   * (<tt>error</tt> == IEEE154_SUCCESS) or still in state TX_LOADED
   * (<tt>error</tt> != IEEE154_SUCCESS).  If the transmission succeeded then
   * the time of transmission -- the point in time when the first symbol of the
   * PPDU was transmitted -- will be stored in the metadata field of the frame.
   * In addition, the <tt>t0</tt> parameter will hold a platform-specific
   * representation of the same point in time (possibly with higher precision)
   * to be used as future reference time in a <tt>transmit()</tt> command. If
   * the transmission did not succeed no timestamp will be stored in the
   * metadata portion, but <tt>t0</tt> will still represent the hypothetical
   * transmission time. 
   *
   * If <tt>error</tt> has a value other than IEEE154_SUCCESS the frame will
   * stay loaded and a subsequent call to <tt>transmit</tt> will (re-)transmit
   * the same <tt>frame</tt> again. If <tt>error</tt> has a value of
   * IEEE154_SUCCESS then the frame was automatically un-loaded and a new frame
   * has to be loaded before the <tt>transmit()</tt> command will succeed.
   *
   * When the <tt>transmit()</tt> command was called with an
   * <tt>ackRequest</tt> parameter with value TRUE, and <tt>error</tt> has a
   * value of IEEE154_SUCCESS, then this means that a corresponding
   * acknowledgement was successfully received. In this case, the
   * <tt>ackPendingFlag</tt> represents the "pending" flag in the header of the
   * acknowledgement frame (TRUE means set, FALSE means reset).
   *
   * @param frame The frame that was transmitted.  
   *
   * @param t0 The (hypothetical) transmission time; the pointer is only valid
   * until the eventhandler returns.  
   *
   * @param ackPendingFlag TRUE if an acknowledgement was received and the
   * "pending" flag is set in the header of the ACK frame, FALSE otherwise
   *
   * @param error SUCCESS if the transmission succeeded (including successful
   * CCA and acknowledgement reception, if requested); EBUSY if CCA was
   * unsuccessful (frame was not transmitted); ENOACK if frame was transmitted
   * but no matching acknowledgement was received.
   **/  
  async event void transmitDone(ieee154_txframe_t *frame, ieee154_reftime_t *t0, 
      bool ackPendingFlag, error_t error);   
}
