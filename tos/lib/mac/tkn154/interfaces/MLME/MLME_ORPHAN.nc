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
 * MLME-SAP orphan notification primitives define how a coordinator
 * can issue a notification of an orphaned device. (IEEE 802.15.4-2006,
 * Sect. 7.1.8)
 */

#include "TKN154.h" 
interface MLME_ORPHAN {

  /**
   * Allows the MLME of a coordinator to notify the next higher layer of the
   * presence of an orphaned device
   * 
   * @param OrphanAddress The 64-bit extended address of the orphaned device
   * @param security        The security options (NULL means security is 
   *                        disabled)
  */
  event void indication (
                          uint64_t OrphanAddress,
                          ieee154_security_t *security
                        );

  /**
   * Allows the next higher layer of a coordinator to respond to the
   * indication primitive
   *
   * @param OrphanAddres The 64-bit extended address of the orphaned device
   * @param ShortAddress The 16-bit short address allocated to the orphaned
   *                     device if it is associated with this coordinator. The
   *                     special short address 0xfffe indicates that no short
   *                     address was allocated, and the device will use its
   *                     64-bit extended address in all communications. If the
   *                     device was not associated with this coordinator, this
   *                     field will contain the value 0xffff and be ignored on
   *                     receipt.
   * @param AssociatedMember TRUE if the orphaned device is associated 
   *                         with this coordinator
   * @param security        The security options (NULL means security is 
   *                        disabled)
   * @return       IEEE154_SUCCESS if the request succeeded and an indication event
   *               will be signalled through the MLME_COMM_STATUS interface later,  
   *               otherwise an appropriate error code (no MLME_COMM_STATUS.indication 
   *               event will be signalled in this case)
   */
  command ieee154_status_t response (
                          uint64_t OrphanAddres,
                          uint16_t ShortAddress,
                          bool AssociatedMember,
                          ieee154_security_t *security
                        );
}
