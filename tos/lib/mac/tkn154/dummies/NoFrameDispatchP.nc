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
 * $Date: 2008-11-25 09:35:09 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "TKN154_PHY.h"
#include "TKN154_MAC.h"

generic module NoFrameDispatchP(uint8_t superframeDirection)
{
  provides
  {
    interface Init as Reset;
    interface FrameTx as FrameTx;
    interface FrameRx as FrameRx[uint8_t frameType];
    interface FrameExtracted as FrameExtracted[uint8_t frameType];
    interface FrameTxNow as BroadcastTx;
    interface Notify<bool> as WasRxEnabled;
    interface Notify<bool> as FindBeacon;
  }
  uses
  {
    interface Alarm<TSymbolIEEE802154,uint32_t> as CapEndAlarm;
    interface Alarm<TSymbolIEEE802154,uint32_t> as BLEAlarm;
    interface Alarm<TSymbolIEEE802154,uint32_t> as IndirectTxWaitAlarm;
    interface Alarm<TSymbolIEEE802154,uint32_t> as BroadcastAlarm;
    interface Resource as Token;
    interface GetNow<bool> as IsTokenRequested;
    interface ResourceTransfer as TokenToCfp;
    interface ResourceTransferred as TokenTransferred;
    interface GetNow<uint32_t> as CapStart; 
    interface GetNow<ieee154_reftime_t*> as CapStartRefTime; 
    interface GetNow<uint32_t> as CapLen; 
    interface GetNow<bool> as IsBLEActive; 
    interface GetNow<uint16_t> as BLELen; 
    interface GetNow<bool> as IsRxBroadcastPending; 
    interface GetNow<bool> as IsRxEnableActive; 
    interface Get<ieee154_txframe_t*> as GetIndirectTxFrame; 
    interface Notify<bool> as RxEnableStateChange;
    interface GetNow<bool> as IsTrackingBeacons;
    interface FrameUtility;
    interface RadioTx;
    interface RadioRx;
    interface RadioOff;
    interface GetNow<bool> as IsBeaconEnabledPAN;
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

  command ieee154_status_t FrameTx.transmit(ieee154_txframe_t *frame)
  {
    return IEEE154_TRANSACTION_OVERFLOW;
   }

  async event void RadioTx.loadDone(){ }
  async event void RadioOff.offDone(){ }
  async event void RadioRx.prepareDone(){ }

  async event void CapEndAlarm.fired(){ }
  async event void BLEAlarm.fired(){ }
  event void RxEnableStateChange.notify(bool whatever){ }
  async event void BroadcastAlarm.fired(){ }

  async event void IndirectTxWaitAlarm.fired() { }
  
  async event void RadioTx.transmitUnslottedCsmaCaDone(ieee154_txframe_t *frame,
      bool ackPendingFlag, ieee154_csma_t *csmaParams, error_t result)
  {
  }

  async event void RadioTx.transmitSlottedCsmaCaDone(ieee154_txframe_t *frame, ieee154_reftime_t *txTime, 
      bool ackPendingFlag, uint16_t remainingBackoff, ieee154_csma_t *csmaParams, error_t result)
  {
  }

  void transmitDone(ieee154_txframe_t *frame, ieee154_reftime_t *txTime, 
      bool ackPendingFlag, ieee154_csma_t *csmaParams, error_t result)
  {
  }

  event message_t* RadioRx.received(message_t* frame, ieee154_reftime_t *timestamp)
  {
    return frame;
  }

  async command ieee154_status_t BroadcastTx.transmitNow(ieee154_txframe_t *frame) 
  {
    return IEEE154_TRANSACTION_OVERFLOW;
  }

  event void Token.granted()
  {
  }

  async event void RadioTx.transmitDone(ieee154_txframe_t *frame, ieee154_reftime_t *txTime){}

  default event void FrameTx.transmitDone(ieee154_txframe_t *data, ieee154_status_t status){}
  default event message_t* FrameRx.received[uint8_t client](message_t* data){return data;}
  default async command bool IsRxEnableActive.getNow(){return FALSE;}

  default async command void IndirectTxWaitAlarm.start(uint32_t dt){call Leds.led0On();}
  default async command void IndirectTxWaitAlarm.stop(){call Leds.led0On();}
  default async command void IndirectTxWaitAlarm.startAt(uint32_t t0, uint32_t dt){call Leds.led0On();}
  
  default async command void BroadcastAlarm.start(uint32_t dt){call Leds.led0On();}
  default async command void BroadcastAlarm.stop(){call Leds.led0On();}
  default async command void BroadcastAlarm.startAt(uint32_t t0, uint32_t dt){call Leds.led0On();}

  default async command bool IsRxBroadcastPending.getNow(){ return FALSE;}
  default async event void BroadcastTx.transmitNowDone(ieee154_txframe_t *frame, ieee154_status_t status){}
  default event message_t* FrameExtracted.received[uint8_t client](message_t* msg, ieee154_txframe_t *txFrame){return msg;}
  default async command error_t FrameBackup.setNow(ieee154_cap_frame_backup_t* val ){return FAIL;}
  default async command ieee154_cap_frame_backup_t* FrameRestore.getNow(){return NULL;}

  command error_t WasRxEnabled.enable(){return FAIL;}
  command error_t WasRxEnabled.disable(){return FAIL;}
  command error_t FindBeacon.enable(){return FAIL;}
  command error_t FindBeacon.disable(){return FAIL;}
}
