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
 * $Date: 2008-07-21 15:18:16 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "TKN154.h"
#include "app_profile.h"
module TestCoordSenderC
{
  uses {
    interface Boot;
    interface MCPS_DATA;
    interface MLME_RESET;
    interface MLME_START;
    interface MLME_SET;
    interface MLME_GET;
    interface Leds;
    interface IEEE154Frame as Frame;
    interface IEEE154TxBeaconPayload;
    interface Packet;
  }
} implementation {

  message_t m_frame;
  uint8_t m_payloadLen;

  event void Boot.booted() {
    char payload[] = "Hello Device!";
    uint8_t *payloadRegion;
    ieee154_address_t deviceShortAddress;

    // construct the frame
    m_payloadLen = strlen(payload);
    payloadRegion = call Packet.getPayload(&m_frame, m_payloadLen);
    deviceShortAddress.shortAddress = DEVICE_ADDRESS; // destination
    if (m_payloadLen <= call Packet.maxPayloadLength()){
      memcpy(payloadRegion, payload, m_payloadLen);
      call Frame.setAddressingFields(
          &m_frame,                
          ADDR_MODE_SHORT_ADDRESS, // SrcAddrMode,
          ADDR_MODE_SHORT_ADDRESS, // DstAddrMode,
          PAN_ID,                  // DstPANId,
          &deviceShortAddress,     // DstAddr,
          NULL                     // security
          );
      call MLME_RESET.request(TRUE, BEACON_ENABLED_PAN);
    }
  }

  event void MLME_RESET.confirm(ieee154_status_t status)
  {
    if (status != IEEE154_SUCCESS)
      return;
    call MLME_SET.macShortAddress(COORDINATOR_ADDRESS);
    call MLME_SET.macAssociationPermit(FALSE);
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

  void dataRequest()
  {
    call MCPS_DATA.request  (
        &m_frame,                                 // msdu,
        m_payloadLen,                             // payloadLength,
        0,                                        // msduHandle,
        TX_OPTIONS_ACK | TX_OPTIONS_INDIRECT      // TxOptions,
        );
  }

  event void MLME_START.confirm(ieee154_status_t status)
  {
    if (status == IEEE154_SUCCESS)
      dataRequest();
  }

  event void MCPS_DATA.confirm(
                          message_t *msg,
                          uint8_t msduHandle,
                          ieee154_status_t status,
                          uint32_t Timestamp
                        )
  {
    if (status == IEEE154_SUCCESS)
      call Leds.led1Toggle();
    dataRequest();
  }

  event message_t* MCPS_DATA.indication ( message_t* frame)
  {
    return frame;
  }

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
