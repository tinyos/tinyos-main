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
 * $Revision: 1.6 $
 * $Date: 2009-03-24 12:56:47 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

 /** Empty placeholder component for BeaconSynchronizeP. */

#include "TKN154_MAC.h"

module NoBeaconSynchronizeP
{
  provides
  {
    interface Init as Reset;
    interface MLME_SYNC;
    interface MLME_BEACON_NOTIFY;
    interface MLME_SYNC_LOSS;
    interface SuperframeStructure as IncomingSF;
    interface GetNow<bool> as IsTrackingBeacons;
    interface StdControl as TrackSingleBeacon;
  }
  uses
  {
    interface MLME_GET;
    interface MLME_SET;
    interface FrameUtility;
    interface IEEE154BeaconFrame as BeaconFrame;
    interface Alarm<TSymbolIEEE802154,uint32_t> as TrackAlarm;
    interface RadioRx as BeaconRx;
    interface RadioOff;
    interface DataRequest;
    interface FrameRx as CoordRealignmentRx;
    interface TransferableResource as RadioToken;
    interface TimeCalc;
    interface IEEE154Frame as Frame;
    interface Leds;
  }
}
implementation
{
  command error_t Reset.init() { return SUCCESS; }  

  command ieee154_status_t MLME_SYNC.request  ( uint8_t logicalChannel, uint8_t channelPage, bool trackBeacon)
  {
    return IEEE154_TRANSACTION_OVERFLOW;
  }

  event void RadioToken.granted() { }

  async event void RadioToken.transferredFrom(uint8_t fromClient) { call RadioToken.transferTo(RADIO_CLIENT_BEACONTRANSMIT); }

  async event void RadioOff.offDone() { }

  async event void BeaconRx.enableRxDone() { }

  async event void TrackAlarm.fired() { }

  event message_t* BeaconRx.received(message_t *frame, const ieee154_timestamp_t *timestamp) { return frame; }

  command error_t TrackSingleBeacon.start()
  {
    return FAIL;
  }

  command error_t TrackSingleBeacon.stop()
  {
    return FAIL;
  }
  
  /* -----------------------  SF Structure, etc. ----------------------- */

  async command uint32_t IncomingSF.sfStartTime() { return 0; }
  async command uint16_t IncomingSF.sfSlotDuration() { return 0; }
  async command uint8_t IncomingSF.numCapSlots() { return 0; }
  async command uint8_t IncomingSF.numGtsSlots() { return 0; }
  async command uint16_t IncomingSF.battLifeExtDuration() { return 0; }
  async command const uint8_t* IncomingSF.gtsFields() { return NULL; }
  async command uint16_t IncomingSF.guardTime() { return 0; }
  async command const ieee154_timestamp_t* IncomingSF.sfStartTimeRef() { return NULL; }
  async command bool IncomingSF.isBroadcastPending() { return 0; }
  async command bool IsTrackingBeacons.getNow() { return 0; }

  event void DataRequest.pollDone(){}

  default event message_t* MLME_BEACON_NOTIFY.indication (message_t* frame){return frame;}
  default event void MLME_SYNC_LOSS.indication (
                          ieee154_status_t lossReason,
                          uint16_t panID,
                          uint8_t logicalChannel,
                          uint8_t channelPage,
                          ieee154_security_t *security){}

  event message_t* CoordRealignmentRx.received(message_t* frame) { return frame; }
}
