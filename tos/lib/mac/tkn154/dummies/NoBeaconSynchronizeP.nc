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
 * $Revision: 1.3 $
 * $Date: 2008-10-21 17:29:00 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */


#include "TKN154_MAC.h"

module NoBeaconSynchronizeP
{
  provides
  {
    interface Init;
    interface MLME_SYNC;
    interface MLME_BEACON_NOTIFY;
    interface MLME_SYNC_LOSS;
    interface GetNow<bool> as IsTrackingBeacons;
    interface Get<uint32_t> as GetLastBeaconRxTime;
    interface GetNow<uint32_t> as CapStart;
    interface GetNow<ieee154_reftime_t*> as CapStartRefTime; 
    interface GetNow<uint32_t> as CapLen;
    interface GetNow<uint32_t> as CapEnd; 
    interface GetNow<uint32_t> as CfpEnd; 
    interface GetNow<uint32_t> as CfpLen;
    interface GetNow<uint32_t> as BeaconInterval; 
    interface GetNow<bool> as IsBLEActive; 
    interface GetNow<uint16_t> as BLELen; 
    interface GetNow<uint8_t*> as GtsField; 
    interface GetNow<uint32_t> as SfSlotDuration; 
    interface GetNow<uint8_t> as FinalCapSlot; 
    interface GetNow<uint8_t> as NumGtsSlots;
    interface GetNow<bool> as IsRxBroadcastPending; 
  }
  uses
  {
    interface MLME_GET;
    interface MLME_SET;
    interface FrameUtility;
    interface Notify<bool> as FindBeacon;
    interface IEEE154BeaconFrame as BeaconFrame;
    interface Alarm<TSymbolIEEE802154,uint32_t> as TrackAlarm;
    interface RadioRx as BeaconRx;
    interface RadioOff;
    interface Get<bool> as IsBeaconEnabledPAN;
    interface DataRequest;
    interface FrameRx as CoordRealignmentRx;
    interface Resource as Token;
    interface ResourceTransfer as TokenToCap;
    interface ResourceTransferred as TokenTransferred;
    interface GetNow<bool> as IsSendingBeacons;
    interface TimeCalc;
    interface IEEE154Frame as Frame;
    interface Leds;
    interface Ieee802154Debug as Debug;
  }
}
implementation
{

  command error_t Init.init() { return SUCCESS; }

  command ieee154_status_t MLME_SYNC.request  (
      uint8_t logicalChannel,
      uint8_t channelPage,
      bool trackBeacon
      )
  {
    return IEEE154_TRANSACTION_OVERFLOW;
  }

  event void Token.granted() { }

  async event void TokenTransferred.transferred() { call Token.release(); }

  async event void TrackAlarm.fired() {}

  async event void BeaconRx.prepareDone() {}

  event message_t* BeaconRx.received(message_t* frame, ieee154_reftime_t *timestamp) { return frame;}

  async event void RadioOff.offDone() {}

  async command bool IsTrackingBeacons.getNow(){ return FALSE;}
  command uint32_t GetLastBeaconRxTime.get(){ return 0;}
  async command uint8_t* GtsField.getNow() { return 0; }
  async command uint32_t SfSlotDuration.getNow() { return 0; }
  async command uint8_t FinalCapSlot.getNow() { return 0; }

  event void DataRequest.pollDone(){}
  async command uint32_t CapEnd.getNow() { return 0; }
  async command uint32_t CapStart.getNow() { return 0; }
  async command uint32_t CapLen.getNow() { return 0; }
  async command uint32_t CfpEnd.getNow() { return 0; }
  async command ieee154_reftime_t* CapStartRefTime.getNow() { return NULL; }
  async command uint32_t CfpLen.getNow(){ return 0;}
  async command uint32_t BeaconInterval.getNow(){ return 0;}
  async command bool IsBLEActive.getNow(){ return 0;}
  async command uint16_t BLELen.getNow(){ return 0;}
  async command uint8_t NumGtsSlots.getNow() { return 0; }
  async command bool IsRxBroadcastPending.getNow() { return FALSE; }
  event message_t* CoordRealignmentRx.received(message_t* frame) {return frame;}
  event void FindBeacon.notify( bool val ){}
}
