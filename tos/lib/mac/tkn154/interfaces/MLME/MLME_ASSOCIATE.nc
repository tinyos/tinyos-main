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
 * $Date: 2009-03-04 18:31:40 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 * MLME-SAP association primitives define how a device becomes
 * associated with a PAN. (IEEE 802.15.4-2006, Sect. 7.1.3)
 */

#include "TKN154.h"

interface MLME_ASSOCIATE {

  /**
   * Requests to associate with a PAN.
   * 
   * @param LogicalChannel  The logical channel on which to attempt
   *                        association
   * @param ChannelPage     The channel page on which to attempt association
   * @param CoordAddrMode   The coordinator addressing mode
   * @param CoordPANID      The 16 bit PAN identifier of the coordinator
   * @param CoordAddress    Individual device address of the coordinator as
   *                        per the CoordAddrMode
   * @param CapabilityInformation Specifies the operational capabilities
   *                        of the associating device
   * @param security        The security options (NULL means security is 
   *                        disabled)
   *
   * @return       IEEE154_SUCCESS if the request succeeded and a confirm event
   *               will be signalled, an appropriate error code otherwise 
   *               (no confirm event will be signalled in this case)
   * @see          confirm
   */
  command ieee154_status_t request  (
                          uint8_t LogicalChannel,
                          uint8_t ChannelPage,
                          uint8_t CoordAddrMode,
                          uint16_t CoordPANID,
                          ieee154_address_t CoordAddress,
                          ieee154_CapabilityInformation_t CapabilityInformation,
                          ieee154_security_t *security
                        );

  /**
   * Notification that a device has requested to associate with this PAN.
   *
   * @param DeviceAddress the 64-bit address of the requesting device
   * @param CapabilityInformation Specifies the operational capabilities
   *                              of the associating device
   * @param security      The security options (NULL means security is 
   *                      disabled)
   */
  event void indication (
                          uint64_t DeviceAddress,
                          ieee154_CapabilityInformation_t CapabilityInformation,
                          ieee154_security_t *security
                        );

  /**
   * Sends a response to a device that requested to associate with this PAN.
   *
   * @param DeviceAddress     The 64-bit address of the device to respond to
   * @param AssocShortAddress The short device address allocated by the
   *                          coordinator on successful allocation.
   * @param status          The status of the association attempt
   * @param security        The security options (NULL means security is 
   *                        disabled)
   *
   * @return IEEE154_SUCCESS if the request succeeded and an indication event
   *         will be signalled through the MLME_COMM_STATUS interface later,  
   *         an appropriate error code otherwise (no MLME_COMM_STATUS.indication
   *         event will be signalled in this case)
   */
  command ieee154_status_t response (
                          uint64_t DeviceAddress,
                          uint16_t AssocShortAddress,
                          ieee154_association_status_t status,
                          ieee154_security_t *security
                        );

  /**
   * Confirms an association attempt.
   *
   * @param AssocShortAddress The short device address allocated by the
   *                          coordinator on successful association
   * @param status          The status of the association attempt
   * @param security        The security options, NULL means security is 
   *                        disabled
   */
  event void confirm    (
                          uint16_t AssocShortAddress,
                          uint8_t status,
                          ieee154_security_t *security
                        );

}
