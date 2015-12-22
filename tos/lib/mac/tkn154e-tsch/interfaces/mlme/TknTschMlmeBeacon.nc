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

interface TknTschMlmeBeacon 
{

  /**
   * The MLME-BEACON.request primitive requests the generation of a beacon or 
   * enhanced beacon in a non- beacon-enabled PAN, either in response to a beacon 
   * request command when macBeaconAutoRespond is FALSE, or on demand, e.g., 
   * to send beacons to enable a TSCH passive scan.
   * 
   * @param BeaconType  Indicates whether to send a beacon (0x00) or
                        enhanced beacon (0x01).
   * @param Channel     The channel number to use.
   * @param ChannelPage The channel page to use.
   * @param beaconSecurity   
   * @param DstAddrMode The destination addressing mode for this primitive and 
                        subsequent beacon.
   * @param DstAddr     If sent in responase to an MLME-BEACON- REQUEST.indication, 
                        the device who sent the beacon request, otherwise the short 
                        broadcast address (0xffff).
   * @param BSNSuppression If BeaconType = 0x01, then if BSNSuppression is TRUE,
                        the EBSN is omitted from the frame and the Sequence Number 
                        Suppression field of the Frame Control field is set to one.
   *
   * @return       IEEE154_SUCCESS if the request succeeded and a confirm event
   *               will be signalled, an appropriate error code otherwise 
   *               (no confirm event will be signalled in this case)
   * @see          confirm
  */
  command plain154_status_t request  (
                          uint8_t BeaconType,
                          uint8_t Channel,
                          uint8_t ChannelPage,
                          plain154_security_t *beaconSecurity,
                          uint8_t DstAddrMode,
                          plain154_address_t *DstAddr, 
                          bool BSNSuppression
                        );

  /**
   * The MLME-BEACON.confirm primitive returns a status of either SUCCESS, 
   * indicating that the request to transmit was successful, or the appropriate 
   * error code. The status values are fully described in 6.3.1.
   * 
   * @param Status  The result of the attempt to send the beacon or enhanced beacon.
                   Valid are IEEE154_SUCCESS, IEEE154_CHANNEL_ACCESS_FAILURE, 
                   IEEE154_FRAME_TOO_LONG and IEEE154_INVALID_PARAMETER
   *
   * @return       IEEE154_SUCCESS if the request succeeded and a confirm event
   *               will be signalled, an appropriate error code otherwise 
   *               (no confirm event will be signalled in this case)
   * @see          confirm
  */
  event void confirm    (
                          plain154_status_t Status
                        );

}
