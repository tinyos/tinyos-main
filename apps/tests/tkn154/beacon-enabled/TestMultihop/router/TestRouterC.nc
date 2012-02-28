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

module TestRouterC
{
  uses {
    interface Boot;
    interface MLME_RESET;
    interface MLME_SCAN;
    interface MLME_SYNC;
    interface MLME_SYNC_LOSS;
    interface MLME_BEACON_NOTIFY;
    interface MLME_ASSOCIATE;
    interface MLME_START;
    interface MCPS_DATA;
    interface MLME_GET;
    interface MLME_SET;

    interface IEEE154TxBeaconPayload;
    interface IEEE154BeaconFrame as BeaconFrame;
    interface IEEE154Frame as Frame;
    interface Packet;
    interface Pool<message_t> as FramePool;

    interface Leds;
  }
} implementation {

  ieee154_CapabilityInformation_t m_capabilityInformation;
  ieee154_PANDescriptor_t m_PANDescriptor;
  uint8_t m_panCoordinatorWasFound = FALSE;
  uint8_t m_associatedToPanCoord = FALSE;

  void scanForPanCoord();

  /* ------------------------------------------------------------------------------ */

  event void Boot.booted()
  {
    m_capabilityInformation.AlternatePANCoordinator = 0;
    m_capabilityInformation.DeviceType = 1;
    m_capabilityInformation.PowerSource = 0;
    m_capabilityInformation.ReceiverOnWhenIdle = 0;
    m_capabilityInformation.Reserved = 0;
    m_capabilityInformation.SecurityCapability = 0;
    m_capabilityInformation.AllocateAddress = 1;

    m_panCoordinatorWasFound = FALSE;
    m_associatedToPanCoord = FALSE;

    call MLME_RESET.request(TRUE);
  }

  event void MLME_RESET.confirm(ieee154_status_t status)
  {
    if (status != IEEE154_SUCCESS)
      return;
    else 
      scanForPanCoord();
  }

  void scanForPanCoord()
  {
    uint8_t scanDuration = BEACON_ORDER;
    // we only scan the single channel on which we expect the PAN coordinator
    ieee154_phyChannelsSupported_t channel = ((uint32_t) 1) << RADIO_CHANNEL;

    // we want to be signalled every single beacon that is received during the 
    // channel SCAN-phase, that's why we set  "macAutoRequest" to FALSE
    call MLME_SET.macAutoRequest(FALSE); 
    m_panCoordinatorWasFound = FALSE;
    m_associatedToPanCoord = FALSE;
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
    ieee154_phyCurrentPage_t page;

    if (m_associatedToPanCoord == TRUE) {
      // we are already associated with the PAN Coordinator
      // and just received one of its periodic beacons
      call Leds.led2Toggle();
    } else {
      // we have received "some" beacon during the SCAN-phase, let's
      // check if it is the beacon from our PAN Coordinator
      page = call MLME_GET.phyCurrentPage();
      if ((m_panCoordinatorWasFound == FALSE) && call BeaconFrame.parsePANDescriptor(
            frame, RADIO_CHANNEL, page, &m_PANDescriptor) == SUCCESS) {
        if (m_PANDescriptor.CoordAddrMode == ADDR_MODE_SHORT_ADDRESS &&
            m_PANDescriptor.CoordPANId == PAN_ID &&
            m_PANDescriptor.CoordAddress.shortAddress == PAN_COORDINATOR_SHORT_ADDRESS) {
          m_panCoordinatorWasFound = TRUE; // yes!
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
    if (m_panCoordinatorWasFound) {
      // our PAN Coordinator is out there sending beacons, 
      // let's try to associate with it
      call MLME_SET.macCoordShortAddress(m_PANDescriptor.CoordAddress.shortAddress);
      call MLME_SET.macPANId(m_PANDescriptor.CoordPANId);
      call MLME_SYNC.request(m_PANDescriptor.LogicalChannel, m_PANDescriptor.ChannelPage, TRUE);
      call MLME_ASSOCIATE.request(
          m_PANDescriptor.LogicalChannel,  // LogicalChannel 
          m_PANDescriptor.ChannelPage,     // ChannelPage
          ADDR_MODE_SHORT_ADDRESS,         // CoordAddrMode
          PAN_ID,                          // CoordPANID
          m_PANDescriptor.CoordAddress,    // CoordAddress
          m_capabilityInformation,         // CapabilityInformation
          0                                // Security
          );                        
    } else {
      scanForPanCoord();
    }
  }

  event void MLME_ASSOCIATE.confirm(
      uint16_t assocShortAddress,
      uint8_t status,
      ieee154_security_t *security
      )
  {
    if (status == IEEE154_ASSOCIATION_SUCCESSFUL) {
      // we have successfully associated with the PAN Coordinator.
      // now we should start sending our own beacons, so the device
      // can associate with us; but we must make sure that our active
      // period does not overlap with PAN Coordinator's active period
      // (via the "StartTime" parameter to "MLME_START.request")
      call Leds.led1Off();
      m_associatedToPanCoord = TRUE;

      call MLME_SET.macShortAddress(assocShortAddress);
      call MLME_SET.macAssociationPermit(TRUE);

      call MLME_START.request(
          PAN_ID,                        	         // PANId
          RADIO_CHANNEL,                           // LogicalChannel
          0,                                       // ChannelPage,
          (uint32_t) ROUTER_BEACON_START_OFFSET,   // StartTime,
          BEACON_ORDER,                            // BeaconOrder
          SUPERFRAME_ORDER,                        // SuperframeOrder
          FALSE,                                   // PANCoordinator
          FALSE,                                   // BatteryLifeExtension
          FALSE,                                   // CoordRealignment
          0,                                       // CoordRealignSecurity
          0                                        // BeaconSecurity
          );
    } else {
      scanForPanCoord();
    }
  }

  event void MLME_START.confirm(ieee154_status_t status)
  {
    if (status != IEEE154_SUCCESS)
      scanForPanCoord();
  }

  event void MLME_SYNC_LOSS.indication(
      ieee154_status_t lossReason,
      uint16_t panId, 
      uint8_t logicalChannel, 
      uint8_t channelPage, 
      ieee154_security_t *security
      )
  {
    // We have lost track of our PAN Coordinator's beacons :(
    // We stop sending our own beacons, until we have synchronized with
    // the PAN Coordinator again.
    if (lossReason == IEEE154_BEACON_LOSS) {
      call Leds.led2Off(); 
      call MLME_START.request(
          PAN_ID,         // PANId
          RADIO_CHANNEL,  // LogicalChannel
          0,              // ChannelPage,
          0,   			      // StartTime,
          15,             // BeaconOrder
          15,             // SuperframeOrder
          FALSE,          // PANCoordinator
          FALSE,          // BatteryLifeExtension
          FALSE,          // CoordRealignment
          0,              // CoordRealignSecurity
          0               // BeaconSecurity
          );
      scanForPanCoord();
    }
  }

  /* ------------------------------------------------------------------------------ */
  /* Everything above was about finding and associating with the PAN Coordinator and 
   * then starting to send our own beacons. The code below is about allowing the device
   * to associate, receiving data from it and forwarding it to the PAN Coordinator.*/

  event void MLME_ASSOCIATE.indication(
      uint64_t deviceAddress,
      ieee154_CapabilityInformation_t capabilityInformation,
      ieee154_security_t *security
      )
  {
    // The device wants to associate ...
    call MLME_ASSOCIATE.response(
        deviceAddress,
        DEVICE_SHORT_ADDRESS,
        IEEE154_ASSOCIATION_SUCCESSFUL,
        0
        );
  }

  event message_t* MCPS_DATA.indication(message_t* receivedFrame)
  {
    message_t* returnFrame; 
    ieee154_address_t panCoordAddr;
    uint8_t payloadLen = call Frame.getPayloadLength(receivedFrame);
    panCoordAddr.shortAddress = PAN_COORDINATOR_SHORT_ADDRESS;

    call Leds.led1Toggle();  

    // if we are no more associated with the PAN coordinator, we drop the frame
    if (m_associatedToPanCoord == FALSE) {
      return receivedFrame;
    }

    // This event handler has to return a frame buffer to the MAC.
    // We don't want to return "receivedFrame", because we will try
    // to forward that to the PAN Coordinator. Instead we get an "empty"
    // frame through the PoolC component and return that to the MAC.
    returnFrame = call FramePool.get();
    if (returnFrame == NULL)
      return receivedFrame; // no empty frame left!

    // to forward the frame to the PAN Coordinator we update
    // the addressing part (the payload part remains unchanged!)
    call Frame.setAddressingFields(
        receivedFrame,                
        ADDR_MODE_SHORT_ADDRESS, // SrcAddrMode,
        ADDR_MODE_SHORT_ADDRESS, // DstAddrMode,
        PAN_ID,                  // DstPANId,
        &panCoordAddr,           // DstAddr,
        NULL                     // security
        );

    call MCPS_DATA.request(
        receivedFrame,           // msdu,
        payloadLen,              // payloadLength,
        0,                       // msduHandle,
        TX_OPTIONS_ACK           // TxOptions,
        );

    return returnFrame;
  }

  event void MCPS_DATA.confirm(
      message_t *msg,
      uint8_t msduHandle,
      ieee154_status_t status,
      uint32_t Timestamp
      )
  {
    call Leds.led1Toggle();  
    call FramePool.put(msg);
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
