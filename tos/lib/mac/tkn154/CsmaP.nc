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
 * $Date: 2008-10-21 17:29:00 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "TKN154_PHY.h"
#include "TKN154_MAC.h"

/** 
 * This module implements the slotted and unslotted CSMA-CA algorithm.
 * Unslotted CSMA-CA is used in nonbeacon-enabled PANs, slotted CSMA-CA is used
 * in beacon-enabled PANs. In a beacon-enabled PAN this module is responsible
 * for channel access during the contention access period (CAP). It does
 * slightly different things depending on whether it is the CAP for an outgoing
 * superframe (superframeDirection = OUTGOING_SUPERFRAME), i.e. the CAP from
 * the perspective of a coordinator after it has transmitted its own beacon; or
 * for an incoming superframe (superframeDirection = INCOMING_SUPERFRAME), i.e.
 * the CAP from the perspective of a device after it has received a beacon from
 * its coordinator; for example, in the CAP a coordinator will usually listen for
 * incoming frames from the devices, and a device will usually switch the radio
 * off unless it has a frame to transmit. In nonbeacon-enabled PANs the
 * superframeDirection parameter is ignored.
 */

generic module CsmaP(uint8_t superframeDirection)
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
    interface GetNow<bool> as IsRxBroadcastPending; 
    interface GetNow<bool> as IsRxEnableActive; 
    interface Notify<bool> as RxEnableStateChange;
    interface GetNow<bool> as IsTrackingBeacons;
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
  typedef enum {
    SWITCH_OFF,
    LOAD_TX,
    PREPARE_RX,
    DO_NOTHING,
    WAIT_FOR_TXDONE,
  } next_state_t;

  typedef enum {
    INDIRECT_TX_ALARM,
    BROADCAST_ALARM,
    NO_ALARM,
  } rx_alarm_t;

  enum {
    COORD_ROLE = (superframeDirection == OUTGOING_SUPERFRAME),
    DEVICE_ROLE = !COORD_ROLE,
  };

  norace bool m_lock;
  norace ieee154_txframe_t *m_currentFrame;
  norace ieee154_txframe_t *m_bcastFrame;
  norace ieee154_txframe_t *m_lastFrame;
  norace ieee154_macMaxBE_t m_BE;
  norace ieee154_macMaxBE_t m_NB;
  norace ieee154_macMaxBE_t m_numCCA;
  norace ieee154_macMaxCSMABackoffs_t m_macMaxCSMABackoffs;
  norace ieee154_macMaxFrameRetries_t m_macMaxFrameRetries;
  norace ieee154_macMaxBE_t m_macMaxBE;
  norace ieee154_macMinBE_t m_macMinBE;
  norace uint16_t m_backoff;
  norace uint16_t m_backoffElapsed;
  norace ieee154_status_t m_result;
  norace uint32_t m_transactionTime;
  norace bool m_indirectTxPending = FALSE;
  norace bool m_broadcastRxPending;
  norace ieee154_macMaxFrameTotalWaitTime_t m_macMaxFrameTotalWaitTime;
  norace bool m_isBeaconEnabledPAN;

  uint16_t generateRandomBackoff(uint8_t BE);
  void stopAllAlarms();
  next_state_t tryReceive(rx_alarm_t alarmType);
  next_state_t tryTransmit();
  next_state_t trySwitchOff();
  void backupCurrentFrame();
  void restoreFrameFromBackup();  
  void updateState();
  void setCurrentFrame(ieee154_txframe_t *frame);
  void signalTxBroadcastDone(ieee154_txframe_t *frame, ieee154_status_t error);
  task void signalTxDoneTask();
  task void setupTxBroadcastTask();
  task void wasRxEnabledTask();

  command error_t Reset.init()
  {
    if (call Token.isOwner()){
      call Leds.led0On(); // internal error
      return FAIL;
    }
    if (m_currentFrame)
      signal FrameTx.transmitDone(m_currentFrame, IEEE154_TRANSACTION_OVERFLOW);
    if (m_lastFrame)
      signal FrameTx.transmitDone(m_lastFrame, IEEE154_TRANSACTION_OVERFLOW);
    if (m_bcastFrame)
      signalTxBroadcastDone(m_bcastFrame, IEEE154_TRANSACTION_OVERFLOW);
    m_currentFrame = m_lastFrame = m_bcastFrame = NULL;
    m_macMaxFrameTotalWaitTime = call MLME_GET.macMaxFrameTotalWaitTime();
    m_isBeaconEnabledPAN = call IsBeaconEnabledPAN.get();
    stopAllAlarms();
    return SUCCESS;
  }

  async event void TokenTransferred.transferred()
  {
    // we got the token, i.e. CAP has just started    
    uint32_t actualCapLen = call CapLen.getNow();
    if (m_isBeaconEnabledPAN && (DEVICE_ROLE && !call IsTrackingBeacons.getNow())){
      // rare case: we're on a beacon-enabled PAN, not tracking beacons, searched
      // and didn't find a beacon for aBaseSuperframeDuration*(2n+1) symbols
      // -> transmit current frame using unslotted CSMA-CA
      m_numCCA = 1;
    } else if (actualCapLen < IEEE154_RADIO_GUARD_TIME){
      call Debug.log(LEVEL_IMPORTANT, CapP_TOO_SHORT, superframeDirection, actualCapLen, IEEE154_RADIO_GUARD_TIME);
      call TokenToCfp.transfer();
      return;
    } else {
      actualCapLen -= IEEE154_RADIO_GUARD_TIME;
      if (DEVICE_ROLE)
        m_broadcastRxPending = call IsRxBroadcastPending.getNow();
      else { 
        // COORD_ROLE
        if (m_bcastFrame != NULL) {
          // we have to transmit a broadcast frame immediately; this  
          // (possibly) requires a backup of the previously active frame
          // and a reinitializing the CSMA parameters -> will do it
          // in task context and then continue
          m_lock = TRUE;
          post setupTxBroadcastTask(); 
        }
      }
      call CapEndAlarm.startAt(call CapStart.getNow(), actualCapLen);
      if (call IsBLEActive.getNow())
        call BLEAlarm.startAt(call CapStart.getNow(), call BLELen.getNow());
      call Debug.log(LEVEL_IMPORTANT, CapP_SET_CAP_END, call CapStart.getNow(), 
          actualCapLen, call CapStart.getNow()+ actualCapLen);
    }
    updateState();
  }

  command ieee154_status_t FrameTx.transmit(ieee154_txframe_t *frame)
  {
    if (m_currentFrame != NULL)
      return IEEE154_TRANSACTION_OVERFLOW;
    else {
      setCurrentFrame(frame);
      if (!m_isBeaconEnabledPAN){
        call Token.request(); // prepare for unslotted CSMA-CA
      } else {
        // a beacon must be found before transmitting in a beacon-enabled PAN
        if (DEVICE_ROLE && !call IsTrackingBeacons.getNow()){
          signal FindBeacon.notify(TRUE);
          // we'll receive the Token at latest after aBaseSuperframeDuration*(2n+1) symbols; 
          // if the beacon was not found, then we'll send the frame using unslotted CSMA-CA
        }
        updateState();
      }
      return IEEE154_SUCCESS;
    }
  }

  task void setupTxBroadcastTask()
  {
    ieee154_macDSN_t tmp;
    ieee154_txframe_t *oldFrame = m_currentFrame;
    if (COORD_ROLE){
      if (m_bcastFrame != NULL){
        // broadcasts should be transmitted *immediately* after the beacon,
        // which may interrupt a pending transmit operation from the previous
        // CAP; back up the last active frame configuration (may be none)
        // and restore it after the broadcast frame has been transmitted; 
        // do this through interfaces and don't wire them for DEVICE_ROLE, 
        // so we don't waste the RAM of devices
        backupCurrentFrame();
        setCurrentFrame(m_bcastFrame);
        if (oldFrame){
          // now the sequence number are out of order... swap them back
          tmp = m_bcastFrame->header->mhr[MHR_INDEX_SEQNO];
          m_bcastFrame->header->mhr[MHR_INDEX_SEQNO] = 
            oldFrame->header->mhr[MHR_INDEX_SEQNO];
          oldFrame->header->mhr[MHR_INDEX_SEQNO] = tmp;
        }
      }
    }
    m_lock = FALSE;
    updateState(); 
  }

  void setCurrentFrame(ieee154_txframe_t *frame)
  {
    ieee154_macDSN_t dsn = call MLME_GET.macDSN();
    frame->header->mhr[MHR_INDEX_SEQNO] = dsn++;
    call MLME_SET.macDSN(dsn);
    m_macMaxCSMABackoffs =  call MLME_GET.macMaxCSMABackoffs();
    m_macMaxFrameRetries =  call MLME_GET.macMaxFrameRetries();
    m_macMaxBE = call MLME_GET.macMaxBE();
    m_macMinBE = call MLME_GET.macMinBE();
    if (call MLME_GET.macBattLifeExt() && m_macMinBE > 2)
      m_macMinBE = 2;
    m_BE = m_macMinBE;
    if (m_isBeaconEnabledPAN)
      m_numCCA = 2;
    else
      m_numCCA = 1;
    m_NB = 0;
    m_transactionTime = IEEE154_SHR_DURATION + 
      (frame->headerLen + frame->payloadLen) * IEEE154_SYMBOLS_PER_OCTET;
    if (frame->header->mhr[MHR_INDEX_FC1] & FC1_ACK_REQUEST)
      m_transactionTime += (IEEE154_aTurnaroundTime + IEEE154_aUnitBackoffPeriod + 
          11 * IEEE154_SYMBOLS_PER_OCTET);
    if (frame->headerLen + frame->payloadLen > IEEE154_aMaxSIFSFrameSize)
      m_transactionTime += call MLME_GET.macMinLIFSPeriod();
    else
      m_transactionTime += call MLME_GET.macMinSIFSPeriod();
    m_backoff = generateRandomBackoff(m_BE) * IEEE154_aUnitBackoffPeriod; // initial backoff
    m_macMaxFrameTotalWaitTime = call MLME_GET.macMaxFrameTotalWaitTime();
    m_backoffElapsed = 0;
    m_currentFrame = frame;
  }

  uint16_t generateRandomBackoff(uint8_t BE)
  {
    // return random number from [0,(2^BE) - 1] (uniform distr.)
    uint16_t res = call Random.rand16();
    uint16_t mask = 0xFFFF;
    mask <<= BE;
    mask = ~mask;
    res &= mask;
    return res;
  }
 
  void stopAllAlarms()
  {
    call CapEndAlarm.stop();
    if (DEVICE_ROLE){
      call IndirectTxWaitAlarm.stop();
      call BroadcastAlarm.stop();
    }
    call BLEAlarm.stop();
  }

  /** 
   * The updateState() function is called whenever some event happened that
   * might require a state change; it implements a lock mechanism (m_lock) to
   * prevent race conditions. Whenever the lock is set a "done"-event (from a
   * RadioTx/RadioRx/RadioOff interface) is pending and will "soon" unset the
   * lock (and then updateState() will called again).  The updateState()
   * function decides about the next state by checking a list of possible
   * current states ordered by priority, e.g. it first always checks whether
   * the CAP is still active. Calling this function more than necessary can do
   * no harm, but it SHOULD be called whenever an event happened that might
   * lead to a state change.
   */ 

  void updateState()
  {
    error_t result = SUCCESS;
    next_state_t next;
    atomic {
      // long atomics are bad... but in this block, once the
      // current state has been determined only one branch will
      // be taken (no loops, etc.)
      if (m_lock || !call Token.isOwner())
        return;
      m_lock = TRUE; // lock

      // Check 1: for beacon-enabled PANs, has the CAP finished?
      if (m_isBeaconEnabledPAN 
          && (COORD_ROLE || call IsTrackingBeacons.getNow()) // FALSE only if device could't find a beacon
          && (call TimeCalc.hasExpired(call CapStart.getNow(), call CapLen.getNow()-IEEE154_RADIO_GUARD_TIME) ||
          !call CapEndAlarm.isRunning())){
        if (call RadioOff.isOff()) {
          stopAllAlarms();  // may still fire, locked through isOwner()
          if (DEVICE_ROLE && m_indirectTxPending)
            signal IndirectTxWaitAlarm.fired();
          m_broadcastRxPending = FALSE;
          if (COORD_ROLE && m_bcastFrame){
            // didn't manage to transmit a broadcast
            restoreFrameFromBackup();
            signalTxBroadcastDone(m_bcastFrame, IEEE154_CHANNEL_ACCESS_FAILURE);
            m_bcastFrame = NULL;
          }
          m_lock = FALSE; // unlock
          call TokenToCfp.transfer();
          return;
        } else 
          next = SWITCH_OFF;
      }

      // Check 2: should a broadcast frame be received/transmitted immediately
      // at the start of CAP?
      else if (DEVICE_ROLE && m_broadcastRxPending){
        // receive a broadcast from coordinator
        next = tryReceive(BROADCAST_ALARM);
      } else if (COORD_ROLE && m_bcastFrame){
        next = tryTransmit();
      }

      // Check 3: was an indirect transmission successfully started 
      // and are we now waiting for a frame from the coordinator?
      else if (DEVICE_ROLE && m_indirectTxPending) {
        next = tryReceive(INDIRECT_TX_ALARM);
      }

      // Check 4: is some other operation (like MLME-SCAN or MLME-RESET) pending? 
      else if (call IsTokenRequested.getNow()) {
        if (call RadioOff.isOff()) {
          stopAllAlarms();  // may still fire, locked through isOwner()
          call Token.release();
          next = DO_NOTHING;
        } else 
          next = SWITCH_OFF;
      }

      // Check 5: is battery life extension (BLE) active and 
      // has the BLE period expired?
      else if (call IsBLEActive.getNow() &&
          call TimeCalc.hasExpired(call CapStart.getNow(), call BLELen.getNow()) &&
          !call IsRxEnableActive.getNow()) {
        next = trySwitchOff();
      }

      // Check 6: is there a frame ready to transmit?
      else if (m_currentFrame != NULL) {
        next = tryTransmit();
      }

      // Check 7: should we be in receive mode?
      else if (COORD_ROLE || call IsRxEnableActive.getNow()) {
        next = tryReceive(NO_ALARM);
        if (next == DO_NOTHING && call IsRxEnableActive.getNow()){
          // this means there is an active MLME_RX_ENABLE.request
          // and the radio was just switched to Rx mode - signal
          // a notify event to inform the next higher layer
          post wasRxEnabledTask();
        }
      }

      // Check 8: just make sure the radio is switched off  
      else {
        next = trySwitchOff();
        if (next == DO_NOTHING && (!m_isBeaconEnabledPAN || (DEVICE_ROLE && !call IsTrackingBeacons.getNow()))){
          // nothing more to do... just release the Token
          m_lock = FALSE; // unlock
          call TokenToCfp.transfer();
          return;
        }
      }

      // if there is nothing to do, then we must clear the lock
      if (next == DO_NOTHING)
        m_lock = FALSE;
    } // atomic
    // put next state in operation (possibly keeping the lock)
    switch (next)
    {
      case SWITCH_OFF: result = call RadioOff.off(); break;
      case LOAD_TX: result = call RadioTx.load(m_currentFrame); break;
      case PREPARE_RX: result = call RadioRx.prepare(); break;
      case WAIT_FOR_TXDONE: break;
      case DO_NOTHING: break;
    }
    if (result != SUCCESS)
      call Leds.led0On(); // internal error: could not update state !!!
  }
  
  next_state_t tryTransmit()
  {
    // tries to transmit m_currentFrame using the configuration stored
    // in other module variables (m_backoff, etc.)
    next_state_t next;
    if (call RadioTx.getLoadedFrame() == m_currentFrame){
      // the frame is already loaded -> transmit it now
      if (m_numCCA == 1){
        // unslotted CSMA-CA
        call RadioTx.transmit(NULL, m_backoff, m_numCCA, m_currentFrame->header->mhr[MHR_INDEX_FC1] & FC1_ACK_REQUEST ? TRUE : FALSE);
        next = WAIT_FOR_TXDONE; // this will NOT clear the lock
      } else {
        // slotted CSMA-CA
        uint32_t capLen = call CapLen.getNow(), capStart = call CapStart.getNow();
        uint32_t elapsed, totalTime;
        totalTime = IEEE154_RADIO_TX_SEND_DELAY + 
          m_backoff - m_backoffElapsed + m_transactionTime + IEEE154_RADIO_GUARD_TIME;
        if (totalTime > capLen)
          totalTime = capLen; // CAP is too short
        elapsed = call TimeCalc.timeElapsed(capStart, call CapEndAlarm.getNow());
        elapsed += (20 - (elapsed % 20)); // round to backoff boundary
        if (!call TimeCalc.hasExpired(capStart, capLen - totalTime)){
          call RadioTx.transmit(call CapStartRefTime.getNow(), 
              elapsed + IEEE154_RADIO_TX_SEND_DELAY + m_backoff - m_backoffElapsed, 
              m_numCCA, 
              m_currentFrame->header->mhr[MHR_INDEX_FC1] & FC1_ACK_REQUEST ? TRUE : FALSE);
          next = WAIT_FOR_TXDONE; // this will NOT clear the lock
        } else {
          // frame does not fit in remaing portion of the CAP
          if (elapsed < call CapLen.getNow()){
            m_backoffElapsed += call CapLen.getNow() - elapsed;
            if (m_backoffElapsed > m_backoff)
              m_backoffElapsed = m_backoff;
          }
          next = SWITCH_OFF;
        }
      }
    } else {
      // the frame to transmit has not yet been loaded -> load it now
      if (!call RadioOff.isOff())
        next = SWITCH_OFF;
      else {
        if (m_lastFrame){
          // the done event for the previous frame has not yet been
          // signalled to the upper layer -> wait
          next = DO_NOTHING; 
        } else
          next = LOAD_TX;
      }
    }
    return next;
  }

  next_state_t tryReceive(rx_alarm_t alarmType)
  {
    next_state_t next;
    if (call RadioRx.isReceiving()){
      next = DO_NOTHING;
    } else if (call RadioRx.isPrepared()){
      call RadioRx.receive(NULL, 0);
      switch (alarmType)
      {
        case INDIRECT_TX_ALARM: call IndirectTxWaitAlarm.start(m_macMaxFrameTotalWaitTime); break;
        case BROADCAST_ALARM: call BroadcastAlarm.start(m_macMaxFrameTotalWaitTime); break;
        case NO_ALARM: break;
      }
      next = DO_NOTHING;
    } else if (call RadioOff.isOff())
      next = PREPARE_RX;
    else
      next = SWITCH_OFF;
    return next;
  }

  next_state_t trySwitchOff()
  {
    next_state_t next;
    if (call RadioOff.isOff())
      next = DO_NOTHING;
    else
      next = SWITCH_OFF;
    return next;
  }

  async event void RadioTx.loadDone(){ m_lock = FALSE; updateState();}
  async event void RadioOff.offDone(){ m_lock = FALSE; updateState();}
  async event void RadioRx.prepareDone(){ m_lock = FALSE; updateState();}

  async event void CapEndAlarm.fired(){ 
    call Debug.log(LEVEL_IMPORTANT, CapP_CAP_END_FIRED, superframeDirection, 0, 0);
    updateState();
  }
  async event void BLEAlarm.fired(){ updateState();}
  event void RxEnableStateChange.notify(bool whatever){ updateState();}
  async event void BroadcastAlarm.fired(){ m_broadcastRxPending = FALSE; updateState();}

  async event void IndirectTxWaitAlarm.fired() 
  { 
    atomic {
      if (m_indirectTxPending){
        m_indirectTxPending = FALSE; 
        post signalTxDoneTask(); 
      }
    }
  }

  async event void RadioTx.transmitDone(ieee154_txframe_t *frame, 
      ieee154_reftime_t *referenceTime, bool ackPendingFlag, error_t error)
  {
    bool retry = FALSE;
    switch (error)
    {
      case SUCCESS:
        m_result = IEEE154_SUCCESS;
        if (DEVICE_ROLE && frame->payload[0] == CMD_FRAME_DATA_REQUEST &&
            ((frame->header->mhr[MHR_INDEX_FC1]) & FC1_FRAMETYPE_MASK) == FC1_FRAMETYPE_CMD){
          // just transmitted a data request frame
          m_result = IEEE154_NO_DATA; // pessimistic 
          if (ackPendingFlag){
            // the coordinator has data for us; switch to Rx 
            // to complete the indirect transmission
            m_indirectTxPending = TRUE;
            m_lastFrame = m_currentFrame;
            m_currentFrame = NULL;
            if (call RadioRx.prepare() != SUCCESS) // SHOULD succeed
              call RadioOff.off();
            return;
          }
        }
        break;
      case EBUSY:
        // we're following the SDL Spec in IEEE 802.15.4-2003 Annex D
        m_result = IEEE154_CHANNEL_ACCESS_FAILURE;
        m_NB += 1;
        if (m_NB < m_macMaxCSMABackoffs){
          m_BE += 1;
          if (m_BE > m_macMaxBE)
            m_BE = m_macMaxBE;
          retry = TRUE;
        }
        break;
      case ENOACK:
        // we're following the SDL Spec in IEEE 802.15.4-2003 Annex D
        m_result = IEEE154_NO_ACK;
        m_NB += 1;
        // shouldn't the next check be (m_NB-1 < m_macMaxFrameRetries)? but
        // on the other hand, NB is used for CHANNEL_ACCESS_FAILURE and NO_ACK,
        // i.e. m_NB does not tell us much about past retransmissions anyway...
        if (m_NB < m_macMaxFrameRetries){
          m_BE = m_macMinBE;
          retry = TRUE;
        }
        break;
      default: break;
    }
    if (retry){
      m_backoff = generateRandomBackoff(m_BE) * IEEE154_aUnitBackoffPeriod; // next backoff
      m_backoffElapsed = 0;
    } else if (COORD_ROLE && frame == m_bcastFrame){
      // signal result of broadcast transmissions immediately 
      restoreFrameFromBackup();
      signalTxBroadcastDone(m_bcastFrame, m_result);
      m_bcastFrame = NULL;
    } else {
      m_lastFrame = m_currentFrame;
      m_currentFrame = NULL;
      post signalTxDoneTask();
    }    
    m_lock = FALSE;
    updateState();
  }

  task void signalTxDoneTask()
  {
    ieee154_txframe_t *lastFrame = m_lastFrame;
    m_lastFrame = NULL; // only now can a next transmission begin 
    m_indirectTxPending = FALSE;
    if (lastFrame)
      signal FrameTx.transmitDone(lastFrame, m_result);
    updateState();
  }

  event message_t* RadioRx.received(message_t* frame, ieee154_reftime_t *timestamp)
  {
    // received a frame during CAP - find out frame type and
    // signal it to corresponding client component
    uint8_t *payload = (uint8_t *) frame->data;
    uint8_t *mhr = MHR(frame);
    uint8_t frameType = mhr[MHR_INDEX_FC1] & FC1_FRAMETYPE_MASK;
    if (frameType == FC1_FRAMETYPE_CMD)
      frameType += payload[0];
    atomic {
      if (DEVICE_ROLE && m_indirectTxPending){
        message_t* frameBuf;
        call IndirectTxWaitAlarm.stop();
        // TODO: check!
        //if (frame->payloadLen)
          // is this frame from our coordinator? hmm... we cannot say
          // with certainty, because we might only know either the 
          // coordinator extended or short address (and the frame could
          // have been sent with the other addressing mode) ??
          m_result = IEEE154_SUCCESS;
        frameBuf = signal FrameExtracted.received[frameType](frame, m_lastFrame);
        signal IndirectTxWaitAlarm.fired();
        return frameBuf;
      } else
        return signal FrameRx.received[frameType](frame);
    }
  }

  void backupCurrentFrame()
  {
    ieee154_cap_frame_backup_t backup = {m_currentFrame, m_BE, m_macMaxCSMABackoffs, 
      m_macMaxBE, m_macMinBE, m_NB, m_backoff, m_backoffElapsed, m_transactionTime};
    call FrameBackup.setNow(&backup);
  }

  void restoreFrameFromBackup()
  {
    ieee154_cap_frame_backup_t *backup = call FrameRestore.getNow();
    if (backup != NULL){
      m_currentFrame = backup->frame;
      m_BE = backup->BE;
      m_macMaxCSMABackoffs = backup->allowedBackoffs;
      m_macMaxBE = backup->macMaxBE; 
      m_macMinBE = backup->macMinBE; 
      m_NB = backup->NB; 
      m_backoff = backup->backoff;
      m_backoffElapsed = backup->backoffElapsed;
      m_transactionTime = backup->transactionTime;
    }
  }

  async command ieee154_status_t BroadcastTx.transmitNow(ieee154_txframe_t *frame) 
  {
    // if this command is called then it is (MUST be) called 
    // only just before the token is transferred to this component
    // and it is then be called only once per CAP (max. one broadcast 
    // is allowed after a beacon transmission)
    atomic {
      if (!call Token.isOwner() && m_bcastFrame == NULL){
        m_bcastFrame = frame;
        return IEEE154_SUCCESS;
      } else {
        call Leds.led0On();
        return IEEE154_TRANSACTION_OVERFLOW;
      }
    }
  }

  void signalTxBroadcastDone(ieee154_txframe_t *frame, ieee154_status_t error)
  {
    signal BroadcastTx.transmitNowDone(frame, error);
  }

  task void wasRxEnabledTask()
  {
    signal WasRxEnabled.notify(TRUE);
  }

  bool isUnslottedCSMA_CA()
  {
    return (m_numCCA == 1);
  }

  event void Token.granted()
  {
    // will not happen
  }

  task void tokenRequestedTask()
  {
    signal TokenRequested.requested();
  }

  async event void TokenRequested.requested() 
  {
    // TODO: this event can be generated by the BeaconTransmitP or
    // BeaconSynchronizeP component - in this case the Token should
    // probably not be released!
    atomic {
      if (call Token.isOwner()){
        if (!m_lock && !(DEVICE_ROLE && m_indirectTxPending) && !(COORD_ROLE && m_bcastFrame))
          call Token.release();
        else
          post tokenRequestedTask();
      }
    }
  }

  async event void TokenRequested.immediateRequested() {}

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
