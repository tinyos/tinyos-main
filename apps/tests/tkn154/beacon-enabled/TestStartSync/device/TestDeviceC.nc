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
    interface MLME_BEACON_NOTIFY;
    interface MLME_SYNC_LOSS;
    interface Leds;
    interface IEEE154BeaconFrame as BeaconFrame;
  }
} implementation {

  enum {
    NUM_PAN_DESCRIPTORS = 10,
  };
  ieee154_PANDescriptor_t m_PANDescriptor[NUM_PAN_DESCRIPTORS];
  void startApp();

  event void Boot.booted() {
    call MLME_RESET.request(TRUE);
  }
  
  event void MLME_RESET.confirm(ieee154_status_t status)
  {
    if (status == IEEE154_SUCCESS)
      startApp();
  }

  void startApp()
  {
    ieee154_phyChannelsSupported_t scanChannels;
    uint8_t scanDuration = BEACON_ORDER;

    // set the short address to whatever was passed 
    // as a parameter to make system ("make install,X")
    call MLME_SET.macShortAddress(TOS_NODE_ID); 
    scanChannels = call MLME_GET.phyChannelsSupported();
    //scanChannels = (uint32_t) 1 << RADIO_CHANNEL;

    // setting the macAutoRequest attribute to TRUE means
    // that during the scan beacons will not be signalled
    // through MLME_BEACON_NOTIFY
    call MLME_SET.macAutoRequest(TRUE);
    call MLME_SCAN.request  (
        PASSIVE_SCAN,           // ScanType
        scanChannels,           // ScanChannels
        scanDuration,           // ScanDuration
        0x00,                   // ChannelPage
        0,                      // EnergyDetectListNumEntries
        NULL,                   // EnergyDetectList
        NUM_PAN_DESCRIPTORS,    // PANDescriptorListNumEntries
        m_PANDescriptor,        // PANDescriptorList
        0                       // security
        );
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
    uint8_t i;
    switch (status){
      case IEEE154_NO_BEACON:
        startApp();
        break;
      case IEEE154_SUCCESS:
        if (PANDescriptorListNumEntries > 0){
          for (i=0; i<PANDescriptorListNumEntries; i++)
            if (PANDescriptorList[i].CoordAddrMode == ADDR_MODE_SHORT_ADDRESS &&
                PANDescriptorList[i].CoordPANId == PAN_ID &&
                PANDescriptorList[i].CoordAddress.shortAddress == COORDINATOR_ADDRESS)
              break;
          if (i == PANDescriptorListNumEntries){
            // found no matching entry
            startApp();
          } else {
            call MLME_SET.macAutoRequest(FALSE); // from now on: give me the beacons
            call MLME_SET.macPANId(PANDescriptorList[i].CoordPANId);
            call MLME_SET.macCoordShortAddress(PANDescriptorList[i].CoordAddress.shortAddress);
            call MLME_SYNC.request(PANDescriptorList[i].LogicalChannel, ChannelPage, TRUE);
          }
        }
        break;
      default:
        break;
    }
  }

  event message_t* MLME_BEACON_NOTIFY.indication (
                          message_t* frame
                        )
  {
    ieee154_macBSN_t beaconSequenceNumber = call BeaconFrame.getBSN(frame);
    if (beaconSequenceNumber & 1)
      call Leds.led2On();
    else
      call Leds.led2Off();    
    call Leds.led1On();
    return frame;
  }

  event void MLME_SYNC_LOSS.indication(
                          ieee154_status_t lossReason,
                          uint16_t PANId,
                          uint8_t LogicalChannel,
                          uint8_t ChannelPage,
                          ieee154_security_t *security)
  {
    call Leds.led1Off();
    startApp();
  }
}
