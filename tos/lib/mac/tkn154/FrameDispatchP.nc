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
 * $Date: 2008-11-25 09:35:08 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "TKN154_PHY.h"
#include "TKN154_MAC.h"


/** 
 * This module is responsible for preparing the transmission/reception of DATA
 * and COMMAND frames in the contention access period (CAP, slotted CSMA-CA) or
 * in a nonbeacon-enabled PAN (unslotted CSMA-CA). It prepares the relevant
 * parameters of the CSMA-CA algorithm (NB, BE, etc.), but it does not implement
 * the CSMA-CA algorithm (the CSMA-CA algorithm is implemented in the radio
 * driver).
 *
 * In a beacon-enabled this module does slightly different things depending on
 * whether it is the CAP for an outgoing superframe (superframeDirection =
 * OUTGOING_SUPERFRAME), i.e. the CAP from the perspective of a coordinator
 * after it has transmitted its own beacon; or for an incoming superframe
 * (superframeDirection = INCOMING_SUPERFRAME), i.e.  the CAP from the
 * perspective of a device after it has received a beacon from its coordinator.
 * For example, in the CAP a coordinator will usually listen for incoming
 * frames from the devices, and a device will usually switch the radio off
 * unless it has a frame to transmit. In nonbeacon-enabled PANs the
 * superframeDirection parameter is ignored.
 */

generic module FrameDispatchP(uint8_t superframeDirection)
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

  norace ieee154_csma_t m_csmaParams;
  norace bool m_resume;
  norace uint16_t m_remainingBackoff;
  norace ieee154_macMaxBE_t m_BE;
  norace ieee154_macMaxCSMABackoffs_t m_macMaxCSMABackoffs;
  norace ieee154_macMaxBE_t m_macMaxBE;
  norace bool m_slottedCsma;
  norace ieee154_macMaxFrameRetries_t m_macMaxFrameRetries;
  norace ieee154_status_t m_result;
  norace uint32_t m_transactionTime;
  norace bool m_indirectTxPending = FALSE;
  norace bool m_broadcastRxPending;
  norace ieee154_macMaxFrameTotalWaitTime_t m_macMaxFrameTotalWaitTime;


#ifdef TKN154_SERIAL_DEBUG 
#define DEBUG_NEXT_BUFFER_SIZE 12
  norace uint8_t dbgHistory[DEBUG_NEXT_BUFFER_SIZE];
  norace uint8_t dbgHistoryIndex;
  void dbgHistoryReset(){dbgHistoryIndex=0; memset(dbgHistory, 0xFF, DEBUG_NEXT_BUFFER_SIZE);} 
  void dbgHistoryAdd(uint8_t nextState)
  {
    dbgHistory[dbgHistoryIndex] = nextState;
    dbgHistoryIndex = (dbgHistoryIndex+1) % DEBUG_NEXT_BUFFER_SIZE; 
  }
  void dbgHistoryFlush()
  {
    uint8_t i,k=dbgHistoryIndex;
    uint32_t s1=0xFFFFFFFF,s2=0xFFFFFFFF,s3=0xFFFFFFFF;
    for (i=0; i<4; i++){ s1 = s1 << 8; s1 |= dbgHistory[k]; k = (k+1) % DEBUG_NEXT_BUFFER_SIZE;}
    for (i=0; i<4; i++){ s2 = s2 << 8; s2 |= dbgHistory[k]; k = (k+1) % DEBUG_NEXT_BUFFER_SIZE;}
    for (i=0; i<4; i++){ s3 = s3 << 8; s3 |= dbgHistory[k]; k = (k+1) % DEBUG_NEXT_BUFFER_SIZE;}
    call Debug.log(DEBUG_LEVEL_INFO, 12, s1,s2,s3);
  }
#else
  void dbgHistoryReset(){} 
  void dbgHistoryAdd(uint8_t nextState){}
  void dbgHistoryFlush(){}
