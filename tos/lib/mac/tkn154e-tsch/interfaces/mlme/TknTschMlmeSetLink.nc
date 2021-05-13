/*
 * Copyright (c) 2015, Technische Universitaet Berlin
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
 * @author Jasper Büsch <buesch@tkn.tu-berlin.de>
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 */


#include "tkntsch_types.h"

interface TknTschMlmeSetLink
{

  /**
   * Operations on slotframes.
   * 
   * The MLME-SET-LINK.request primitive requests to add a new link, 
   * or delete or modify an existing link at the MAC sublayer. 
   * The sfHandle and linkHandle are supplied by a higher layer.
   *
   * @param Operation   Type of link management operation to be performed.
                        PLAIN154E_ADD_LINK, PLAIN154E_DELETE_LINK, PLAIN154E_MODIFY_LINK
   * @param LinkHandle  Unique identifier (local to specified slotframe) 
                        for the link.  
   * @param sfHandle   The sfHandle of the slotframe to which 
                              the link is associated.
   * @param Timeslot    Timeslot of the link to be added, as described in 5.1.1.5.
   * @param ChannelOffset   The Channel offset of the link
   * @param LinkOptions Bitmap for Transmit, Receive, Shared, Timekeeping.
   * @param LinkType    Type of link. Also indicates if the link may be used 
                        to send an Enhanced beacon.
   * @param NodeAddr    Address of neighbor device connected by the link. 
                        0xffff indicates the link may be used for frames destined 
                        for the broadcast address.
   *
   * @return       IEEE154_SUCCESS if the request succeeded and a confirm event
   *               will be signalled, an appropriate error code otherwise 
   *               (no confirm event will be signalled in this case)
   * @see          confirm
   */
  command plain154_status_t request  (
                          tkntsch_slotframe_operation_t  Operation,
                          uint16_t LinkHandle,
                          uint8_t  sfHandle, 
                          uint16_t Timeslot, 
                          uint8_t  ChannelOffset, 
                          uint8_t  LinkOptions, 
                          tkntsch_link_type_t  LinkType, 
                          plain154_full_address_t* NodeAddr
                        );

  /**
   * The MLME-SET-LINK.confirm primitive indicates the result of add, delete, 
   * or modify link operation. The linkHandle and sfHandle are those 
   * that were supplied by a higher layer in the prior call to MLME- SET-LINK.request
   *
   * @param Status Result of the request operation. SUCCESS, INVALID_PARAMETER, 
                       UNKNOWN_LINK, MAX_LINKS_EXCEEDED
   * @param LinkHandle Unique (local to specified slotframe) identifier for 
                       the link.
   * @param sfHandle The sfHandle of the slotframe to which the 
                       link is associated.
   *
   */
  event void confirm    (
                          tkntsch_status_t  Status,
                          uint16_t LinkHandle, 
                          uint8_t  sfHandle
                        );

}
