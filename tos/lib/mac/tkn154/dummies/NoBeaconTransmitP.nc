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
 * $Date: 2008-06-18 15:52:53 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "TKN154_MAC.h"
#include "TKN154_PHY.h"
module NoBeaconTransmitP
{
  provides
  {
    interface Init;
    interface MLME_START;
    interface WriteBeaconField as SuperframeSpecWrite;
    interface Get<bool> as IsSendingBeacons;
    interface GetNow<uint32_t> as CapStart; 
    interface GetNow<ieee154_reftime_t*> as CapStartRefTime; 
    interface GetNow<uint32_t> as CapLen; 
    interface GetNow<uint32_t> as CapEnd; 
    interface GetNow<uint32_t> as CfpEnd; 
    interface GetNow<uint32_t> as CfpLen; 
    interface GetNow<bool> as IsBLEActive; 
    interface GetNow<uint16_t> as BLELen; 
    interface GetNow<uint8_t*> as GtsField; 
    interface GetNow<uint32_t> as SfSlotDuration; 
    interface GetNow<uint32_t> as BeaconInterval; 
    interface GetNow<uint8_t> as FinalCapSlot;
    interface GetNow<uint8_t> as NumGtsSlots;
    interface GetNow<bool> as BeaconFramePendingBit;
    interface IEEE154TxBeaconPayload;
  } uses {
    interface Notify<bool> as GtsSpecUpdated;
    interface Notify<bool> as PendingAddrSpecUpdated;
    interface Notify<const void*> as PIBUpdate[uint8_t attributeID];
    interface Alarm<TSymbolIEEE802154,uint32_t> as BeaconTxAlarm;
    interface Timer<TSymbolIEEE802154> as BeaconPayloadUpdateTimer;
    interface RadioOff;
    interface Get<bool> as IsBeaconEnabledPAN;
    interface RadioTx as BeaconTx;
    interface MLME_GET;
    interface MLME_SET;
    interface Resource as Token;
    interface ResourceTransfer as TokenToBroadcast;
    interface FrameTx as RealignmentBeaconEnabledTx;
    interface FrameTx as RealignmentNonBeaconEnabledTx;
    interface FrameRx as BeaconRequestRx;
    interface WriteBeaconField as GtsInfoWrite;
    interface WriteBeaconField as PendingAddrWrite;
    interface FrameUtility;
    interface GetNow<bool> as IsTrackingBeacons;
    interface GetNow<uint32_t> as LastBeaconRxTime;
    interface GetNow<ieee154_reftime_t*> as LastBeaconRxRefTime; 
    interface Ieee802154Debug as Debug;
    interface Set<ieee154_macSuperframeOrder_t> as SetMacSuperframeOrder;
    interface Set<ieee154_macBeaconTxTime_t> as SetMacBeaconTxTime;
    interface Set<ieee154_macPanCoordinator_t> as SetMacPanCoordinator;
    interface GetSet<ieee154_txframe_t*> as GetSetRealignmentFrame;
    interface GetNow<bool> as IsBroadcastReady; 
    interface TimeCalc;
    interface Leds;
  }
}
implementation
{
  command error_t Init.init()
  {
    return SUCCESS;
  }
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

  event void Token.granted() { }

  async event void RadioOff.offDone() { }

  async event void BeaconTxAlarm.fired() {}

  async event void BeaconTx.loadDone() {}

  async event void BeaconTx.transmitDone(ieee154_txframe_t *frame, 
      ieee154_reftime_t *referenceTime, bool pendingFlag, error_t error) { }

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

  command uint8_t SuperframeSpecWrite.write(uint8_t *superframeSpecField, uint8_t maxlen)
  {
    return 0;
  }

  command uint8_t SuperframeSpecWrite.getLength()
  {
    return 0;
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

  command bool IsSendingBeacons.get(){ return FALSE;}

  async command uint32_t CapStart.getNow() { return 0; }
  async command ieee154_reftime_t* CapStartRefTime.getNow() { return NULL; }
  async command uint32_t CapLen.getNow() { return 0;}
  async command uint32_t CapEnd.getNow() 
  {
    return 0;
  }
  async command uint32_t CfpEnd.getNow() 
  {
    return 0;
  }
  async command uint32_t CfpLen.getNow()
  {
    return 0;
  }
  async command bool IsBLEActive.getNow(){ return FALSE;}
  async command uint16_t BLELen.getNow(){ return 0;}
  async command bool BeaconFramePendingBit.getNow(){ return FALSE;}

  async command uint8_t* GtsField.getNow() { return NULL; }
  async command uint32_t SfSlotDuration.getNow() { return 0; }
  async command uint32_t BeaconInterval.getNow() { return 0; }
  async command uint8_t FinalCapSlot.getNow() { return 0; }
  async command uint8_t NumGtsSlots.getNow() { return 0; }

  default event void MLME_START.confirm    (
                          ieee154_status_t status
                        ){}

  default event void IEEE154TxBeaconPayload.setBeaconPayloadDone(void *beaconPayload, uint8_t length){}

  default event void IEEE154TxBeaconPayload.modifyBeaconPayloadDone(uint8_t offset, void *buffer, uint8_t bufferLength){}

  default event void IEEE154TxBeaconPayload.aboutToTransmit(){}

  default event void IEEE154TxBeaconPayload.beaconTransmitted(){}

}
