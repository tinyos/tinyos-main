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
 * $Date: 2009-06-10 09:23:45 $
 * @author: Jasper Buesch <buesch@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "TKN154.h"
#include "app_profile.h"
module TestIndirectDataCoordC
{
  uses {
    interface Boot;
    interface MLME_RESET;
    interface MLME_START;
    interface MLME_SET;
    interface MLME_GET;
    interface MCPS_DATA;
    interface IEEE154Frame as Frame;
    interface Leds;
    interface Packet;
    interface Timer<T62500hz> as DataTimer;
    interface Timer<T62500hz> as Led1Timer;
    interface Timer<T62500hz> as Led0Timer;
  }
} implementation {

  message_t frame;
  uint8_t *payloadRegion;
  uint8_t m_payloadLen;

  char payload[] = "TestIndirect, Coordinator talking now!";

  void sendIndirectData();

  event void Boot.booted() {
    m_payloadLen = strlen(payload);
    payloadRegion = call Packet.getPayload(&frame, m_payloadLen);
    if (m_payloadLen <= call Packet.maxPayloadLength()){
      memcpy(payloadRegion, payload, m_payloadLen);
      call MLME_RESET.request(TRUE);
    }
  }

  event void MLME_RESET.confirm(ieee154_status_t status)
  {
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

  void sendIndirectData(){
    ieee154_address_t deviceAddress;
    deviceAddress.shortAddress = DEVICE_ADDRESS;
    call Frame.setAddressingFields(
                          &frame,                
                          ADDR_MODE_SHORT_ADDRESS,     // SrcAddrMode,
                          ADDR_MODE_SHORT_ADDRESS,     // DstAddrMode,
                          PAN_ID,                      // DstPANId,
                          &deviceAddress,              // DstAddr,
                          NULL                         // security
                        );
    call MCPS_DATA.request(
                          &frame,                               // frame,
                          strlen(payload),                      // payloadLength,
                          0,                                    // msduHandle,
                          TX_OPTIONS_INDIRECT | TX_OPTIONS_ACK  // TxOptions,
                        ); 
    call Leds.led1On();
    call Led1Timer.startOneShot(12500U);
  }

  event void MLME_START.confirm(ieee154_status_t status) {
    sendIndirectData();
  }

  event void DataTimer.fired(){
    sendIndirectData();
  }

  event void Led1Timer.fired(){
    call Leds.led1Off();
  }

  event void MCPS_DATA.confirm(
                          message_t *msg,
                          uint8_t msduHandle,
                          ieee154_status_t status,
                          uint32_t Timestamp
                        )
  {
    if(status == IEEE154_TRANSACTION_EXPIRED){
      call Leds.led0On();
      call Led0Timer.startOneShot(125000U);
      sendIndirectData();
    }else if(status == SUCCESS){
      call DataTimer.startOneShot(125000U);
    }
  }

  event void Led0Timer.fired(){
    call Leds.led0Off();
  }

  event message_t* MCPS_DATA.indication ( message_t* frame__ ){
    return frame__;
  }
}
