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
 * $Date: 2008-06-16 18:00:28 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "TKN154_PHY.h"
#include "TKN154_MAC.h"
module RxEnableP
{
  provides
  {
    interface Init;
    interface MLME_RX_ENABLE;
    interface SplitControl as PromiscuousMode;
    interface FrameRx;
    interface Get<bool> as PromiscuousModeGet;
    interface GetNow<bool> as IsRxEnableActive; 
    interface Notify<bool> as RxEnableStateChange;
  }
  uses
  {
    interface Resource as Token;
    interface RadioRx as PromiscuousRx;
    interface RadioOff;
    interface Set<bool> as RadioPromiscuousMode;
    interface Ieee802154Debug as Debug;
    interface Timer<TSymbolIEEE802154> as RxEnableTimer;
    interface Get<bool> as IsBeaconEnabledPAN;
    interface Get<ieee154_macPanCoordinator_t> as IsMacPanCoordinator;
    interface Get<bool> as IsTrackingBeacons;
    interface GetNow<uint32_t> as IncomingSfStart; 
    interface GetNow<uint32_t> as IncomingBeaconInterval; 
    interface Get<bool> as IsSendingBeacons;
    interface GetNow<uint32_t> as OutgoingSfStart; 
    interface GetNow<uint32_t> as OutgoingBeaconInterval; 
    interface Notify<bool> as WasRxEnabled;
    interface TimeCalc;
  }
}
implementation
{
  enum promiscuous_state {
    S_IDLE,
    S_STARTING,
    S_STARTED,
    S_STOPPING,
  } m_promiscuousState;

  uint32_t m_rxOnDuration;
  uint32_t m_rxOnOffset;
  uint32_t m_rxOnAnchor;
  norace bool m_isRxEnabled;
  bool m_isRxEnableConfirmPending;

  task void prepareDoneTask();
  task void radioOffDoneTask();

  command error_t Init.init()
  {
    if (m_isRxEnableConfirmPending){
      m_isRxEnableConfirmPending = FALSE;
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
                          uint32_t RxOnDuration
                        )
  {
    uint32_t lastBeaconTime=0;
    uint32_t beaconInterval=0;

    if (m_isRxEnableConfirmPending)
      return IEEE154_TRANSACTION_OVERFLOW;
    if (RxOnTime > 0xFFFFFF || RxOnDuration > 0xFFFFFF)
      return IEEE154_INVALID_PARAMETER;
    if (call IsBeaconEnabledPAN.get()){
      if (call IsSendingBeacons.get() && call IsMacPanCoordinator.get()){
        // for OUTGOING SUPERFRAME
        lastBeaconTime = call OutgoingSfStart.getNow();
        beaconInterval = call OutgoingBeaconInterval.getNow();
      } else if (call IsTrackingBeacons.get()){
        // for INCOMING SUPERFRAME 
        lastBeaconTime = call IncomingSfStart.getNow();
        beaconInterval = call IncomingBeaconInterval.getNow();
      }
      if (beaconInterval == 0)
        return IEEE154_PAST_TIME; // we're not even sending/receiving beacons
      if (RxOnTime+RxOnDuration >= beaconInterval)
        return IEEE154_ON_TIME_TOO_LONG;
      if (call TimeCalc.hasExpired(lastBeaconTime, RxOnTime - IEEE154_aTurnaroundTime)){
        if (!DeferPermit)
          return IEEE154_PAST_TIME;
        else {
          // defer to next beacon
          RxOnTime += beaconInterval;
        }
      }
      m_rxOnAnchor = lastBeaconTime;
      m_rxOnOffset = RxOnTime;
    } else {
      m_rxOnAnchor = call RxEnableTimer.getNow();
      m_rxOnOffset = 0;
    }
    m_rxOnDuration = RxOnDuration;      
    m_isRxEnabled = FALSE;
    m_isRxEnableConfirmPending = TRUE;
    call RxEnableTimer.startOneShotAt(m_rxOnAnchor, m_rxOnOffset);
    signal RxEnableStateChange.notify(TRUE);
    return IEEE154_SUCCESS;
  }

  event void RxEnableTimer.fired()
  {
    if (!m_isRxEnabled){
      m_isRxEnabled = TRUE;
      call RxEnableTimer.startOneShotAt(m_rxOnAnchor, m_rxOnOffset + m_rxOnDuration);
    } else {
      m_isRxEnabled = FALSE;
      if (m_isRxEnableConfirmPending){
        // this means we tried to enable rx, but never
        // succeeded, because there were  "other 
        // responsibilities" - but is SUCCESS really
        // an appropriate error code in this case?
        m_isRxEnableConfirmPending = FALSE;
        signal MLME_RX_ENABLE.confirm(IEEE154_SUCCESS);
      }
    }
    signal RxEnableStateChange.notify(TRUE);
  }

  async command bool IsRxEnableActive.getNow()
  { 
    return m_isRxEnabled;
  }

  event void WasRxEnabled.notify( bool val )
  {
    if (m_isRxEnabled && m_isRxEnableConfirmPending){
      m_isRxEnableConfirmPending = FALSE;
      signal MLME_RX_ENABLE.confirm(IEEE154_SUCCESS);
    }
  }

  command error_t RxEnableStateChange.enable(){return FAIL;}
  command error_t RxEnableStateChange.disable(){return FAIL;}

/* ----------------------- Promiscuous Mode ----------------------- */

  command bool PromiscuousModeGet.get()
  {
    return (m_promiscuousState == S_STARTED);
  }

  command error_t PromiscuousMode.start()
  {
    if (m_promiscuousState != S_IDLE)
      return FAIL;
    m_promiscuousState = S_STARTING;
    call Token.request();
    call Debug.log(LEVEL_INFO, EnableRxP_PROMISCUOUS_REQUEST, m_promiscuousState, 0, 0);
    call Debug.flush();
    return SUCCESS;
  }

  event void Token.granted()
  {
    if (m_promiscuousState != S_STARTING){
      call Token.release();
      return;
    }
    call RadioPromiscuousMode.set(TRUE);
    if (call PromiscuousRx.prepare() != IEEE154_SUCCESS){
      m_promiscuousState = S_IDLE;
      call Token.release();
      call Debug.log(LEVEL_IMPORTANT, EnableRxP_RADIORX_ERROR, 0, 0, 0);
      signal PromiscuousMode.startDone(FAIL);
    }
  }

  async event void PromiscuousRx.prepareDone()
  {
    post prepareDoneTask();
  }

  task void prepareDoneTask()
  {
    if (m_promiscuousState != S_STARTING){
      call Token.release();
      return;
    }    
    m_promiscuousState = S_STARTED;
    call PromiscuousRx.receive(NULL, 0);
    signal PromiscuousMode.startDone(SUCCESS);
    call Debug.log(LEVEL_INFO, EnableRxP_PROMISCUOUS_ON, m_promiscuousState, 0, 0);
  }

  event message_t* PromiscuousRx.received(message_t *frame, ieee154_reftime_t *timestamp)
  {
    if (m_promiscuousState == S_STARTED){
      ((ieee154_header_t*) frame->header)->length |= FRAMECTL_PROMISCUOUS;
      return signal FrameRx.received(frame);
    } else
      return frame;
  }

  command error_t PromiscuousMode.stop()
  {
    if (m_promiscuousState != S_STARTED)
      return FAIL;
    m_promiscuousState = S_STOPPING;
    call RadioOff.off();
    return SUCCESS;
  }

  async event void RadioOff.offDone()
  {
    post radioOffDoneTask();
  }

  task void radioOffDoneTask()
  {
    if (m_promiscuousState != S_STOPPING){
      call Token.release();
      return;
    }
    m_promiscuousState = S_IDLE;
    call RadioPromiscuousMode.set(FALSE);
    call Token.release();
    signal PromiscuousMode.stopDone(SUCCESS);
    call Debug.log(LEVEL_INFO, EnableRxP_PROMISCUOUS_OFF, m_promiscuousState, 0, 0);
  }

  default event void PromiscuousMode.startDone(error_t error){}
  default event void PromiscuousMode.stopDone(error_t error){}
  default event void MLME_RX_ENABLE.confirm(ieee154_status_t status){}
}
