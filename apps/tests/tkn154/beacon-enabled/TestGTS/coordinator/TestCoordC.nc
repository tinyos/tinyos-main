/*
 * Copyright (c) 2010, CISTER/ISEP - Polytechnic Institute of Porto
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
 * 
 * 
 * 
 * @author Ricardo Severino <rars@isep.ipp.pt>
 * @author Stefano Tennina <sota@isep.ipp.pt>
 * ========================================================================
 */

#include "TKN154.h"
#include "app_profile.h"

module TestCoordC
{
  uses {
    interface Boot;
    interface MCPS_DATA;
    interface MLME_RESET;
    interface MLME_START;
    interface MLME_SET;
    interface MLME_GET;
    interface IEEE154Frame as Frame;
    interface IEEE154TxBeaconPayload;
    interface Leds;
    interface MLME_GTS;
    interface Packet;
  }
}
implementation 
{
  bool m_ledCount;
  uint8_t m_payloadLen;

  uint8_t m_gotSlot;
  uint8_t m_messageCount;
  message_t m_frame;
  ieee154_address_t m_destAddr;
  message_t m_frame;
  ieee154_address_t m_dstAddr;
  uint8_t *payloadRegion;

  bool GtsGetDirection(uint8_t gtsCharacteristics)
  {
    if ( (gtsCharacteristics & 0x10) == 0x10)
      return GTS_RX_DIRECTION;
    else
      return GTS_TX_DIRECTION;
  }  

  event void Boot.booted() 
  {
    char payload[]="GTS TEST!";
    m_messageCount=0;
    m_payloadLen=strlen(payload);
    payloadRegion=call Packet.getPayload(&m_frame, m_payloadLen);

    if (m_payloadLen <= call Packet.maxPayloadLength()){
      memcpy(payloadRegion, payload, m_payloadLen);
      m_gotSlot=0;
      call MLME_RESET.request(TRUE);
    }  
  }

  event void MLME_RESET.confirm(ieee154_status_t status)
  {
    if (status != IEEE154_SUCCESS)
      return;
    call MLME_SET.macShortAddress(COORDINATOR_ADDRESS);
    call MLME_SET.macAssociationPermit(FALSE);
    call MLME_SET.macGTSPermit(TRUE);  //RARS GTS
    call MLME_START.request(
                          PAN_ID,               // PANId
                          RADIO_CHANNEL,        // LogicalChannel
                          0,                    // ChannelPage,
                          0,                    // StartTime,
                          BEACON_ORDER,         // BeaconOrder
                          SUPERFRAME_ORDER,     // SuperframeOrder
                          TRUE,                 // PANCoordinator
                          FALSE,                // BatteryLifeExtension
                          FALSE,                // CoordRealignment
                          0,                    // CoordRealignSecurity,
                          0                     // BeaconSecurity
                        );
  }


  task void packetSendTask()
  {
    call Frame.setAddressingFields(
          &m_frame,                
          ADDR_MODE_SHORT_ADDRESS,        // SrcAddrMode,
          ADDR_MODE_SHORT_ADDRESS,        // DstAddrMode,
          call MLME_GET.macPANId(),     // DstPANId,
          &m_dstAddr,  // DstAddr,
          NULL                            // security
          );
    m_messageCount++; 
    if (m_messageCount <  10) {
      call MCPS_DATA.request  (
          &m_frame,                         // frame,
          m_payloadLen,                     // payloadLength,
          0,                                // msduHandle,
          TX_OPTIONS_ACK | TX_OPTIONS_GTS // TxOptions,
          );    
    }
  }

  event message_t* MCPS_DATA.indication ( message_t* frame )
  {
    call Leds.led1Toggle();
    return frame;
  }

  event void MLME_START.confirm(ieee154_status_t status) {}

  event void MCPS_DATA.confirm(
                          message_t *msg,
                          uint8_t msduHandle,
                          ieee154_status_t status,
                          uint32_t Timestamp
                        ) { }

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
    if (m_gotSlot)
      post packetSendTask();
  }

  event void MLME_GTS.indication (
                          uint16_t DeviceAddress,
                          uint8_t GtsCharacteristics,
                          ieee154_security_t *security
                        )
  {
    if (GtsGetDirection(GtsCharacteristics) == GTS_RX_DIRECTION && m_gotSlot == 0)
    {
      m_dstAddr.shortAddress=DeviceAddress;
      m_gotSlot=1;
      m_messageCount=0;
      post packetSendTask();
    }
  }

  event void MLME_GTS.confirm (
                          uint8_t GtsCharacteristics,
                          ieee154_status_t status
                        ){}

}
