/* 
 * Copyright (c) 2010, Technische Universitaet Berlin
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
 * $Revision: 1.0 $
 * $Date: 2010/08/26 16:07:34 $
 * @author: Jasper Buesch <buesch@tkn.tu-berlin.de>
 * ========================================================================
 */ 

#include "TKN154.h"
#include "app_profile.h"

module TestPanCoordinatorC
{
  uses {
    interface Boot;
    interface MLME_RESET;
    interface MLME_START;
    interface MLME_ASSOCIATE;
    interface MCPS_DATA;
    interface MLME_SET;
    interface MLME_GET;
    
    interface IEEE154TxBeaconPayload;
    interface IEEE154Frame as Frame;
    interface Packet;
    
    interface Leds;
  }

} implementation {

  event void Boot.booted()
  {
    call MLME_RESET.request(TRUE);
  }

  event void MLME_RESET.confirm(ieee154_status_t status)
  {
    if (status != IEEE154_SUCCESS)
      return;

    call MLME_SET.macShortAddress(PAN_COORDINATOR_SHORT_ADDRESS);
    call MLME_SET.macAssociationPermit(TRUE);
    call MLME_START.request(
                         PAN_ID,           // PANId
                         RADIO_CHANNEL,    // LogicalChannel
                         0,                // ChannelPage,
                         0,                // StartTime,
                         BEACON_ORDER,     // BeaconOrder
                         SUPERFRAME_ORDER, // SuperframeOrder
                         TRUE,             // PANCoordinator
                         FALSE,            // BatteryLifeExtension
                         FALSE,            // CoordRealignment
                         0,                // CoordRealignSecurity
                         0                 // BeaconSecurity
                           );

    
  }

  event void MLME_START.confirm(ieee154_status_t status)
  {
    if (status != IEEE154_SUCCESS)
      call MLME_RESET.request(TRUE);
  }

  event message_t* MCPS_DATA.indication(message_t* frame)
  {
    // we received a packet from the "router" -> toggle LED1
    call Leds.led1Toggle();
    return frame;
  }

  event void MCPS_DATA.confirm(
                         message_t *msg,
                         uint8_t msduHandle,
                         ieee154_status_t status,
                         uint32_t timestamp
                              )
  {
  }  

  /* ------------------------------------------------------------------------------ */

  event void MLME_ASSOCIATE.confirm(
                         uint16_t assocShortAddress,
                         uint8_t status,
                         ieee154_security_t *security
                                   )
  {
  }

  event void MLME_ASSOCIATE.indication(
                         uint64_t deviceAddress,
                         ieee154_CapabilityInformation_t capabilityInformation,
                         ieee154_security_t *security
                                      )
  {
    call MLME_ASSOCIATE.response(
                         deviceAddress,
                         ROUTER_SHORT_ADDRESS,
                         IEEE154_ASSOCIATION_SUCCESSFUL,
                         0
                                );
  }

  /* ------------------------------------------------------------------------------ */

  event void IEEE154TxBeaconPayload.aboutToTransmit() { }

  event void IEEE154TxBeaconPayload.setBeaconPayloadDone(void *beaconPayload, uint8_t length) { }

  event void IEEE154TxBeaconPayload.modifyBeaconPayloadDone(uint8_t offset, void *buffer, uint8_t bufferLength) { }

  event void IEEE154TxBeaconPayload.beaconTransmitted()
  {
    call Leds.led2Toggle();
  }  
  
}
