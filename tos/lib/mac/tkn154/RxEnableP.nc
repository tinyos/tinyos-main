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
 * $Revision: 1.5 $
 * $Date: 2009-03-04 18:31:29 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "TKN154_PHY.h"
#include "TKN154_MAC.h"
module RxEnableP
{
  provides
  {
    interface Init as Reset;
    interface MLME_RX_ENABLE;
    interface GetNow<bool> as IsRxEnableActive; 
    interface Notify<bool> as RxEnableStateChange;
  }
  uses
  {
    interface Timer<TSymbolIEEE802154> as RxEnableTimer;
    interface Get<ieee154_macPanCoordinator_t> as IsMacPanCoordinator;
    interface SuperframeStructure as IncomingSuperframeStructure;
    interface SuperframeStructure as OutgoingSuperframeStructure;
    interface GetNow<bool> as IsTrackingBeacons;
    interface GetNow<bool> as IsSendingBeacons;
    interface Notify<bool> as WasRxEnabled;
    interface TimeCalc;
  }
}
implementation
{

  uint32_t m_rxOnDuration;
  uint32_t m_rxOnOffset;
  uint32_t m_rxOnAnchor;
  norace bool m_isRxEnabled;
  bool m_confirmPending;

  command error_t Reset.init()
  {
    if (m_confirmPending) {
      m_confirmPending = FALSE;
      signal MLME_RX_ENABLE.confirm(IEEE154_SUCCESS);
    }
    m_isRxEnabled = FALSE;
    call RxEnableTimer.stop();
    return SUCCESS;
  }

  /* ----------------------- MLME-RX-ENABLE ----------------------- */

  command ieee154_status_t MLME_RX_ENABLE.request  ( 
                          bool DeferPermit,
                          uint32_t RxOnTime,
                          uint32_t RxOnDuration)
  {
    ieee154_status_t status = IEEE154_SUCCESS;
    uint32_t lastBeaconTime=0;
    uint32_t beaconInterval=0;

    if (m_confirmPending)
      status = IEEE154_TRANSACTION_OVERFLOW;
    else if (IEEE154_BEACON_ENABLED_PAN && RxOnTime > 0xFFFFFF)
      status = IEEE154_INVALID_PARAMETER;
    else if (RxOnDuration > 0xFFFFFF)
      status = IEEE154_INVALID_PARAMETER;
    else if (IEEE154_BEACON_ENABLED_PAN) {
      if (call IsSendingBeacons.getNow() && call IsMacPanCoordinator.get()) {
        // for OUTGOING SUPERFRAME
        lastBeaconTime = call OutgoingSuperframeStructure.sfStartTime();
        beaconInterval = call OutgoingSuperframeStructure.sfSlotDuration() * 16;
      } else if (call IsTrackingBeacons.getNow()) {
        // for INCOMING SUPERFRAME 
        lastBeaconTime = call IncomingSuperframeStructure.sfStartTime();
        beaconInterval = call IncomingSuperframeStructure.sfSlotDuration() * 16;
      }
      if (beaconInterval == 0)
        status = IEEE154_PAST_TIME; // we're not even sending/receiving beacons
      else if (RxOnTime+RxOnDuration >= beaconInterval)
        status = IEEE154_ON_TIME_TOO_LONG;
      else if (call TimeCalc.hasExpired(lastBeaconTime, RxOnTime - IEEE154_aTurnaroundTime)) {
        if (!DeferPermit)
          status = IEEE154_PAST_TIME;
        else {
          // defer to next beacon
          RxOnTime += beaconInterval;
        }
      }
      if (status == IEEE154_SUCCESS) {
        m_rxOnAnchor = lastBeaconTime;
        m_rxOnOffset = RxOnTime;
      }
    } else {
      // this is a nonbeacon-enabled PAN
      m_rxOnAnchor = call RxEnableTimer.getNow();
      m_rxOnOffset = 0;
    }

    if (status == IEEE154_SUCCESS) {
      m_rxOnDuration = RxOnDuration;      
      m_isRxEnabled = FALSE;
      m_confirmPending = TRUE;
      call RxEnableTimer.startOneShotAt(m_rxOnAnchor, m_rxOnOffset);
      signal RxEnableStateChange.notify(TRUE);
    }
    dbg_serial("RxEnableP", "MLME_RX_ENABLE.request -> result: %lu\n", (uint32_t) status);
    return status;
  }

  event void RxEnableTimer.fired()
  {
    if (!m_isRxEnabled) {
      m_isRxEnabled = TRUE;
      call RxEnableTimer.startOneShotAt(m_rxOnAnchor, m_rxOnOffset + m_rxOnDuration);
    } else {
      m_isRxEnabled = FALSE;
      if (m_confirmPending) {
        // this means we tried to enable rx, but never succeeded, because
        // there were  "other responsibilities" - but is SUCCESS really
        // an appropriate error code in this case?
        m_confirmPending = FALSE;
        dbg_serial("RxEnableP", "never actually managed to switch to Rx mode\n");
        signal MLME_RX_ENABLE.confirm(IEEE154_SUCCESS);
      }
    }
    signal RxEnableStateChange.notify(TRUE);
  }

  async command bool IsRxEnableActive.getNow()
  { 
    return m_isRxEnabled;
  }

  event void WasRxEnabled.notify(bool val)
  {
    if (m_isRxEnabled && m_confirmPending) {
      m_confirmPending = FALSE;
      dbg_serial("RxEnableP", "MLME_RX_ENABLE.confirm, radio is now in Rx mode\n");
      signal MLME_RX_ENABLE.confirm(IEEE154_SUCCESS);
    }
  }

  command error_t RxEnableStateChange.enable() {return FAIL;}
  command error_t RxEnableStateChange.disable() {return FAIL;}
  default event void MLME_RX_ENABLE.confirm(ieee154_status_t status) {}
  default async command uint32_t IncomingSuperframeStructure.sfStartTime() {return 0;}
  default async command uint16_t IncomingSuperframeStructure.sfSlotDuration() {return 0;}
  default async command uint32_t OutgoingSuperframeStructure.sfStartTime() {return 0;}
  default async command uint16_t OutgoingSuperframeStructure.sfSlotDuration() {return 0;}
  default async command bool IsTrackingBeacons.getNow() { return FALSE;}
  default async command bool IsSendingBeacons.getNow() { return FALSE;}
  default command ieee154_macPanCoordinator_t IsMacPanCoordinator.get() { return FALSE;}
}
