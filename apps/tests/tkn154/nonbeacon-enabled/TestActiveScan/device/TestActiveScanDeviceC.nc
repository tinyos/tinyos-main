/*
 * Copyright (c) 2009, Technische Universitaet Berlin
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
 * $Date: 2009-06-10 09:38:41 $
 * @author: Jasper Buesch <buesch@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "TKN154.h"
#include "app_profile.h"
module TestActiveScanDeviceC
{
  uses {
    interface Boot;
    interface MLME_RESET;
    interface MLME_SET;
    interface MLME_GET;
    interface MLME_SCAN;
    interface Leds;
    interface Timer<T62500hz> as ScanTimer;
    interface Timer<T62500hz> as Led1Timer;
    interface Timer<T62500hz> as Led0Timer;
    interface Timer<T62500hz> as Led2Timer;
  }
} implementation {

  ieee154_PANDescriptor_t m_PANDescriptor[5];

  event void Boot.booted() {
    call MLME_RESET.request(TRUE);
  }

  event void MLME_RESET.confirm(ieee154_status_t status) {
    if (status == IEEE154_SUCCESS){
    call ScanTimer.startPeriodic(125000U); 
    }
  }

  event void ScanTimer.fired() {
    ieee154_phyChannelsSupported_t channelMask;
    channelMask = ((uint32_t) 1) << RADIO_CHANNEL;
    call Leds.led2On();
    call Led2Timer.startOneShot(62500U);
    call MLME_SCAN.request  (
                           ACTIVE_SCAN,            // ScanType
                           channelMask,            // ScanChannels
                           5,                      // ScanDuration
                           0x00,                   // ChannelPage
                           0,                      // EnergyDetectListNumEntries
                           NULL,                   // EnergyDetectList
                           5,                      // PANDescriptorListNumEntries
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
                        ){
    uint8_t scanIndex;
    uint8_t rightCoordFound = FALSE;

    for(scanIndex = 0; scanIndex < PANDescriptorListNumEntries; scanIndex++){
      if( (PANDescriptorList[scanIndex].CoordAddrMode == ADDR_MODE_SHORT_ADDRESS) && 
          (PANDescriptorList[scanIndex].CoordAddress.shortAddress == COORDINATOR_ADDRESS) &&
          (PANDescriptorList[scanIndex].CoordPANId == PAN_ID) ) {
        call Leds.led1On();
        call Led1Timer.startOneShot(62500U);
        rightCoordFound = TRUE;
        break;
      }
    }
    if(rightCoordFound == FALSE) {
      call Leds.led0On();
      call Led0Timer.startOneShot(62500U); 
    }
  }

  event void Led0Timer.fired(){
    call Leds.led0Off();
  }

  event void Led1Timer.fired(){
    call Leds.led1Off();
  }

  event void Led2Timer.fired(){
    call Leds.led2Off();
  }

}
