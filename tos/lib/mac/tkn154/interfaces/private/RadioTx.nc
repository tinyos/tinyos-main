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
 * $Revision: 1.2 $
 * $Date: 2008-11-25 09:35:09 $
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
   * the radio is switched off through the <tt>RadioOff</tt>
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
   * through a call to <tt>load()</tt> at time <tt>t0+dt</tt> or immediately if
   * <tt>t0</tt> is NULL. In the first case the caller has to guarantee (through
   * platform-specific guard times and by calling <tt>transmit</tt> in an
   * atomic block) that the callee can start the transmission on time.
   * The frame is transmitted without carrier sense (without CCA).  
   * The <tt>transmitDone()</tt> event will signal the result
   * of the transmission.
   *
   * @param t0 Reference time for transmission (NULL means now)  
   * @param dt A positive offset relative to <tt>t0</tt>.  
   *
   * @return SUCCESS if the transmission was triggered successfully and only
   * then <tt>transmitDone()</tt> will be signalled; FAIL, if the transmission
   * was not triggered because no frame was loaded.
   */
  async command error_t transmit(ieee154_reftime_t *t0, uint32_t dt);

  /**
   * Signalled in response to a call to <tt>transmit()</tt> and completing the transmission. Depending on the
   * <tt>error</tt> parameter the radio is now in the state RADIO_OFF
   * (<tt>error == IEEE154_SUCCESS</tt>) or back in state TX_LOADED
   * (<tt>error != IEEE154_SUCCESS</tt>). 
   *
   * @param frame The frame that was transmitted.  
   * @param txTime The time of transmission of the first symbol of the PPDU or NULL if the transmission failed.  
   */
  async event void transmitDone(ieee154_txframe_t *frame, ieee154_reftime_t *txTime);


 /** 
   * Transmits the frame whose transmission has previously been prepared
   * through a call to <tt>load()</tt> using the unslotted CSMA-CA 
   * algorithm as specified in the IEEE 802.15.4-2006 standard Sect. 7.5.1.4. The initial 
   * CSMA-CA parameters are passed as a parameter, the algorithm should start immediately.
   * The <tt>transmitUnslottedCsmaCaDone()</tt> event will signal the result
   * of the transmission.
   * A successful transmission may include an acknowledgement from the
   * destination if the ACK_REQUESTED flag is set in the loaded frame's header; then,
   * the callee also has to perform the necessary steps for receiving the
   * acknowledgement (switching the radio to Rx mode immediately after
   * transmission, etc., as specified in IEEE 802.15.4-2006 Sect. 7.5.6.4). 
   * 
   * @param csmaParameters parameters for the unslotted CSMA-CA algorithm. 
   *
   * @return SUCCESS if the unslotted CSMA-CA was triggered successfully,
   * FAIL otherwise.
   */
  async command error_t transmitUnslottedCsmaCa(ieee154_csma_t *csmaParameters);

  /**
   * Signalled in response to a call to <tt>transmitUnslottedCsmaCa()</tt>. 
   * Depending on the
   * <tt>error</tt> parameter the radio is now in the state RADIO_OFF
   * (<tt>error == IEEE154_SUCCESS</tt>) or still in state TX_LOADED
   * (<tt>error != IEEE154_SUCCESS</tt>). If the transmission succeeded then
   * the time of the transmission -- the point in time when the first symbol of the
   * PPDU was transmitted -- will be stored in the metadata field of the frame. 
   *
   * @param frame The frame that was transmitted.  
   * @param csmaParameters csmaParameters parameters for the unslotted CSMA-CA algorithm
   * @param ackPendingFlag TRUE if an acknowledgement was received and the
   * "pending" flag is set in the header of the ACK frame, FALSE otherwise
   * @param result SUCCESS if the the frame was transmitted (and a matching
   * acknowledgement was received, if requested); FAIL if the CSMA-CA algorithm failed
   * because NB > macMaxCsmaBackoffs.  
   *
   * unslotted CSMA-CA was triggered successfully,
   * FAIL otherwiseThe time of transmission or NULL if the transmission failed.  
   */
  async event void transmitUnslottedCsmaCaDone(ieee154_txframe_t *frame,
      bool ackPendingFlag, ieee154_csma_t *csmaParameters, error_t result);


 /** 
   * Transmits the frame whose transmission has previously been prepared
   * through a call to <tt>load()</tt> using the slotted CSMA-CA 
   * algorithm as specified in the IEEE 802.15.4-2006 standard Sect. 7.5.1.4. The initial 
   * CSMA-CA parameters are passed as a parameter, the algorithm should start immediately,
   * but the frame transmission should start no later than <tt>slot0Time+dtMax</tt>. The backoff slot boundaries
   * are defined relative to <tt>slot0Time</tt>, if the <tt>resume</tt>
   * then the initial backoff (in symbols) is passed as the <tt>initialBackoff</tt> parameter.
   *
   * The <tt>transmitSlottedCsmaCaDone()</tt> event will signal the result
   * of the transmission.
   * A successful transmission may include an acknowledgement from the
   * destination if the ACK_REQUESTED flag is set in the loaded frame's header; then,
   * the callee also has to perform the necessary steps for receiving the
   * acknowledgement (switching the radio to Rx mode immediately after
   * transmission, etc., as specified in IEEE 802.15.4-2006 Sect. 7.5.6.4). 
   * 
   * @param slot0Time Reference time (last beacon)  
   * @param dtMax <tt>slot0Time+dtMax</tt> is the last time the frame may be transmitted.
   * @param resume TRUE means that the initial backoff is defined by the
   * <tt>initialBackoff</tt> parameter, FALSE means the <tt>initialBackoff</tt>
   * should be ignored.
   * @param initialBackoff initial backoff.
   * @param csmaParameters parameters for the slotted CSMA-CA algorithm. 
   *
   * @return SUCCESS if the slotted CSMA-CA was triggered successfully,
   * FAIL otherwise.
   */
  async command error_t transmitSlottedCsmaCa(ieee154_reftime_t *slot0Time, uint32_t dtMax, 
      bool resume, uint16_t initialBackoff, ieee154_csma_t *csmaParameters);

  /**
   * Signalled in response to a call to <tt>transmitSlottedCsmaCa()</tt>. 
   * Depending on the
   * <tt>error</tt> parameter the radio is now in the state RADIO_OFF
   * (<tt>error == IEEE154_SUCCESS</tt>) or still in state TX_LOADED
   * (<tt>error != IEEE154_SUCCESS</tt>). If the transmission succeeded then
   * the time of the transmission -- the point in time when the first symbol of the
   * PPDU was transmitted -- will be stored in the metadata field of the frame.
   * It will also passed (possibly with higher precision) through the
   * <tt>txTime</tt> parameter.
   *
   * @param frame The frame that was transmitted.  
   * @param txTime The time of transmission of the first symbol of the PPDU or NULL if the transmission failed.  
   * @param ackPendingFlag TRUE if an acknowledgement was received and the
   * "pending" flag is set in the header of the ACK frame, FALSE otherwise
   * @param remainingBackoff only valid if <tt>error == ERETRY</tt>, i.e.
   * when the frame could not be transmitted because transmission would have
   * started later than <tt>slot0Time+dtMax</tt>; then it 
   * specifies the remaining offset (in symbols) relative to <tt>slot0Time+dtMax</tt>,
   * when the frame would have been transmitted
   * @param csmaParameters csmaParameters parameters for the unslotted CSMA-CA algorithm
   *
   * @result result SUCCESS if the the frame was transmitted (and a matching
   * acknowledgement was received, if requested); FAIL if the CSMA-CA algorithm failed
   * because NB > macMaxCsmaBackoffs; ERETRY if the frame could not be transmitted because transmission would have
   * started later than <tt>slot0Time+dtMax</tt>
   */
  async event void transmitSlottedCsmaCaDone(ieee154_txframe_t *frame, ieee154_reftime_t *txTime, 
      bool ackPendingFlag, uint16_t remainingBackoff, ieee154_csma_t *csmaParameters, error_t result);
}
