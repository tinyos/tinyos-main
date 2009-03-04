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
 * $Date: 2009-03-04 18:31:40 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 * The MCPS-DATA.request primitive requests the transfer of a data SPDU (i.e.,
 * MSDU) from a local SSCS entity to a single peer SSCS entity. (IEEE
 * 802.15.4-2006, Sect. 7.1.1)
 */

#include "TKN154.h"
#include <message.h>

interface MCPS_DATA 
{

  /**
   * "Requests to transfer a data SPDU (i.e., MSDU) from a local SSCS
   * entity to a single peer SSCS entity." (IEEE 802.15.4-2006, Sec.
   * 7.1.1.1) 
   *
   * The source/destination addressing mode, destination PAN
   * identifier, destination address, the payload and (optionally) the
   * security mode/key are part of the <tt>frame</tt> and must have
   * been set (through the <tt>IEEE154Frame</tt> interface) before
   * calling this command.
   * 
   * If this command returns IEEE154_SUCCESS, then the confirm event
   * will be signalled in the future; otherwise, the confirm event
   * will not be signalled.
   * 
   * @param frame         The frame to send
   * @param payloadLen    The length of the frame payload
   * @param msduHandle    Handle associated with the frame
   * @param TxOptions     Bitwised OR transmission options
   *
   * @return       IEEE154_SUCCESS if the request succeeded and only
   *               then the <tt>confirm()</tt> event will be signalled;
   *               an appropriate error code otherwise 
   * @see          confirm
   */

  command ieee154_status_t request  (
                          message_t *frame,
                          uint8_t payloadLen,
                          uint8_t msduHandle,
                          uint8_t TxOptions
                        );

  /**
   * Reports the result of a request to transfer a frame to a peer
   * SSCS entity.
   *
   * @param frame      The frame which was requested to be sent
   * @param msduHandle The handle associated with the frame
   * @param status     The status of the last MSDU transmission
   * @param timestamp  Time of transmission (invalid if <tt>status</tt> 
   *                   is not IEEE154_SUCCESS)
   */
  event void confirm    (  
                          message_t *frame,
                          uint8_t msduHandle,
                          ieee154_status_t status,
                          uint32_t Timestamp
                        );

  /**
   * Indicates the arrival of a frame. Use the <tt>IEEE154Frame</tt>
   * interface to get the payload, source/destination addresses, DSN
   * and other information associated with this frame.
   * 
   * @return A frame buffer for the stack to use for the next received frame
   */
  event message_t* indication ( message_t* frame );

}
