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
#include "TKN154_platform.h"
interface RadioRx
{

  /** 
   * Prepares the radio for receive mode. This command will fail, if the radio
   * is not in the state RADIO_OFF. The actual receive operation will be
   * triggered through a call to <tt>receive()</tt>.  
   *
   * @return SUCCESS if the command was accepted and <tt>prepareDone()</tt>
   * will be signalled; EALREADY if the radio is already in state RX_PREPARED,
   * FAIL otherwise
   **/ 
  async command error_t prepare();

  /** 
   * Signalled in response to a successful call to <tt>prepare()</tt>. This  
   * event is completing the preparation of a receive operation, the radio is
   * now in the state RX_PREPARED. The actual receive operation will be
   * triggered through a call to <tt>receive()</tt>.
   **/    
  async event void prepareDone(); 

  /** @return TRUE if the radio is in the state RX_PREPARED, FALSE otherwise */
  async command bool isPrepared();

  /** 
   * Switches the radio to receive mode at time <tt>t0 + dt</tt>.  If
   * <tt>t0</tt> is NULL, then the callee interprets <tt>t0</tt> as the current
   * time. 
   *
   * @param t0 Reference time for receive operation (NULL means now)  
   *
   * @param dt A positive offset relative to <tt>t0</tt>.  
   *
   * @return SUCCESS if the the command was accepted and the radio will be 
   * switched to receive mode; FAIL, if the radio is not in the state 
   * RX_PREPARED
   */
  async command error_t receive(ieee154_reftime_t *t0, uint32_t dt); 
  
  /** @return TRUE if the radio is in the state RECEIVING, FALSE otherwise */
  async command bool isReceiving();

  /** 
   * A frame was received and passed the filters described in 
   * IEEE 802.15.4-2006 Sec. 7.5.6.2 ("Reception and rejection").
   *
   * @param timestamp The point in time when the first bit of the PPDU
   * was received or NULL if timestamp is not available.
   *
   * @param frame The received frame  
   *
   * @return            a buffer to be used by the driver for the next 
   *                    incoming frame 
   */
  event message_t* received(message_t *frame, ieee154_reftime_t *timestamp); 
}

