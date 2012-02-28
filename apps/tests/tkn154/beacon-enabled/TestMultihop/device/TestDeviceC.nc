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

module TestDeviceC
{
  uses {
    interface Boot;
    interface MLME_RESET;
    interface MLME_SCAN;
    interface MLME_SYNC;
    interface MLME_SYNC_LOSS;
    interface MLME_BEACON_NOTIFY;
    interface MLME_ASSOCIATE;
    interface MCPS_DATA;
    interface MLME_SET;
    interface MLME_GET;

    interface IEEE154Frame as Frame;
    interface IEEE154BeaconFrame as BeaconFrame;
    interface Packet;

    interface Leds;
    interface Timer<T62500hz> as DataTimer;
  }
} implementation {

  ieee154_CapabilityInformation_t m_capabilityInformation;
  ieee154_PANDescriptor_t m_panDescriptor;
  message_t m_frame;
  bool m_routerWasFound;
  bool m_associatedToRouter;
  bool m_dataConfirmPending;
  uint8_t m_payloadLen;
  void scanForRouter();

  event void Boot.booted()
  {
    m_capabilityInformation.AlternatePANCoordinator = 0;
    m_capabilityInformation.DeviceType = 0;
    m_capabilityInformation.PowerSource = 0;
    m_capabilityInformation.ReceiverOnWhenIdle = 0;
    m_capabilityInformation.Reserved = 0;
    m_capabilityInformation.SecurityCapability = 0;
    m_capabilityInformation.AllocateAddress = 1;
    call MLME_RESET.request(TRUE);
  }

  event void MLME_RESET.confirm(ieee154_status_t status)
  {
    char myPayload[] = "This is a packet for the PAN Coordinator!";
    uint8_t *p;

    m_payloadLen = strlen(myPayload);
    p =  call Packet.getPayload(&m_frame, m_payloadLen);
    if (status == IEEE154_SUCCESS && p != NULL)
    {
      memcpy(p, myPayload, m_payloadLen);
      scanForRouter();
    }
  }

  void scanForRouter()
  {
    ieee154_phyChannelsSupported_t channel;
    // we only scan the single channel on which we expect the Router
    uint8_t scanDuration = BEACON_ORDER;

    channel = ((uint32_t) 1) << RADIO_CHANNEL;

    // we want to be signalled every single beacon that is received during the 
    // channel SCAN-phase, that's why we set  "macAutoRequest" to FALSE
    call MLME_SET.macAutoRequest(FALSE);
    m_routerWasFound = FALSE;
    m_associatedToRouter = FALSE;
    call MLME_SCAN.request(
        PASSIVE_SCAN,           // ScanType
        channel,                // ScanChannels
        scanDuration,           // ScanDuration
        0x00,                   // ChannelPage
        0,                      // EnergyDetectListNumEntries
        NULL,                   // EnergyDetectList
        0,                      // PANDescriptorListNumEntries
        NULL,                   // PANDescriptorList
        0                       // security
        );
  }

  event message_t* MLME_BEACON_NOTIFY.indication(message_t* frame)
  {
    ieee154_phyCurrentPage_t page = call MLME_GET.phyCurrentPage();

    if (m_associatedToRouter) {
      // we are already associated to the Router
      // and just received one of its periodic beacons
      call Leds.led2Toggle();
      return frame;
    } else {
      // we have received "some" beacon during the SCAN-phase, let's
      // check if it is the beacon from our Router
      if (!m_routerWasFound && call BeaconFrame.parsePANDescriptor(
            frame, RADIO_CHANNEL, page, &m_panDescriptor) == SUCCESS) {
        if (m_panDescriptor.CoordAddrMode == ADDR_MODE_SHORT_ADDRESS &&
            m_panDescriptor.CoordPANId == PAN_ID &&
            m_panDescriptor.CoordAddress.shortAddress == ROUTER_SHORT_ADDRESS) {
          m_routerWasFound = TRUE; // yes!
        }
      }
    }
    return frame;
  }

  event void MLME_SCAN.confirm(
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
    if (m_routerWasFound) {
      // our Router is out there sending beacons, 
      // let's try to associate with it
      call MLME_SET.macCoordShortAddress(m_panDescriptor.CoordAddress.shortAddress);
      call MLME_SET.macPANId(m_panDescriptor.CoordPANId);
      call MLME_SYNC.request(m_panDescriptor.LogicalChannel, m_panDescriptor.ChannelPage, TRUE);

      call MLME_ASSOCIATE.request(
          m_panDescriptor.LogicalChannel,  // LogicalChannel 
          m_panDescriptor.ChannelPage,     // ChannelPage
          ADDR_MODE_SHORT_ADDRESS,         // CoordAddrMode
          PAN_ID,                          // CoordPANID
          m_panDescriptor.CoordAddress,    // CoordAddress
          m_capabilityInformation,         // CapabilityInformation
          0                                // Security
          );                              

    } else {
      scanForRouter();
    }
  }

  event void MLME_ASSOCIATE.confirm(
      uint16_t AssocShortAddress,
      uint8_t status,
      ieee154_security_t *security
      )
  {
    if (status == IEEE154_ASSOCIATION_SUCCESSFUL) {
      m_associatedToRouter = TRUE;
      call MLME_SET.macShortAddress(AssocShortAddress);
      call Leds.led1Off();
      call DataTimer.startPeriodic(DATA_TRANSFER_PERIOD);
    } else {
      scanForRouter();
    }
  }

  event void DataTimer.fired()
  {
    ieee154_address_t deviceShortAddress;
    deviceShortAddress.shortAddress = ROUTER_SHORT_ADDRESS; // destination

    if (!m_associatedToRouter || m_dataConfirmPending)
      return;


    call Frame.setAddressingFields(
        &m_frame,                
        ADDR_MODE_SHORT_ADDRESS, // SrcAddrMode,
        ADDR_MODE_SHORT_ADDRESS, // DstAddrMode,
        PAN_ID,                  // DstPANId,
        &deviceShortAddress,     // DstAddr,
        NULL                     // security
        );      

    if (call MCPS_DATA.request(
        &m_frame,                            // msdu,
        m_payloadLen,                        // payloadLength,
        0,                                   // msduHandle,
        TX_OPTIONS_ACK                       // TxOptions,
        ) == IEEE154_SUCCESS)
      m_dataConfirmPending = TRUE;

    call Leds.led1Toggle();
  }

  event void MCPS_DATA.confirm(
      message_t *msg,
      uint8_t msduHandle,
      ieee154_status_t status,
      uint32_t Timestamp
      )
  {
    m_dataConfirmPending = FALSE;
  }

  event void MLME_SYNC_LOSS.indication(
      ieee154_status_t lossReason,
      uint16_t PANId, 
      uint8_t LogicalChannel, 
      uint8_t ChannelPage, 
      ieee154_security_t *security
      )
  {
    call DataTimer.stop();
    scanForRouter();
  }

  event message_t* MCPS_DATA.indication(message_t* frame)
  {
    return frame;
  }


  event void MLME_ASSOCIATE.indication(
      uint64_t DeviceAddress,
      ieee154_CapabilityInformation_t CapabilityInformation,
      ieee154_security_t *security
      ) { }

}
