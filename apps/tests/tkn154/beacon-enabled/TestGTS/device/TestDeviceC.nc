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
#include "GTS.h"

module TestDeviceC
{
  uses {
    interface Boot;
    interface MCPS_DATA;
    interface MLME_RESET;
    interface MLME_SET;
    interface MLME_GET;
    interface MLME_SCAN;
    interface MLME_SYNC;
    interface MLME_BEACON_NOTIFY;
    interface MLME_SYNC_LOSS;
    interface IEEE154Frame as Frame;
    interface IEEE154BeaconFrame as BeaconFrame;
    interface Leds;
    interface Packet;
    interface MLME_GTS;
  }
}
 implementation 
{
  message_t m_frame;
  uint8_t m_payloadLen;
  ieee154_PANDescriptor_t m_PANDescriptor;
  bool m_ledCount;
  bool m_wasScanSuccessful;
  void startApp();
  uint8_t m_messageCount;
  task void packetSendTask();
  norace uint8_t m_step;
  uint8_t m_gtsCharacteristics;

  uint8_t GtsSetCharacteristics(uint8_t gtsLength, uint8_t gtsDirection, uint8_t characteristicType)
  {
    return ( (gtsLength << 0) | (gtsDirection << 4) | (characteristicType << 5));
  }  

  event void Boot.booted() {
    char payload[]="GTS TEST!";
    uint8_t *payloadRegion;
    m_payloadLen=strlen(payload);
    payloadRegion=call Packet.getPayload(&m_frame, m_payloadLen);
    if (m_payloadLen <= call Packet.maxPayloadLength()){
      memcpy(payloadRegion, payload, m_payloadLen);
      call MLME_RESET.request(TRUE);
    }
  }

  event void MLME_RESET.confirm(ieee154_status_t status)
  {
    if (status == IEEE154_SUCCESS)
      startApp();
  }

  void startApp()
  {
    ieee154_phyChannelsSupported_t channelMask;
    uint8_t scanDuration = BEACON_ORDER;
    call MLME_SET.macShortAddress(TOS_NODE_ID);
    // scan only the channel where we expect the coordinator
    channelMask = ((uint32_t) 1) << RADIO_CHANNEL;
    // we want all received beacons to be signalled 
    // through the MLME_BEACON_NOTIFY interface, i.e.
    // we set the macAutoRequest attribute to FALSE
    call MLME_SET.macAutoRequest(FALSE);
    m_wasScanSuccessful = FALSE;
    call MLME_SCAN.request  (
                           PASSIVE_SCAN,           // ScanType
                           channelMask,            // ScanChannels
                           scanDuration,           // ScanDuration
                           0x00,                   // ChannelPage
                           0,                      // EnergyDetectListNumEntries
                           NULL,                   // EnergyDetectList
                           0,                      // PANDescriptorListNumEntries
                           NULL,                   // PANDescriptorListGtsSetCharacteristics
                           0                       // security
                        );
  }

  event message_t* MLME_BEACON_NOTIFY.indication (message_t* frame)
  {
    // received a beacon frame
    ieee154_phyCurrentPage_t page = call MLME_GET.phyCurrentPage();
    ieee154_macBSN_t beaconSequenceNumber = call BeaconFrame.getBSN(frame);
    if (!m_wasScanSuccessful) {
      // received a beacon during channel scanning
      if (call BeaconFrame.parsePANDescriptor(
            frame, RADIO_CHANNEL, page, &m_PANDescriptor) == SUCCESS) {
        // let's see if the beacon is from our coordinator...
        if (m_PANDescriptor.CoordAddrMode == ADDR_MODE_SHORT_ADDRESS &&
            m_PANDescriptor.CoordPANId == PAN_ID &&
            m_PANDescriptor.CoordAddress.shortAddress == COORDINATOR_ADDRESS){
          // yes! wait until SCAN is finished, then syncronize to the beacons
          m_wasScanSuccessful = TRUE;
        }
      }
    } else { 
      // received a beacon during synchronization, toggle LED2
      if (beaconSequenceNumber & 1)
        call Leds.led2On();
      else
        call Leds.led2Off();   
    }
    if (m_step == 1)
      post packetSendTask();
    return frame;
  }

  event void MLME_SCAN.confirm    (
                          ieee154_status_t status,
                          uint8_t ScanType,
                          uint8_t ChannelPage,
                          uint32_t UnscannedChannels,
                          uint8_t EnergyDetectListNumEntries,
                          int8_t* EnergyDetectList,
                          uint8_t PANDescriptorListNumEntries,
                          ieee154_PANDescriptor_t* PANDescriptorList
                        )
  {
    if (m_wasScanSuccessful) {
      // we received a beacon from the coordinator before
      call MLME_SET.macCoordShortAddress(m_PANDescriptor.CoordAddress.shortAddress);
      call MLME_SET.macPANId(m_PANDescriptor.CoordPANId);
      call MLME_SYNC.request(m_PANDescriptor.LogicalChannel, m_PANDescriptor.ChannelPage, TRUE);
      call Frame.setAddressingFields(
          &m_frame,                
          ADDR_MODE_SHORT_ADDRESS,        // SrcAddrMode,
          ADDR_MODE_SHORT_ADDRESS,        // DstAddrMode,
          m_PANDescriptor.CoordPANId,     // DstPANId,
          &m_PANDescriptor.CoordAddress,  // DstAddr,
          NULL                            // security
          );
      // allocate a gts for TX - GTS 1
      m_gtsCharacteristics=GtsSetCharacteristics(2,GTS_TX_DIRECTION,1); //setup gts characteristics
      //1st argument: 		number of slots
      //2nd argument:		Gts direction (tx or rx)
      //3rd argument:		characteristicType (Allocation or Deallocation)
      call MLME_GTS.request(m_gtsCharacteristics,0); //send the gts slot request
      call Leds.led1On();
    } else
      startApp();
  }

  task void packetSendTask()
  {
    if (!m_wasScanSuccessful)
      return;
    m_messageCount++;
    if (m_messageCount == 3 && m_step == 1) { // allocate a second gts for RX - GTS 2
        m_gtsCharacteristics=GtsSetCharacteristics(2,GTS_RX_DIRECTION,1); //setup gts characteristics
        call MLME_GTS.request(m_gtsCharacteristics,0); //send the gts slot request      
        return;
    }
    if (m_messageCount <  7 && m_step == 1) {
      call MCPS_DATA.request  (
          &m_frame,                         // frame,
          m_payloadLen,                     // payloadLength,
          0,                                // msduHandle,
          TX_OPTIONS_ACK | TX_OPTIONS_GTS // TxOptions,
          );
    }
    else {
      m_step=2;
      //deallocate GTS 1
      m_gtsCharacteristics=GtsSetCharacteristics(2,GTS_TX_DIRECTION,0); //setup gts characteristics
      call MLME_GTS.request(m_gtsCharacteristics,0); //send the gts slot request
    }
  }

  event void MCPS_DATA.confirm    (
                          message_t *msg,
                          uint8_t msduHandle,
                          ieee154_status_t status,
                          uint32_t timestamp
                        )
  {}

  event void MLME_SYNC_LOSS.indication(
                          ieee154_status_t lossReason,
                          uint16_t PANId,
                          uint8_t LogicalChannel,
                          uint8_t ChannelPage,
                          ieee154_security_t *security)
  {
    m_wasScanSuccessful = FALSE;
    call Leds.led1Off();
    call Leds.led2Off();
    call Leds.led0On();
    
	m_messageCount=0;
	m_step=0;
    startApp();
  }

  event message_t* MCPS_DATA.indication (message_t* frame)
  {
    // we don't expect data
    return frame;
  }

  event void MLME_GTS.indication (
                          uint16_t DeviceAddress,
                          uint8_t GtsCharacteristics,
                          ieee154_security_t *security
                        ){}

  event void MLME_GTS.confirm    (
                          uint8_t GtsCharacteristics,
                          ieee154_status_t status
                        )
  {
    if (status == IEEE154_SUCCESS && m_step==0) {
      m_step=1;
      call Leds.led1Off();
      call Leds.led0Off();
    }
  }
}