#endif

  void stopAllAlarms();
  next_state_t tryReceive(rx_alarm_t alarmType);
  next_state_t tryTransmit();
  next_state_t trySwitchOff();
  void backupCurrentFrame();
  void restoreFrameFromBackup();  
  void updateState();
  void setCurrentFrame(ieee154_txframe_t *frame);
  void signalTxBroadcastDone(ieee154_txframe_t *frame, ieee154_status_t error);
  void transmitDone(ieee154_txframe_t *frame, ieee154_reftime_t *txTime, 
      bool ackPendingFlag, ieee154_csma_t *csmaParams, error_t result);
  task void signalTxDoneTask();
  task void setupTxBroadcastTask();
  task void wasRxEnabledTask();

  command error_t Reset.init()
  {
    if (m_currentFrame)
      signal FrameTx.transmitDone(m_currentFrame, IEEE154_TRANSACTION_OVERFLOW);
    if (m_lastFrame)
      signal FrameTx.transmitDone(m_lastFrame, IEEE154_TRANSACTION_OVERFLOW);
    if (m_bcastFrame)
      signalTxBroadcastDone(m_bcastFrame, IEEE154_TRANSACTION_OVERFLOW);
    m_currentFrame = m_lastFrame = m_bcastFrame = NULL;
    stopAllAlarms();
    return SUCCESS;
  }

  async event void TokenTransferred.transferred()
  {
    // we got the token, i.e. CAP has just started    
    uint32_t actualCapLen = call CapLen.getNow();
    dbgHistoryReset();
    if (!call IsBeaconEnabledPAN.getNow()){
      call Leds.led0On(); // internal error! 
      call TokenToCfp.transfer();
      call Debug.log(DEBUG_LEVEL_IMPORTANT, 0, 0,0,0);
    } else if (DEVICE_ROLE && actualCapLen == 0){
      // very rare case: 
      // this can only happen, if we're on a beacon-enabled PAN, not tracking beacons, 
      // and searched but didn't find a beacon for aBaseSuperframeDuration*(2n+1) symbols
      // -> transmit current frame using unslotted CSMA-CA
      m_slottedCsma = FALSE;
      updateState();
      return;
    } else if (actualCapLen < IEEE154_ACTIVE_PERIOD_GUARD_TIME){
      call Debug.log(DEBUG_LEVEL_IMPORTANT, 1, superframeDirection, actualCapLen, IEEE154_ACTIVE_PERIOD_GUARD_TIME);
      call TokenToCfp.transfer();
      return;
    } else {
      actualCapLen -= IEEE154_ACTIVE_PERIOD_GUARD_TIME;
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
          call Debug.log(DEBUG_LEVEL_INFO, 7, 0,0,0);
        }
      }
      call CapEndAlarm.startAt(call CapStart.getNow(), actualCapLen);
      if (call IsBLEActive.getNow())
        call BLEAlarm.startAt(call CapStart.getNow(), call BLELen.getNow());
      call Debug.log(DEBUG_LEVEL_INFO, 2, call CapStart.getNow(), 
          actualCapLen, call CapStart.getNow()+ actualCapLen);
    }
    updateState();
  }

  command ieee154_status_t FrameTx.transmit(ieee154_txframe_t *frame)
  {
    //call Debug.log(DEBUG_LEVEL_INFO, 4, m_lock, call Token.isOwner(), m_currentFrame == NULL);
    if (m_currentFrame != NULL){
      call Debug.log(DEBUG_LEVEL_IMPORTANT, 5, 0,0,0);
      return IEEE154_TRANSACTION_OVERFLOW;
    } else {
      setCurrentFrame(frame);
      if (!call IsBeaconEnabledPAN.getNow()){
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
    m_csmaParams.NB = 0;
    m_csmaParams.macMaxCsmaBackoffs = m_macMaxCSMABackoffs = call MLME_GET.macMaxCSMABackoffs();
    m_csmaParams.macMaxBE = m_macMaxBE = call MLME_GET.macMaxBE();
    m_csmaParams.BE = call MLME_GET.macMinBE();
    if (call MLME_GET.macBattLifeExt() && m_csmaParams.BE > 2)
      m_csmaParams.BE = 2;
    m_BE = m_csmaParams.BE;
    if (COORD_ROLE && call GetIndirectTxFrame.get() == frame)
      m_macMaxFrameRetries =  0; // this is an indirect transmissions (never retransmit)
    else
      m_macMaxFrameRetries =  call MLME_GET.macMaxFrameRetries();
    m_slottedCsma = call IsBeaconEnabledPAN.getNow();
    m_transactionTime = IEEE154_SHR_DURATION + 
      (frame->headerLen + frame->payloadLen + 2) * IEEE154_SYMBOLS_PER_OCTET; // extra 2 for CRC
    if (frame->header->mhr[MHR_INDEX_FC1] & FC1_ACK_REQUEST)
      m_transactionTime += (IEEE154_aTurnaroundTime + IEEE154_aUnitBackoffPeriod + 
          11 * IEEE154_SYMBOLS_PER_OCTET); // 11 byte for the ACK PPDU
    //if (frame->headerLen + frame->payloadLen > IEEE154_aMaxSIFSFrameSize)
    //  m_transactionTime += call MLME_GET.macMinLIFSPeriod();
    //else
    //  m_transactionTime += call MLME_GET.macMinSIFSPeriod();
    m_macMaxFrameTotalWaitTime = call MLME_GET.macMaxFrameTotalWaitTime();
    m_currentFrame = frame;
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
      if (call IsBeaconEnabledPAN.getNow() 
          && (COORD_ROLE || call IsTrackingBeacons.getNow()) // FALSE only if device could't find a beacon
          && (call TimeCalc.hasExpired(call CapStart.getNow(), call CapLen.getNow()-IEEE154_ACTIVE_PERIOD_GUARD_TIME) ||
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
          call Debug.log(DEBUG_LEVEL_INFO, 8, 0,0,0);
          dbgHistoryFlush();
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
      else if (call IsTokenRequested.getNow() && call IsBeaconEnabledPAN.getNow()) {
        if (call RadioOff.isOff()) {
          stopAllAlarms();  // may still fire, but is locked through isOwner()
          // nothing more to do... just release the Token
          m_lock = FALSE; // unlock
          call TokenToCfp.transfer();
          call Debug.log(DEBUG_LEVEL_INFO, 9, call IsTokenRequested.getNow(),0,0);
          dbgHistoryFlush();
          return;
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
        if (next == DO_NOTHING && 
            (!call IsBeaconEnabledPAN.getNow() || (DEVICE_ROLE && call CapLen.getNow() == 0))){
          // nothing more to do... just release the Token
          stopAllAlarms();  // may still fire, but is locked through isOwner()
          m_lock = FALSE; // unlock
          call Debug.log(DEBUG_LEVEL_INFO, 10, 0,0,0);
          dbgHistoryFlush();
          call Token.release();
          return;
        }
      }

      // if there is nothing to do, then we must clear the lock
      if (next == DO_NOTHING)
        m_lock = FALSE;
    } // atomic
    dbgHistoryAdd(next);
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
    // tries to transmit m_currentFrame using the either slotted or unslotted csma-ca
    next_state_t next;
    if (call RadioTx.getLoadedFrame() == m_currentFrame){
      // the frame is already loaded -> transmit it now
      if (!m_slottedCsma){
        // unslotted CSMA-CA
        call RadioTx.transmitUnslottedCsmaCa(&m_csmaParams);
        next = WAIT_FOR_TXDONE; // this will NOT clear the lock
      } else {
        // slotted CSMA-CA
        uint32_t dtMax = call CapLen.getNow() - m_transactionTime - IEEE154_ACTIVE_PERIOD_GUARD_TIME;
        if (dtMax > call CapLen.getNow())
          dtMax = 0;
        if (call IsBLEActive.getNow()){
          // battery life extension
          uint16_t bleLen = call BLELen.getNow();
          if (bleLen < dtMax)
            dtMax = bleLen;
        }
        if (call TimeCalc.hasExpired(call CapStart.getNow() - 60, dtMax)) // 60 is for enabling Rx + 2 CCA
          next = SWITCH_OFF; // frame doesn't possibly fit in the remaining CAP
        else {
          call RadioTx.transmitSlottedCsmaCa(call CapStartRefTime.getNow(),
              dtMax, m_resume, m_remainingBackoff, &m_csmaParams);
          //call Debug.log(DEBUG_LEVEL_INFO, 13, call CapStart.getNow(), dtMax, m_resume);
          next = WAIT_FOR_TXDONE; // this will NOT clear the lock
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
    call Debug.log(DEBUG_LEVEL_IMPORTANT, 3, superframeDirection, 0, 0);
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
  
  async event void RadioTx.transmitUnslottedCsmaCaDone(ieee154_txframe_t *frame,
      bool ackPendingFlag, ieee154_csma_t *csmaParams, error_t result)
  {
    transmitDone(frame, NULL, ackPendingFlag, csmaParams, result);
  }

  async event void RadioTx.transmitSlottedCsmaCaDone(ieee154_txframe_t *frame, ieee154_reftime_t *txTime, 
      bool ackPendingFlag, uint16_t remainingBackoff, ieee154_csma_t *csmaParams, error_t result)
  {
    if (result == ERETRY){
      m_resume = TRUE;
      m_remainingBackoff = remainingBackoff;
    } else
      m_resume = FALSE;
    transmitDone(frame, txTime, ackPendingFlag, csmaParams, result);
  }

  void transmitDone(ieee154_txframe_t *frame, ieee154_reftime_t *txTime, 
      bool ackPendingFlag, ieee154_csma_t *csmaParams, error_t result)
  {
    bool done = TRUE;
    //call Debug.log(DEBUG_LEVEL_INFO, 11, result,0,0);
    switch (result)
    {
      case SUCCESS:
        // frame was successfully transmitted, if ACK was requested
        // then a matching ACK was successfully received also
        m_result = IEEE154_SUCCESS;
        if (DEVICE_ROLE && frame->payload[0] == CMD_FRAME_DATA_REQUEST &&
            ((frame->header->mhr[MHR_INDEX_FC1]) & FC1_FRAMETYPE_MASK) == FC1_FRAMETYPE_CMD){
          // this was a data request frame
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
      case FAIL:
        // CSMA-CA algorithm failed: frame was not transmitted,
        // because channel was never idle (including backoff attempts)
        m_result = IEEE154_CHANNEL_ACCESS_FAILURE;
        break;
      case ENOACK:
        // frame was transmitted, but we didn't receive an ACK (and
        // the AckRequest flag was set in the frame header)
        // note: coordinator never retransmits an indirect transmission (see above) 
        if (m_macMaxFrameRetries > 0) {
          // retransmit: reinitialize CSMA-CA parameters
          done = FALSE;
          m_csmaParams.NB = 0;
          m_csmaParams.macMaxCsmaBackoffs = m_macMaxCSMABackoffs;
          m_csmaParams.macMaxBE = m_macMaxBE;
          m_csmaParams.BE = m_BE;
          m_macMaxFrameRetries -= 1;
        } else
          m_result = IEEE154_NO_ACK;
        break;
      case ERETRY:
        // frame was not transmitted, because the transaction does not
        // fit in the remaining CAP (in beacon-enabled PANs only)
        done = FALSE;
        break;
      default: 
        break;
    }
    if (COORD_ROLE && frame == m_bcastFrame){
      // always signal result of broadcast transmissions immediately 
      restoreFrameFromBackup();
      signalTxBroadcastDone(m_bcastFrame, (!done) ? IEEE154_CHANNEL_ACCESS_FAILURE : m_result);
      m_bcastFrame = NULL;
    } else if (done) {
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
    ieee154_cap_frame_backup_t backup = {m_currentFrame, m_csmaParams, m_transactionTime};
    call FrameBackup.setNow(&backup);
  }

  void restoreFrameFromBackup()
  {
    ieee154_cap_frame_backup_t *backup = call FrameRestore.getNow();
    if (backup != NULL){
      m_currentFrame = backup->frame;
      memcpy(&m_csmaParams, &backup->csmaParams, sizeof(ieee154_csma_t));
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

  event void Token.granted()
  {
    // the current frame should be transmitted using unslotted CSMA-CA
    dbgHistoryReset();
    call Debug.log(DEBUG_LEVEL_INFO, 6, 0,0,0);
    updateState();
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
