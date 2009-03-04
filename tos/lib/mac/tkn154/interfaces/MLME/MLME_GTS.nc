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
 * The MLME-SAP GTS management primitives define how GTSs are
 * requested and maintained. A device wishing to use these primitives
 * and GTSs in general will already be tracking the beacons of its PAN
 * coordinator. (IEEE 802.15.4-2006, Sect. 7.1.7)
 */

#include "TKN154.h"
interface MLME_GTS {

  /**
   * Request allocation of a new GTS or deallocation from the PAN
   * coordinator.
   *
   * @param GtsCharacteristics The characteristics of the GTS request
   * @param security      The security options (NULL means security is 
   *                      disabled)
   * @return       IEEE154_SUCCESS if the request succeeded and a confirm event
   *               will be signalled, an appropriate error code otherwise 
   *               (no confirm event will be signalled in this case)
   * @see          confirm
   */
  command ieee154_status_t request  (
                          uint8_t GtsCharacteristics,
                          ieee154_security_t *security
                        );

  /**
   * Reports the results of a request to allocated a new GTS or
   * deallocate an existing GTS
   *
   * @param GtsCharacteristics The characteristics of the GTS request
   * @param status The status of the GTS request
   */
  event void confirm    (
                          uint8_t GtsCharacteristics,
                          ieee154_status_t status
                        );

  /**
   * Indicates that a GTS has been allocated or that a previously allocated
   * GTS has been deallocated
   *
   * All pointers are valid only until the return of this event.
   * 
   * @param DeviceAddress Short address of the device that has been allocated
   *                   or deallocated a GTS
   * @param GtsCharacteristics The characteristics of the GTS request
   * @param security        The security options, NULL means security is 
   *                        disabled
   */   
  event void indication (
                          uint16_t DeviceAddress,
                          uint8_t GtsCharacteristics,
                          ieee154_security_t *security
                        );

}
