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
 * $Revision: 1.2 $
 * $Date: 2009-09-10 12:00:49 $
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
    interface MLME_ASSOCIATE;
    interface MLME_DISASSOCIATE;
    interface MLME_COMM_STATUS;
    interface Leds;
    interface Timer<T62500hz> as DisassociateTimer;
  }
} implementation {

  ieee154_CapabilityInformation_t m_capabilityInformation;
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
    ieee154_address_t coordAdr;

    coordAdr.shortAddress = COORDINATOR_ADDRESS;
    call MLME_SET.phyCurrentChannel(RADIO_CHANNEL);
    call MLME_SET.macAutoRequest(FALSE);
    call MLME_SET.macPANId(PAN_ID);
    call MLME_SET.macCoordShortAddress(COORDINATOR_ADDRESS);
    call MLME_ASSOCIATE.request(
          RADIO_CHANNEL,
          call MLME_GET.phyCurrentPage(),
          ADDR_MODE_SHORT_ADDRESS,
          PAN_ID,
          coordAdr,
          m_capabilityInformation,
          NULL  // security
          );    
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
      startApp(); // retry
    }
  }

  event void DisassociateTimer.fired()
  {
    ieee154_address_t coordAdr;
    coordAdr.shortAddress = COORDINATOR_ADDRESS;
    if (call MLME_DISASSOCIATE.request  (
          ADDR_MODE_SHORT_ADDRESS,
          PAN_ID,
          coordAdr,
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
                        ) {}
}
