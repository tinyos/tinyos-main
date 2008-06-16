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
 * $Date: 2008-06-16 18:00:31 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "TKN154.h"
interface MLME_RESET {

  /**
   * Allows the next higher layer to request that the MLME performs a
   * reset operation. This command initializes the MAC and must be called 
   * before calling any other MAC primitive. It extends the standard  
   * interface definition by a parameter <tt>PANType</tt>, which defines 
   * whether the device/coordinator will operate on a beacon-enabled PAN
   * or on a nonbeacon-enabled PAN.
   *
   * Two things are important:
   * (1) This command will fail while promiscuous mode is enabled 
   * (promiscuous mode is controlled through a separate SplitControl 
   * interface). (2) While the MLME_RESET.confirm is pending the next
   * higher layer MUST NOT call any MAC commands; if there are any
   * other pending request the MAC will signal their corresponding confirm 
   * events before MLME_RESET.confirm is signalled (with a status code of
   * IEEE154_TRANSACTION_OVERFLOW).
   * 
   * @param SetDefaultPIB If TRUE, the MAC sublayer is reset and all MAC PIB
   *                      attributes are set to their default values.  If
   *                      FALSE, the MAC sublayer is reset but all MAC PIB
   *                      attributes retain their values prior to the
   *                      generation of the reset primitive.
   * @param PANType       Either BEACON_ENABLED_PAN for beacon-enabled PANs
   *                      or NONBEACON_ENABLED_PAN for nonbeacon-enabled PANs
   *
   * @return       IEEE154_SUCCESS if the request succeeded and a confirm event
   *               will be signalled, an appropriate error code otherwise 
   *               (no confirm event will be signalled in this case)
   *                      
   */
  command ieee154_status_t request  (
                          bool SetDefaultPIB,
                          uint8_t PANType
                        );

  /**
   * Reports the results of the reset operation
   *
   * @param status The status of the reset operation
   */
  event void confirm    (
                          ieee154_status_t status
                        );

}
