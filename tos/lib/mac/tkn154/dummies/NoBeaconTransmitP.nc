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
 * $Revision: 1.8 $
 * $Date: 2009-12-14 16:46:49 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

 /** Empty placeholder component for BeaconTransmitP. */

#include "TKN154_MAC.h"
#include "TKN154_PHY.h"
module NoBeaconTransmitP
{
  provides
  {
    interface Init as Reset;
    interface MLME_START;
    interface IEEE154TxBeaconPayload;
    interface SuperframeStructure as OutgoingSF;
    interface GetNow<bool> as IsSendingBeacons;
  } uses {
    interface Notify<bool> as GtsSpecUpdated;
    interface Notify<bool> as PendingAddrSpecUpdated;
    interface Notify<const void*> as PIBUpdate[uint8_t attributeID];
    interface Alarm<TSymbolIEEE802154,uint32_t> as BeaconSendAlarm;
    interface Timer<TSymbolIEEE802154> as BeaconPayloadUpdateTimer;
    interface RadioOff;
    interface RadioTx as BeaconTx;
    interface MLME_GET;
    interface MLME_SET;
    interface TransferableResource as RadioToken;
    interface FrameTx as RealignmentBeaconEnabledTx;
    interface FrameTx as RealignmentNonBeaconEnabledTx;
    interface FrameRx as BeaconRequestRx;
    interface WriteBeaconField as GtsInfoWrite;
    interface WriteBeaconField as PendingAddrWrite;
    interface FrameUtility;
    interface GetNow<bool> as IsTrackingBeacons;
    interface SuperframeStructure as IncomingSF;
    interface Set<ieee154_macSuperframeOrder_t> as SetMacSuperframeOrder;
    interface Set<ieee154_macBeaconTxTime_t> as SetMacBeaconTxTime;
    interface Set<ieee154_macPanCoordinator_t> as SetMacPanCoordinator;
    interface GetSet<ieee154_txframe_t*> as GetSetRealignmentFrame;
    interface GetNow<bool> as IsBroadcastReady; 
    interface TimeCalc;
    interface Random;
    interface Leds;
  }
}
implementation
{
  command error_t Reset.init() { return SUCCESS; }

  command ieee154_status_t MLME_START.request  (
                          uint16_t panID,
                          uint8_t logicalChannel,
                          uint8_t channelPage,
                          uint32_t startTime,
                          uint8_t beaconOrder,
                          uint8_t superframeOrder,
                          bool panCoordinator,
                          bool batteryLifeExtension,
                          bool coordRealignment,
                          ieee154_security_t *coordRealignSecurity,
                          ieee154_security_t *beaconSecurity)
  {
    return IEEE154_TRANSACTION_OVERFLOW;
  }

  event void RadioToken.granted() { }

  async event void RadioToken.transferredFrom(uint8_t from) { call RadioToken.transferTo(RADIO_CLIENT_BEACONSYNCHRONIZE); }

  async event void RadioOff.offDone() { }

  async event void BeaconSendAlarm.fired() {}

  async event void BeaconTx.transmitDone(ieee154_txframe_t *frame, error_t result){}

  command error_t IEEE154TxBeaconPayload.setBeaconPayload(void *beaconPayload, uint8_t length) { return ESIZE; }

  command const void* IEEE154TxBeaconPayload.getBeaconPayload() { return NULL; }

  command uint8_t IEEE154TxBeaconPayload.getBeaconPayloadLength() {return 0; }

  command error_t IEEE154TxBeaconPayload.modifyBeaconPayload(uint8_t offset, void *buffer, uint8_t bufferLength)
  {
    return ESIZE;
  }

  event void PIBUpdate.notify[uint8_t attributeID](const void* attributeValue)
  {
  }

  event void PendingAddrSpecUpdated.notify(bool val)
  {
  }

  event void GtsSpecUpdated.notify(bool val)
  {
  }

  event void BeaconPayloadUpdateTimer.fired()
  {
  }

  event void RealignmentBeaconEnabledTx.transmitDone(ieee154_txframe_t *frame, ieee154_status_t status)
  {
  }
 
  event void RealignmentNonBeaconEnabledTx.transmitDone(ieee154_txframe_t *frame, ieee154_status_t status)
  {
  }

  event message_t* BeaconRequestRx.received(message_t* frame)
  {
    return frame;
  }

  async command uint32_t OutgoingSF.sfStartTime() {return 0;}

  async command uint32_t OutgoingSF.sfSlotDuration() {return 0;}

  async command uint8_t OutgoingSF.numCapSlots() {return 0;}

  async command uint8_t OutgoingSF.numGtsSlots() {return 0;}

  async command uint16_t OutgoingSF.battLifeExtDuration() {return 0;}

  async command const uint8_t* OutgoingSF.gtsFields() {return NULL;}

  async command uint16_t OutgoingSF.guardTime() {return 0;}

  async command bool OutgoingSF.isBroadcastPending() {return FALSE;}

  async command uint32_t OutgoingSF.beaconInterval() { return 0;}

  async command bool IsSendingBeacons.getNow() {return FALSE;}
}
