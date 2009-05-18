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
 * $Date: 2009-05-18 16:21:55 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
#include "TKN154.h"
#include "app_profile.h"
module TestDeviceC
{
  uses {
    interface Boot;
    interface MLME_RESET;
    interface MLME_SET;
    interface MLME_GET;
    interface MLME_SCAN;
    interface MLME_SYNC;
    interface MLME_ASSOCIATE;
    interface MLME_DISASSOCIATE;
    interface MLME_COMM_STATUS;
    interface MLME_BEACON_NOTIFY;
    interface MLME_SYNC_LOSS;
    interface Leds;
    interface IEEE154BeaconFrame as BeaconFrame;
    interface Timer<T62500hz> as DisassociateTimer;
  }
} implementation {

  ieee154_CapabilityInformation_t m_capabilityInformation;
  ieee154_PANDescriptor_t m_PANDescriptor;
  bool m_isPANDescriptorValid;
  void startApp();

  event void Boot.booted() {
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
    if (status == IEEE154_SUCCESS)
      startApp();
  }

  void startApp()
  {
    ieee154_phyChannelsSupported_t channel;
    uint8_t scanDuration = BEACON_ORDER; 

    m_isPANDescriptorValid = FALSE;

    // scan only one channel
    channel = ((uint32_t) 1) << RADIO_CHANNEL;

    // we want all received beacons to be signalled 
    // through the MLME_BEACON_NOTIFY interface, i.e.
    // we set the macAutoRequest attribute to FALSE
    call MLME_SET.macAutoRequest(FALSE);
    m_isPANDescriptorValid = FALSE;
    call MLME_SCAN.request  (
                           PASSIVE_SCAN,           // ScanType
                           channel,                // ScanChannels
                           scanDuration,           // ScanDuration
                           0x00,                   // ChannelPage
                           0,                      // EnergyDetectListNumEntries
                           NULL,                   // EnergyDetectList
                           0,                      // PANDescriptorListNumEntries
                           NULL,                   // PANDescriptorList
                           NULL                    // security
                        );
  }

  event message_t* MLME_BEACON_NOTIFY.indication (message_t* frame)
  {
    // received a beacon frame
    ieee154_phyCurrentPage_t page = call MLME_GET.phyCurrentPage();
    ieee154_macBSN_t beaconSequenceNumber = call BeaconFrame.getBSN(frame);

    if (beaconSequenceNumber & 1)
      call Leds.led2On();
    else
      call Leds.led2Off();   
    if (!m_isPANDescriptorValid && call BeaconFrame.parsePANDescriptor(
          frame, RADIO_CHANNEL, page, &m_PANDescriptor) == SUCCESS){
      // let's see if the beacon is from the coordinator we expect...
      if (m_PANDescriptor.CoordAddrMode == ADDR_MODE_SHORT_ADDRESS &&
          m_PANDescriptor.CoordPANId == PAN_ID &&
          m_PANDescriptor.CoordAddress.shortAddress == COORDINATOR_ADDRESS){
        // yes - wait until SCAN is finished, then syncronize to beacons
        m_isPANDescriptorValid = TRUE;
      }
    }
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
    if (m_isPANDescriptorValid){
      call MLME_SET.macPANId(m_PANDescriptor.CoordPANId);
      call MLME_SET.macCoordShortAddress(m_PANDescriptor.CoordAddress.shortAddress);
      call MLME_SYNC.request(m_PANDescriptor.LogicalChannel, m_PANDescriptor.ChannelPage, TRUE);
      call MLME_ASSOCIATE.request(
          m_PANDescriptor.LogicalChannel,
          m_PANDescriptor.ChannelPage,
          m_PANDescriptor.CoordAddrMode,
          m_PANDescriptor.CoordPANId,
          m_PANDescriptor.CoordAddress,
          m_capabilityInformation,
          NULL  // security
          );
    } else
      startApp();
  }

  event void MLME_ASSOCIATE.confirm    (
                          uint16_t AssocShortAddress,
                          uint8_t status,
                          ieee154_security_t *security
                        )
  {
    if ( status == IEEE154_SUCCESS ){
      // we are now associated - set a timer for disassociation 
      call Leds.led1On();
      call DisassociateTimer.startOneShot(312500U);
    } else {
      call MLME_ASSOCIATE.request(
          m_PANDescriptor.LogicalChannel,
          m_PANDescriptor.ChannelPage,
          m_PANDescriptor.CoordAddrMode,
          m_PANDescriptor.CoordPANId,
          m_PANDescriptor.CoordAddress,
          m_capabilityInformation,
          NULL  // security
          );
    }
  }

  event void DisassociateTimer.fired()
  {
    if (call MLME_DISASSOCIATE.request  (
        m_PANDescriptor.CoordAddrMode,
        m_PANDescriptor.CoordPANId,
        m_PANDescriptor.CoordAddress,
        IEEE154_DEVICE_WISHES_TO_LEAVE,
        FALSE,
        NULL
        ) != IEEE154_SUCCESS)
      call DisassociateTimer.startOneShot(312500U);
  }

  event void MLME_DISASSOCIATE.confirm    (
                          ieee154_status_t status,
                          uint8_t DeviceAddrMode,
                          uint16_t DevicePANID,
                          ieee154_address_t DeviceAddress
                        )
  {
    if (status == IEEE154_SUCCESS){
      call Leds.led1Off();
    } else {
      call DisassociateTimer.startOneShot(312500U);
    }
  }

  event void MLME_ASSOCIATE.indication (
                          uint64_t DeviceAddress,
                          ieee154_CapabilityInformation_t CapabilityInformation,
                          ieee154_security_t *security
                        ){}  

  event void MLME_SYNC_LOSS.indication(
                          ieee154_status_t lossReason,
                          uint16_t PANId,
                          uint8_t LogicalChannel,
                          uint8_t ChannelPage,
                          ieee154_security_t *security)
  {
    startApp();
  }

  event void MLME_DISASSOCIATE.indication (
                          uint64_t DeviceAddress,
                          ieee154_disassociation_reason_t DisassociateReason,
                          ieee154_security_t *security
                        ){}


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
  }
}
