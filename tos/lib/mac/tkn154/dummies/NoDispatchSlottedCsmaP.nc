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
 * $Date: 2009-03-24 12:56:47 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

 /** Empty placeholder component for DispatchSlottedCsmaP. */

#include "TKN154_PHY.h"
#include "TKN154_MAC.h"

generic module NoDispatchSlottedCsmaP(uint8_t sfDirection)
{
  provides
  {
    interface Init as Reset;
    interface FrameTx as FrameTx;
    interface FrameRx as FrameRx[uint8_t frameType];
    interface FrameExtracted as FrameExtracted[uint8_t frameType];
    interface FrameTxNow as BroadcastTx;
    interface Notify<bool> as WasRxEnabled;
  }
  uses
  {
    interface Alarm<TSymbolIEEE802154,uint32_t> as CapEndAlarm;
    interface Alarm<TSymbolIEEE802154,uint32_t> as BLEAlarm;
    interface Alarm<TSymbolIEEE802154,uint32_t> as IndirectTxWaitAlarm;
    interface Alarm<TSymbolIEEE802154,uint32_t> as BroadcastAlarm;
    interface GetNow<token_requested_t> as IsRadioTokenRequested;
    interface TransferableResource as RadioToken;
    interface SuperframeStructure; 
    interface GetNow<bool> as IsRxEnableActive; 
    interface Get<ieee154_txframe_t*> as GetIndirectTxFrame; 
    interface Notify<bool> as RxEnableStateChange;
    interface GetNow<bool> as IsTrackingBeacons;
    interface FrameUtility;
    interface SlottedCsmaCa;
    interface RadioRx;
    interface RadioOff;
    interface MLME_GET;
    interface MLME_SET;
    interface TimeCalc;
    interface Leds;
    interface SetNow<ieee154_cap_frame_backup_t*> as FrameBackup;
    interface GetNow<ieee154_cap_frame_backup_t*> as FrameRestore;
    interface StdControl as TrackSingleBeacon;
  }
}
implementation
{
  enum {
    COORD_ROLE = (sfDirection == OUTGOING_SUPERFRAME),
    DEVICE_ROLE = !COORD_ROLE,
    RADIO_CLIENT_CFP = COORD_ROLE ? RADIO_CLIENT_COORDCFP : RADIO_CLIENT_DEVICECFP,
  };  

  command error_t Reset.init() { return SUCCESS; }

  async event void RadioToken.transferredFrom(uint8_t c) { call RadioToken.transferTo(RADIO_CLIENT_CFP); }

  command ieee154_status_t FrameTx.transmit(ieee154_txframe_t *frame) { return IEEE154_TRANSACTION_OVERFLOW; }

  async event void RadioOff.offDone(){ }

  async event void RadioRx.enableRxDone(){}

  async event void CapEndAlarm.fired(){ }

  async event void BLEAlarm.fired(){ }

  event void RxEnableStateChange.notify(bool whatever){ }

  async event void BroadcastAlarm.fired(){ }

  async event void IndirectTxWaitAlarm.fired() { }

  async event void SlottedCsmaCa.transmitDone(ieee154_txframe_t *frame, ieee154_csma_t *csma, 
      bool ackPendingFlag,  uint16_t remainingBackoff, error_t result) { }

  event message_t* RadioRx.received(message_t* frame, const ieee154_timestamp_t *timestamp) { return frame; }

  async command ieee154_status_t BroadcastTx.transmitNow(ieee154_txframe_t *frame) { return IEEE154_TRANSACTION_OVERFLOW;}

  event void RadioToken.granted() { }

  command error_t WasRxEnabled.enable(){return FAIL;}
  command error_t WasRxEnabled.disable(){return FAIL;}
}
