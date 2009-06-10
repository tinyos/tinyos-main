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
module TestActiveScanCoordC
{
  uses {
    interface Boot;
    interface MLME_RESET;
    interface MLME_START;
    interface MLME_SET;
    interface MLME_GET;
    interface IEEE154TxBeaconPayload;
    interface Leds;
    interface Timer<T62500hz> as Led1Timer;

  }
} implementation {

  event void Boot.booted() {
    call MLME_RESET.request(TRUE);
  }

  event void MLME_RESET.confirm(ieee154_status_t status) {
    if (status != IEEE154_SUCCESS) 
      return;
    call MLME_SET.macShortAddress(COORDINATOR_ADDRESS);
    call MLME_SET.macAssociationPermit(FALSE);
    call MLME_SET.macRxOnWhenIdle(TRUE);
    call MLME_START.request(
                          PAN_ID,           // PANId
                          RADIO_CHANNEL,    // LogicalChannel
                          0,                // ChannelPage,
                          0,                // StartTime,
                          15,               // BeaconOrder
                          15,               // SuperframeOrder
                          TRUE,             // PANCoordinator
                          FALSE,            // BatteryLifeExtension
                          FALSE,            // CoordRealignment
                          NULL,             // no realignment security
                          NULL              // no beacon security
                        );    
  }

  event void MLME_START.confirm(ieee154_status_t status) {}

  event void IEEE154TxBeaconPayload.aboutToTransmit() {
    call Leds.led1On();
    call Led1Timer.startOneShot(62500U);
  }

  event void Led1Timer.fired(){
    call Leds.led1Off();
  }

  event void IEEE154TxBeaconPayload.setBeaconPayloadDone(void *beaconPayload, uint8_t length){}
  event void IEEE154TxBeaconPayload.modifyBeaconPayloadDone(uint8_t offset, void *buffer, uint8_t bufferLength){}
  event void IEEE154TxBeaconPayload.beaconTransmitted(){}
}
