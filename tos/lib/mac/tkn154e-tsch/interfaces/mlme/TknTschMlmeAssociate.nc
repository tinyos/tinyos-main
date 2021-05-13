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
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * @author Jasper Büsch <buesch@tkn.tu-berlin.de>
 */


#include "tkntsch_types.h"

interface TknTschMlmeAssociate 
{

  /**
   * Requests to associate with a TSCH PAN.
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
   * @param ChannelOffset   Specifies the offset value of Hopping Sequence.
   * @param HoppingSequenceID Indicate the ID of channel hopping sequence in use.
   *
   * @return       IEEE154_SUCCESS if the request succeeded and a confirm event
   *               will be signalled, an appropriate error code otherwise 
   *               (no confirm event will be signalled in this case)
   * @see          confirm
   */
  command plain154_status_t request  (
                          uint8_t LogicalChannel,
                          uint8_t ChannelPage,
                          uint8_t CoordAddrMode,
                          uint16_t CoordPANID,
                          plain154_address_t CoordAddress,
                          plain154_CapabilityInformation_t CapabilityInformation,
                          plain154_security_t *security,
                          uint16_t ChannelOffset,
                          uint8_t HoppingSequenceID
                        );

  /**
   * Notification that a device has requested to associate with this PAN.
   *
   * @param DeviceAddress the 64-bit address of the requesting device
   * @param CapabilityInformation Specifies the operational capabilities
   *                              of the associating device
   * @param ChannelOffset   Specifies the offset value of Hopping Sequence.
   * @param HoppingSequenceID Indicate the ID of channel hopping sequence in use.
   * @param security      The security options (NULL means security is 
   *                      disabled)
   */
  event void indication (
                          uint64_t DeviceAddress,
                          plain154_CapabilityInformation_t CapabilityInformation,
                          plain154_security_t *security,
                          uint16_t ChannelOffset,
                          uint8_t HoppingSequenceID
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
   * @param ChannelOffset   Specifies the offset value of Hopping Sequence.
   * @param HoppingSequenceLength  Specifies the length of Hopping Sequence as 
                            described in 5.1.1a.
   * @param HoppingSequence  Specifies the sequence of channel numbers that is
                            set by a higher layer as described in 5.1.1a. 
                            This parameter shall be present only if 
                            macHoppingSequenceLength is nonzero.
   *
   * @return IEEE154_SUCCESS if the request succeeded and an indication event
   *         will be signalled through the MLME_COMM_STATUS interface later,  
   *         an appropriate error code otherwise (no MLME_COMM_STATUS.indication
   *         event will be signalled in this case) 
   *         TODO: Checken if relevant for TSCH
   */
  command plain154_status_t response (
                          uint64_t DeviceAddress,
                          uint16_t AssocShortAddress,
                          plain154_association_status_t status,
                          plain154_security_t *security,
                          uint16_t ChannelOffset,
                          uint16_t HoppingSequenceLength, 
                          uint8_t* HoppingSequence
                        );

  /**
   * Confirms an association attempt.
   *
   * @param AssocShortAddress The short device address allocated by the
   *                          coordinator on successful association
   * @param status          The status of the association attempt
   * @param security        The security options, NULL means security is 
   *                        disabled
   * @param ChannelOffset   Specifies the offset value of Hopping Sequence.
   * @param HoppingSequenceLength  Specifies the length of Hopping Sequence as 
                            described in 5.1.1a.
   * @param HoppingSequence  Specifies the sequence of channel numbers that is
                            set by a higher layer as described in 5.1.1a. 
                            This parameter shall be present only if 
                            macHoppingSequenceLength is nonzero.
   */
  event void confirm    (
                          uint16_t AssocShortAddress,
                          uint8_t status,
                          plain154_security_t *security,
                          uint16_t ChannelOffset,
                          uint16_t HoppingSequenceLength, 
                          uint8_t* HoppingSequence
                        );
}
