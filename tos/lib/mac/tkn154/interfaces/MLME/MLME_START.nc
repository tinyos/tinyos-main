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
 * $Date: 2009-04-17 14:47:09 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 * MLME-SAP start primitives define how an FFD can request to start
 * using a new superframe configuration in order to initiate a PAN,
 * begin transmitting beacons on an already existing PAN, thus
 * facilitating device discovery, or to stop transmitting beacons.
 * (IEEE 802.15.4-2006, Sect. 7.1.14)
 */

#include "TKN154.h"
interface MLME_START {

  /**
   * Requests to start using a new superframe configuration.
   * 
   * @param PANId The PAN identifier to be used by the device
   * @param LogicalChannel The logical channel on which to start transmitting
   *                       beacons
   * @param ChannelPage The channel page on which to begin using the new 
   *                    superframe configuration.
   * @param StartTime The time at which to begin transmitting beacons. If this
   *                  parameter is equal to 0x000000, beacon transmissions 
   *                  will begin immediately. Otherwise, the specified time is
   *                  relative to the received beacon of the coordinator with
   *                  which the device synchronizes.
   *                  This parameter is ignored if either the beaconOrder 
   *                  parameter has a value of 15 or the panCoordinator
   *                  parameter is TRUE.The time is specified in symbols and
   *                  is rounded to a backoff slot boundary. This is a 24-bit
   *                  value, and the precision of this value shall be a
   *                  minimum of 20 bits, with the lowest 4 bits being the 
   *                  least significant.
   * @param BeaconOrder The beacon order of the superframe
   * @param SuperframeOrder The superframe order of the superframe
   * @param PanCoordinator If TRUE, the device will become the PAN coordinator
   *                       of a new PAN.  If FALSE, the device will begin
   *                       transmitting beacons on the PAN with which it 
   *                       is associated
   * @param BatteryLifeExtension If TRUE, the receiver of the beaconing
   *                             device is disabled after the IFS period
   * @param CoordRealignment TRUE if a coordinator realignment command is to
   *                         be transmitted prior to changing the superframe
   *                         configuration
   * @param coordRealignSecurity The security options for the coordinator
   *                         realignment command (NULL means security
   *                         is disabled)
   * @param beaconSecurity The security options for beacon frames
   *                         (NULL means security is disabled)
   *
   * @return       IEEE154_SUCCESS if the request succeeded and a confirm event
   *               will be signalled, an appropriate error code otherwise 
   *               (no confirm event will be signalled in this case)
   * @see          confirm
  */
  command ieee154_status_t request  (
                          uint16_t PANId,
                          uint8_t LogicalChannel,
                          uint8_t ChannelPage,
                          uint32_t StartTime,
                          uint8_t BeaconOrder,
                          uint8_t SuperframeOrder,
                          bool PanCoordinator,
                          bool BatteryLifeExtension,
                          bool CoordRealignment,
                          ieee154_security_t *coordRealignSecurity,
                          ieee154_security_t *beaconSecurity
                        );

  /**
   * Signalled in response to a successful request.
   * Reports the results of the attempt to start using a new superframe
   * configuration
   *
   * @param status The result of the attempt to start using an 
   *               updated superframe configuration
   */
  event void confirm    (
                          ieee154_status_t status
                        );

}
