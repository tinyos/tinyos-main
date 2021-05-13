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
 */


#include "tkntsch_types.h"

interface TknTschMlmeSetSlotframe
{

  /**
   * Operations on slotframes.
   * 
   * The MLME-SET-SLOTFRAME.request primitive is used to add, delete, 
   * or modify a slotframe at the MAC sublayer. The sfHandle is 
   * supplied by a higher layer.
   *
   * @param sfHandle Unique identifier of the slotframe.
   * @param Operation The Operation to perform on the slotframe. 
                      ADD_SLOTFRAME, DELETE_SLOTFRAME, MODIFY_SLOTFRAME.
   * @param Size Number of timeslots in the new slotframe.

   * @return       IEEE154_SUCCESS if the request succeeded and a confirm event
   *               will be signalled, an appropriate error code otherwise 
   *               (no confirm event will be signalled in this case)
   * @see          confirm
   */
  command plain154_status_t request  (
                          uint8_t sfHandle, 
                          uint8_t Operation,  // enum.
                          uint16_t Size
                        );

  /**
   * Reports the results of the channel scan request, returning
   * the buffers passed in the <tt>request</tt> command.
   *
   * @param sfHandle Unique identifier of the slotframe to be 
                            added, deleted, or modified.
   * @param Status Indicates results of the MLME-SET-SLOTFRAME.request.
                   SUCCESS, INVALID_PARAMETER, SLOTFRAME_NOT_FOUND, 
                   MAX_SLOTFRAMES_EXCEEDED

   */
  event void confirm    (
                          uint8_t sfHandle,
                          uint8_t Status  // enum.
                        );

}
