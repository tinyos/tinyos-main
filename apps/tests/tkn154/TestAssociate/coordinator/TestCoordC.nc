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
 * $Date: 2008-07-21 14:56:59 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "TKN154.h"
#include "app_profile.h"
module TestCoordC
{
  uses {
    interface Boot;
    interface MLME_RESET;
    interface MLME_START;
    interface MLME_ASSOCIATE;
    interface MLME_DISASSOCIATE;
    interface MLME_COMM_STATUS;
    interface MLME_SET;
    interface MLME_GET;
    interface IEEE154Frame as Frame;
    interface IEEE154TxBeaconPayload;
    interface Leds;
  }
} implementation {

  ieee154_address_t m_lastDevice;
  uint16_t m_shortAddress;

  event void Boot.booted() {
    call MLME_RESET.request(TRUE, BEACON_ENABLED_PAN);
  }

  event void MLME_RESET.confirm(ieee154_status_t status)
  {
    if (status != IEEE154_SUCCESS)
      return;
    call MLME_SET.macShortAddress(COORDINATOR_ADDRESS);
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
                          0,                // no realignment security
                          0                 // no beacon security
                        );
  }

  event void MLME_START.confirm(ieee154_status_t status) { }

  event void MLME_ASSOCIATE.indication (
                          uint64_t DeviceAddress,
                          ieee154_CapabilityInformation_t CapabilityInformation,
                          ieee154_security_t *security
                        )
  {
    call MLME_ASSOCIATE.response(DeviceAddress, m_shortAddress++, IEEE154_ASSOCIATION_SUCCESSFUL, 0);
  }

  event void MLME_DISASSOCIATE.indication (
                          uint64_t DeviceAddress,
                          ieee154_disassociation_reason_t DisassociateReason,
                          ieee154_security_t *security
                        )
  {
    call Leds.led1Off();
  }


  event void MLME_COMM_STATUS.indication (
                          uint16_t PANId,
                          uint8_t SrcAddrMode,
                          ieee154_address_t SrcAddr,
                          uint8_t DstAddrMode,
                          ieee154_address_t DstAddr,
                          ieee154_status_t status,
                          ieee154_security_t *security
                        )
  {
    if (status == IEEE154_SUCCESS){
      // association was successful
      call Leds.led1On();
      m_lastDevice.extendedAddress = DstAddr.extendedAddress;
    } else {
      call Leds.led1Off();
    }
  }

  event void MLME_DISASSOCIATE.confirm    (
                          ieee154_status_t status,
                          uint8_t DeviceAddrMode,
                          uint16_t DevicePANID,
                          ieee154_address_t DeviceAddress
                        ){}

  event void MLME_ASSOCIATE.confirm    (
                          uint16_t AssocShortAddress,
                          uint8_t status,
                          ieee154_security_t *security
                        ){}

  event void IEEE154TxBeaconPayload.aboutToTransmit() { }

  event void IEEE154TxBeaconPayload.setBeaconPayloadDone(void *beaconPayload, uint8_t length) { }

  event void IEEE154TxBeaconPayload.modifyBeaconPayloadDone(uint8_t offset, void *buffer, uint8_t bufferLength) { }

  event void IEEE154TxBeaconPayload.beaconTransmitted() 
  {
    ieee154_macBSN_t beaconSequenceNumber = call MLME_GET.macBSN();
    if (beaconSequenceNumber & 1)
      call Leds.led2On();
    else
      call Leds.led2Off();
  }  
}
