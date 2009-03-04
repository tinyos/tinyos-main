
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
 * $Date: 2009-03-04 18:31:42 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 * MLME-SAP receiver state primitives define how a device can enable
 * or disable the receiver at a given time. (IEEE 802.15.4-2006, Sect.
 * 7.1.10)
 */

#include "TKN154.h"
interface MLME_RX_ENABLE {

  /**
   * Allows the next higher layer to request that the receiver is
   * enabled for a finite period of time
   * 
   * @param DeferPermit TRUE if the receiver enable can be deferred until
   *                    during the next superframe if the requested time has
   *                    already passed
   * @param RxOnTime The number of symbols from the start of the superframe 
   *                 before the receiver is to be enabled.  The precision 
   *                 of this value is a minimum of 20 bits.  This parameter 
   *                 is ignored for nonbeacon-enabled PANs
   * @param RxOnDuration The number of symbols for which the receiver 
   *                     is to be enabled
   * @return       IEEE154_SUCCESS if the request succeeded and a confirm event
   *               will be signalled, an appropriate error code otherwise 
   *               (no confirm event will be signalled in this case)
   * @see          confirm
   */
  command ieee154_status_t request  (
                          bool DeferPermit,
                          uint32_t RxOnTime,
                          uint32_t RxOnDuration
                        );

  /**
   * Reports the results of the attempt to enable the receiver
   *
   * @param status The status of the receiver enable request
   */
  event void confirm    (
                          ieee154_status_t status
                        );

}
