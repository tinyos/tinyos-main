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
 * $Date: 2008-06-16 18:00:30 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "TKN154_PHY.h"
#include "TKN154_MAC.h"

generic module NoCapP()
{
  provides
  {
    interface Init as Reset;
    interface FrameTx as CapTx;
    interface FrameRx as FrameRx[uint8_t frameType];
    interface FrameExtracted as FrameExtracted[uint8_t frameType];
    interface FrameTxNow as BroadcastTx;
    interface Notify<bool> as WasRxEnabled;
  }
  uses
  {
    interface Random;
    interface Alarm<TSymbolIEEE802154,uint32_t> as CapEndAlarm;
    interface Alarm<TSymbolIEEE802154,uint32_t> as BLEAlarm;
    interface Alarm<TSymbolIEEE802154,uint32_t> as IndirectTxWaitAlarm;
    interface Alarm<TSymbolIEEE802154,uint32_t> as BroadcastAlarm;
    interface Resource as Token;
    interface ResourceTransfer as TokenToCfp;
    interface ResourceTransferred as TokenTransferred;
    interface ResourceRequested as TokenRequested;
    interface GetNow<bool> as IsTokenRequested;
    interface GetNow<uint32_t> as CapStart; 
    interface GetNow<ieee154_reftime_t*> as CapStartRefTime; 
    interface GetNow<uint32_t> as CapLen; 
    interface GetNow<bool> as IsBLEActive; 
    interface GetNow<uint16_t> as BLELen; 
    interface GetNow<bool> as IsRxEnableActive; 
    interface GetNow<bool> as IsRxBroadcastPending; 
    interface Notify<bool> as RxEnableStateChange;
    interface FrameUtility;
    interface RadioTx;
    interface RadioRx;
    interface RadioOff;
    interface Get<bool> as IsBeaconEnabledPAN;
    interface MLME_GET;
    interface MLME_SET;
    interface Ieee802154Debug as Debug;
    interface TimeCalc;
    interface Leds;
    interface SetNow<ieee154_cap_frame_backup_t*> as FrameBackup;
    interface GetNow<ieee154_cap_frame_backup_t*> as FrameRestore;
  }
}
implementation
{
  command error_t Reset.init()
  {
    return SUCCESS;
  }

  async event void TokenTransferred.transferred()
  {
    call TokenToCfp.transfer();
  }

  command ieee154_status_t CapTx.transmit(ieee154_txframe_t *frame)
  {
    return IEEE154_TRANSACTION_OVERFLOW;
  }

  async event void RadioTx.loadDone(){ }
  async event void RadioOff.offDone(){ }
  async event void RadioRx.prepareDone(){ }

  async event void CapEndAlarm.fired(){ }
  async event void BLEAlarm.fired(){ }
  event void RxEnableStateChange.notify(bool x){ }
  async event void BroadcastAlarm.fired(){ }

  async event void IndirectTxWaitAlarm.fired() { }

  async event void RadioTx.transmitDone(ieee154_txframe_t *frame, ieee154_reftime_t
       *referenceTime, bool ackPendingFlag, error_t error) { }

  event message_t* RadioRx.received(message_t* frame, ieee154_reftime_t* referenceTime) { return frame; }
  async command ieee154_status_t  BroadcastTx.transmitNow(ieee154_txframe_t *frame){ return IEEE154_TRANSACTION_OVERFLOW; }

  async event void TokenRequested.requested() {}
  async event void TokenRequested.immediateRequested() {}
  event void Token.granted(){}
  command error_t WasRxEnabled.enable(){return FAIL;}
  command error_t WasRxEnabled.disable(){return FAIL;}
}
