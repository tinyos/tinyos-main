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

interface TknTschMlmeKeepAlive
{

  /**
   * The MLME-KEEP-ALIVE.request primitive requests that frames be sent 
   * to a device with a minimum period.
   *
   * @param DstAddr   Address of the neighbor device with which to maintain timing.
                      0xffff cannot be used.
   * @param KeepAlivePeriod   Period in timeslots after which a frame is sent 
   *                  if no frames have been sent to dstAddr.
   *
   * @return       IEEE154_SUCCESS if the request succeeded and a confirm event
   *               will be signalled, an appropriate error code otherwise 
   *               (no confirm event will be signalled in this case)
   * @see          confirm
   */
  command plain154_status_t request  (
                          uint16_t DstAddr,
                          uint16_t KeepAlivePeriod
                        );

  /**
   * The MLME-KEEP-ALIVE.confirm primitive reports the results of a request that 
   * frames be sent to a device with a minimum period.
   *
   * @param Status     Indicates results of the MLME-KEEP-ALIVE.request.
   *                   SUCCESS or INVALID_PARAMETER
   *
   */
  event void confirm    (
                          tkntsch_status_t Status
                        );

}
