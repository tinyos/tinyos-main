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
 * $Revision: 1.7 $
 * $Date: 2009-05-14 13:20:35 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "TKN154_PHY.h"
#include "TKN154_MAC.h"


/** 
 * This module is responsible for the transmission/reception of DATA and
 * COMMAND frames in the CAP of beacon-enabled PANs. Its main tasks are
 * initialization of the parameters of the slotted CSMA-CA algorithm (NB, BE,
 * etc.), initiating retransmissions and dealing with broadcast transmissions.
 * It does not implement the actual CSMA-CA algorithm, because due to its
 * timing requirements the CSMA-CA algorithm is not part of the MAC
 * implementation but of the chip-specific radio driver.
 *
 * This module does slightly different things depending on whether it is the
 * CAP for an outgoing superframe (sfDirection = OUTGOING_SUPERFRAME), i.e. the
 * CAP from the perspective of a coordinator after it has transmitted its own
 * beacon; or for an incoming superframe (sfDirection = INCOMING_SUPERFRAME),
 * i.e.  the CAP from the perspective of a device after it has received a
 * beacon from its coordinator. For example, in the CAP a coordinator will
 * typically listen for incoming frames from the devices, and a device will
 * typically switch the radio off unless it has a frame to transmit.
 */

generic module DispatchSlottedCsmaP(uint8_t sfDirection)
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
    interface Alarm<TSymbolIEEE802154,uint32_t> as RxWaitAlarm;
    interface TransferableResource as RadioToken;
    interface ResourceRequested as RadioTokenRequested;
    interface SuperframeStructure; 
    interface GetNow<token_requested_t> as IsRadioTokenRequested;
    interface GetNow<bool> as IsRxEnableActive; 
    interface Get<ieee154_txframe_t*> as GetIndirectTxFrame; 
    interface Notify<bool> as RxEnableStateChange;
    interface GetNow<bool> as IsTrackingBeacons;
    interface Notify<const void*> as PIBUpdateMacRxOnWhenIdle;
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
  typedef enum {
    SWITCH_OFF,       
    WAIT_FOR_RXDONE,  
    WAIT_FOR_TXDONE,  
    DO_NOTHING,       
  } next_state_t; 

  typedef enum {
    INDIRECT_TX_ALARM,
    BROADCAST_ALARM,
    NO_ALARM,
  } rx_alarm_t;

  enum {
    COORD_ROLE = (sfDirection == OUTGOING_SUPERFRAME),
    DEVICE_ROLE = !COORD_ROLE,
    RADIO_CLIENT_CFP = COORD_ROLE ? RADIO_CLIENT_COORDCFP : RADIO_CLIENT_DEVICECFP,
  };

  /* state / frame management */
  norace bool m_lock;
  norace bool m_resume;
  norace ieee154_txframe_t *m_currentFrame;
  norace ieee154_txframe_t *m_bcastFrame;
  norace ieee154_txframe_t *m_lastFrame;
  norace uint16_t m_remainingBackoff;
  ieee154_macRxOnWhenIdle_t macRxOnWhenIdle;

  /* variables for the slotted CSMA-CA */
  norace ieee154_csma_t m_csma;
  norace ieee154_macMaxBE_t m_BE;
  norace ieee154_macMaxCSMABackoffs_t m_macMaxCSMABackoffs;
  norace ieee154_macMaxBE_t m_macMaxBE;
  norace ieee154_macMaxFrameRetries_t m_macMaxFrameRetries;
  norace ieee154_status_t m_txStatus;
  norace uint32_t m_transactionTime;
  norace bool m_indirectTxPending = FALSE;
  norace bool m_broadcastRxPending;
  norace ieee154_macMaxFrameTotalWaitTime_t m_macMaxFrameTotalWaitTime;

  /* function / task prototypes */
  void stopAllAlarms();
  next_state_t tryReceive();
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

#ifdef TKN154_DEBUG
  enum {
    HEADER_STR_LEN = 27,
    DBG_STR_SIZE = 250,
  };
  norace uint16_t m_dbgNumEntries;
  norace char m_dbgStr[HEADER_STR_LEN + DBG_STR_SIZE] = "updateState() transitions: ";
  void dbg_push_state(uint8_t state) {
    if (m_dbgNumEntries < DBG_STR_SIZE-3)
      m_dbgStr[HEADER_STR_LEN + m_dbgNumEntries++] = '0' + state; 
  }
  void dbg_flush_state() {
    m_dbgStr[HEADER_STR_LEN + m_dbgNumEntries++] = '\n'; 
    m_dbgStr[HEADER_STR_LEN + m_dbgNumEntries++] = 0; 
    dbg_serial("DispatchSlottedCsmaP",m_dbgStr);
    m_dbgNumEntries = 0;
  }
#else 
#define dbg_push_state(X)
#define dbg_flush_state()
#endif

  command error_t Reset.init()
  {
    if (m_currentFrame)
      signal FrameTx.transmitDone(m_currentFrame, IEEE154_TRANSACTION_OVERFLOW);
    if (m_lastFrame)
      signal FrameTx.transmitDone(m_lastFrame, IEEE154_TRANSACTION_OVERFLOW);
    if (m_bcastFrame)
      signalTxBroadcastDone(m_bcastFrame, IEEE154_TRANSACTION_OVERFLOW);
    m_currentFrame = m_lastFrame = m_bcastFrame = NULL;
    m_macMaxFrameTotalWaitTime = call MLME_GET.macMaxFrameTotalWaitTime();
    stopAllAlarms();
    return SUCCESS;
  }

  async event void RadioToken.transferredFrom(uint8_t fromClient)
  {
    // we got the token, i.e. CAP has just started
    uint32_t capDuration = (uint32_t) call SuperframeStructure.numCapSlots() * 
      (uint32_t) call SuperframeStructure.sfSlotDuration();
    uint16_t guardTime = call SuperframeStructure.guardTime();

    dbg_serial("DispatchSlottedCsmaP", "Got token, remaining CAP time: %lu\n", 
        call SuperframeStructure.sfStartTime() + capDuration - guardTime - call CapEndAlarm.getNow());
    if (DEVICE_ROLE && !call IsTrackingBeacons.getNow()) {
      // very rare case: 
      // this can only happen, if we're on a beacon-enabled PAN, not tracking beacons,   
      // and searched but didn't find a beacon for aBaseSuperframeDuration*(2n+1) symbols
      // we'd actually have to transmit the current frame using unslotted CSMA-CA        
      // but we don't have that functionality available... signal FAIL...                
      m_lastFrame = m_currentFrame;
      m_currentFrame = NULL;
      m_txStatus = IEEE154_NO_BEACON;
      post signalTxDoneTask();
      return;
    } else if (capDuration < guardTime) {
      // CAP is too short to do anything practical
      dbg_serial("DispatchSlottedCsmaP", "CAP too short!\n");
      call RadioToken.transferTo(RADIO_CLIENT_CFP);
      return;
    } else {
      capDuration -= guardTime;
      if (DEVICE_ROLE)
        m_broadcastRxPending = call SuperframeStructure.isBroadcastPending();
      else { 
        // COORD_ROLE
        if (m_bcastFrame != NULL) {
          // we have to transmit a broadcast frame immediately; this
          // may require to a backup of the previously active frame 
          // and a reinitializing the CSMA parameters -> will do it 
          // in task context and then continue
          m_lock = TRUE;
          post setupTxBroadcastTask(); 
          dbg_serial("DispatchSlottedCsmaP", "Preparing broadcast.\n");
        }
      }
      call CapEndAlarm.startAt(call SuperframeStructure.sfStartTime(), capDuration);
      if (call SuperframeStructure.battLifeExtDuration() > 0)
        call BLEAlarm.startAt(call SuperframeStructure.sfStartTime(), call SuperframeStructure.battLifeExtDuration());
    }
    updateState();
  }

  command ieee154_status_t FrameTx.transmit(ieee154_txframe_t *frame)
  {
    if (m_currentFrame != NULL) {
      // we've not finished transmitting the current frame yet
      dbg_serial("DispatchSlottedCsmaP", "Overflow\n");
      return IEEE154_TRANSACTION_OVERFLOW;
    } else {
      setCurrentFrame(frame);
      dbg("DispatchSlottedCsmaP", "New frame to transmit, DSN: %lu\n", (uint32_t) MHR(frame)[MHR_INDEX_SEQNO]);
      // a beacon must be found before transmitting in a beacon-enabled PAN
      if (DEVICE_ROLE && !call IsTrackingBeacons.getNow()) {
        call TrackSingleBeacon.start();
        dbg_serial("DispatchSlottedCsmaP", "Tracking single beacon now\n");
        // we'll receive the Token  after a beacon was found or after
        // aBaseSuperframeDuration*(2n+1) symbols if none was found  
      }
      updateState();
      return IEEE154_SUCCESS;
    }
  }

  task void setupTxBroadcastTask()
  {
    ieee154_macDSN_t tmp;
    ieee154_txframe_t *oldFrame = m_currentFrame;
    if (COORD_ROLE) {
      if (m_bcastFrame != NULL) {
        // broadcasts should be transmitted *immediately* after the beacon,  
        // which may interrupt a pending transmit operation from the previous
        // CAP; back up the last active frame configuration (may be none)    
        // and restore it after the broadcast frame has been transmitted;    
        // do this through interfaces and don't wire them for DEVICE_ROLE,   
        // so we don't waste the RAM of devices
        backupCurrentFrame();
        setCurrentFrame(m_bcastFrame);
        if (oldFrame) {
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
    m_csma.NB = 0;
    m_csma.macMaxCsmaBackoffs = m_macMaxCSMABackoffs = call MLME_GET.macMaxCSMABackoffs();
    m_csma.macMaxBE = m_macMaxBE = call MLME_GET.macMaxBE();
    m_csma.BE = call MLME_GET.macMinBE();
    if (call MLME_GET.macBattLifeExt() && m_csma.BE > 2)
      m_csma.BE = 2;
    m_BE = m_csma.BE;
    if (COORD_ROLE && call GetIndirectTxFrame.get() == frame)
      m_macMaxFrameRetries =  0; // this is an indirect transmissions (never retransmit)
    else
      m_macMaxFrameRetries =  call MLME_GET.macMaxFrameRetries();
    m_transactionTime = IEEE154_SHR_DURATION + 
      (frame->headerLen + frame->payloadLen + 2) * IEEE154_SYMBOLS_PER_OCTET; // extra 2 for CRC
    if (frame->header->mhr[MHR_INDEX_FC1] & FC1_ACK_REQUEST)
      m_transactionTime += (IEEE154_aTurnaroundTime + IEEE154_aUnitBackoffPeriod + 
          11 * IEEE154_SYMBOLS_PER_OCTET); // 11 byte for the ACK PPDU
    // if (frame->headerLen + frame->payloadLen > IEEE154_aMaxSIFSFrameSize) 
    //  m_transactionTime += call MLME_GET.macMinLIFSPeriod(); 
    // else 
    //  m_transactionTime += call MLME_GET.macMinSIFSPeriod(); 
    m_macMaxFrameTotalWaitTime = call MLME_GET.macMaxFrameTotalWaitTime();
    m_currentFrame = frame;
  }
 
  void stopAllAlarms()
  {
    call CapEndAlarm.stop();
    if (DEVICE_ROLE)
      call RxWaitAlarm.stop();
    call BLEAlarm.stop();
  }

  /** 
   * The updateState() function is called whenever something happened that
   * might require a state transition; it implements a lock mechanism (m_lock)
   * to prevent race conditions. Whenever the lock is set a "done"-event (from
   * the SlottedCsmaCa/RadioRx/RadioOff interface) is pending and will "soon"
   * unset the lock (and then updateState() will called again).  The
   * updateState() function decides about the next state by checking a list of
   * possible current states ordered by priority, e.g. it first always checks
   * whether the CAP is still active. Calling this function more than necessary
   * can do no harm.
   */ 

  void updateState()
  {
    uint32_t capDuration; 
    next_state_t next;
    atomic {
      // long atomics are bad... but in this block, once the/ current state has
      // been determined only one branch will/ be taken (there are no loops)
      if (m_lock || !call RadioToken.isOwner())
        return;
      m_lock = TRUE; // lock
      capDuration = (uint32_t) call SuperframeStructure.numCapSlots() * 
               (uint32_t) call SuperframeStructure.sfSlotDuration();

      // Check 1: has the CAP finished?
      if ((COORD_ROLE || call IsTrackingBeacons.getNow()) && 
          (call TimeCalc.hasExpired(call SuperframeStructure.sfStartTime(), 
                capDuration - call SuperframeStructure.guardTime()) ||
          !call CapEndAlarm.isRunning())) {
        dbg_push_state(1);
        if (call RadioOff.isOff()) {
          stopAllAlarms();  // may still fire, but is locked through isOwner()
          if (DEVICE_ROLE && m_indirectTxPending)
            signal RxWaitAlarm.fired();
          m_broadcastRxPending = FALSE;
          if (COORD_ROLE && m_bcastFrame) {
            // didn't manage to transmit a broadcast
            restoreFrameFromBackup();
            signalTxBroadcastDone(m_bcastFrame, IEEE154_CHANNEL_ACCESS_FAILURE);
            m_bcastFrame = NULL;
          }
          m_lock = FALSE; // unlock
          dbg_flush_state();
          dbg_serial("DispatchSlottedCsmaP", "Handing over to CFP.\n");
          call RadioToken.transferTo(RADIO_CLIENT_CFP);
          return;
        } else 
          next = SWITCH_OFF;
      }

      // Check 2: should a broadcast frame be received/transmitted
      // immediately at the start of CAP?
      else if (DEVICE_ROLE && m_broadcastRxPending) {
        // receive a broadcast from coordinator
        dbg_push_state(2);
        next = tryReceive();
      } else if (COORD_ROLE && m_bcastFrame) {
        dbg_push_state(2);
        next = tryTransmit();
      }

      // Check 3: was an indirect transmission successfully started 
      // and are we now waiting for a frame from the coordinator?
      else if (DEVICE_ROLE && m_indirectTxPending) {
        dbg_push_state(3);
        next = tryReceive();
      }

      // Check 4: is some other operation (like MLME-SCAN or MLME-RESET) pending? 
      else if (call IsRadioTokenRequested.getNow()) {
        dbg_push_state(4);
        if (call RadioOff.isOff()) {
          stopAllAlarms();  // may still fire, but is locked through isOwner()
          // nothing more to do... just release the Token
          m_lock = FALSE; // unlock
          dbg_serial("DispatchSlottedCsmaP", "Token requested: Handing over to CFP.\n");
          call RadioToken.release();
          return;
        } else 
          next = SWITCH_OFF;
      }

      // Check 5: is battery life extension (BLE) active and 
      // has the BLE period expired?
      else if (call SuperframeStructure.battLifeExtDuration() > 0 &&
          call TimeCalc.hasExpired(call SuperframeStructure.sfStartTime(), 
            call SuperframeStructure.battLifeExtDuration()) &&
          !call IsRxEnableActive.getNow() && !macRxOnWhenIdle) {
        dbg_push_state(5);
        next = trySwitchOff();
      }

      // Check 6: is there a frame ready to transmit?
      else if (m_currentFrame != NULL) {
        dbg_push_state(6);
        next = tryTransmit();
      }

      // Check 7: should we be in receive mode?
      else if (COORD_ROLE || call IsRxEnableActive.getNow() || macRxOnWhenIdle) {
        dbg_push_state(7);
        next = tryReceive();
        if (next == DO_NOTHING) {
          // if there was an active MLME_RX_ENABLE.request then we'll
          // inform the next higher layer that radio is now in Rx mode
          post wasRxEnabledTask();
        }
      }

      // Check 8: just make sure the radio is switched off  
      else {
        dbg_push_state(8);
        next = trySwitchOff();
      }

      // if there is nothing to do, then we must clear the lock
      if (next == DO_NOTHING)
        m_lock = FALSE;
    } // atomic

    // put next state in operation (possibly keeping the lock)
    switch (next)
    {
      case SWITCH_OFF: ASSERT(call RadioOff.off() == SUCCESS); break;
      case WAIT_FOR_RXDONE: break;
      case WAIT_FOR_TXDONE: break;
      case DO_NOTHING: break;
    }
  }
  
  next_state_t tryTransmit()
  {
    // tries to transmit m_currentFrame
    uint32_t capDuration = (uint32_t) call SuperframeStructure.numCapSlots() * 
      (uint32_t) call SuperframeStructure.sfSlotDuration();
    next_state_t next;

    if (!call RadioOff.isOff())
      next = SWITCH_OFF;
    else {
      uint32_t dtMax = capDuration - call SuperframeStructure.guardTime() - m_transactionTime;
      // round to backoff boundary
      dtMax = dtMax + (IEEE154_aUnitBackoffPeriod - (dtMax % IEEE154_aUnitBackoffPeriod));
      if (dtMax > capDuration)
        dtMax = 0;
      if (call SuperframeStructure.battLifeExtDuration() > 0) {
        // battery life extension
        uint16_t bleLen = call SuperframeStructure.battLifeExtDuration();
        if (bleLen < dtMax)
          dtMax = bleLen;
      }
      if (call TimeCalc.hasExpired(call SuperframeStructure.sfStartTime(), dtMax))
        next = DO_NOTHING; // frame doesn't fit in the remaining CAP
      else {
        error_t res;
        res = call SlottedCsmaCa.transmit(m_currentFrame, &m_csma, 
                   call SuperframeStructure.sfStartTimeRef(), dtMax, m_resume, m_remainingBackoff);
        dbg("DispatchSlottedCsmaP", "SlottedCsmaCa.transmit() -> %lu\n", (uint32_t) res);
        next = WAIT_FOR_TXDONE; // this will NOT clear the lock
      }
    }
    return next;
  }

  next_state_t tryReceive()
  {
    next_state_t next;
    if (call RadioRx.isReceiving())
      next = DO_NOTHING;
    else if (!call RadioOff.isOff())
      next = SWITCH_OFF;
    else {
      call RadioRx.enableRx(0, 0);
      next = WAIT_FOR_RXDONE;
    }
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

  async event void RadioOff.offDone() 
  { 
    m_lock = FALSE; 
    updateState();
  }

  async event void RadioRx.enableRxDone() 
  { 
    if (DEVICE_ROLE && (m_indirectTxPending || m_broadcastRxPending))
      call RxWaitAlarm.start(m_macMaxFrameTotalWaitTime);
    m_lock = FALSE; 
    updateState();
  }

  async event void CapEndAlarm.fired() { 
    dbg_serial("DispatchSlottedCsmaP", "CapEndAlarm.fired()\n");
    updateState();
  }
  async event void BLEAlarm.fired() { updateState();}
  event void RxEnableStateChange.notify(bool whatever) { updateState();}
  event void PIBUpdateMacRxOnWhenIdle.notify( const void* val ) {
    atomic macRxOnWhenIdle = *((ieee154_macRxOnWhenIdle_t*) val);
    updateState();
  }

  async event void RxWaitAlarm.fired() 
  { 
    if (DEVICE_ROLE && (m_indirectTxPending || m_broadcastRxPending))
      atomic {
        if (m_indirectTxPending) {
          m_indirectTxPending = FALSE; 
          post signalTxDoneTask(); 
        } else if (m_broadcastRxPending) {
          m_broadcastRxPending = FALSE;
          updateState();
        }
      }
  }

  async event void SlottedCsmaCa.transmitDone(ieee154_txframe_t *frame, ieee154_csma_t *csma, 
      bool ackPendingFlag,  uint16_t remainingBackoff, error_t result)
  {
    bool done = TRUE;
    dbg("DispatchSlottedCsmaP", "SlottedCsmaCa.transmitDone() -> %lu\n", (uint32_t) result);
    m_resume = FALSE;

    switch (result)
    {
      case SUCCESS:
        // frame was successfully transmitted, if ACK was requested
        // then a matching ACK was successfully received as well   
        m_txStatus = IEEE154_SUCCESS;
        if (DEVICE_ROLE && frame->payload[0] == CMD_FRAME_DATA_REQUEST &&
            ((frame->header->mhr[MHR_INDEX_FC1]) & FC1_FRAMETYPE_MASK) == FC1_FRAMETYPE_CMD) {
          // this was a data request frame
          m_txStatus = IEEE154_NO_DATA; // pessimistic 
          if (ackPendingFlag) {
            // the coordinator has data for us; switch to Rx 
            // to complete the indirect transmission         
            m_indirectTxPending = TRUE;
            m_lastFrame = m_currentFrame;
            m_currentFrame = NULL;
            ASSERT(call RadioRx.enableRx(0, 0) == SUCCESS);
            return;
          }
        }
        break;
      case FAIL:
        // The CSMA-CA algorithm failed: the frame was not transmitted,
        // because channel was never idle                              
        m_txStatus = IEEE154_CHANNEL_ACCESS_FAILURE;
        break;
      case ENOACK:
        // frame was transmitted, but we didn't receive an ACK (although
        // we requested an one). note: coordinator never retransmits an 
        // indirect transmission (see above) 
        if (m_macMaxFrameRetries > 0) {
          // retransmit: reinitialize CSMA-CA parameters
          done = FALSE;
          m_csma.NB = 0;
          m_csma.macMaxCsmaBackoffs = m_macMaxCSMABackoffs;
          m_csma.macMaxBE = m_macMaxBE;
          m_csma.BE = m_BE;
          m_macMaxFrameRetries -= 1;
        } else
          m_txStatus = IEEE154_NO_ACK;
        break;
      case EINVAL: // DEBUG!!!
        dbg_serial("DispatchSlottedCsmaP", "EINVAL returned by transmitDone()!\n");
        // fall through
      case ERETRY:
        // frame was not transmitted, because the transaction does not
        // fit in the remaining CAP (in beacon-enabled PANs only)
        dbg_serial("DispatchSlottedCsmaP", "Transaction didn't fit, current BE: %lu\n", (uint32_t) csma->BE);
        m_resume = TRUE;
        m_remainingBackoff = remainingBackoff;
        done = FALSE;
        m_lock = FALSE; // debug! problem: if CAP endalarm has fired it's a deadlock!
        if (!call CapEndAlarm.isRunning())
          updateState();
        return;
        break;
      default: 
        ASSERT(0);
        break;
    }

    if (COORD_ROLE && frame == m_bcastFrame) {
      // always signal result of broadcast transmissions immediately 
      restoreFrameFromBackup();
      signalTxBroadcastDone(m_bcastFrame, (!done) ? IEEE154_CHANNEL_ACCESS_FAILURE : m_txStatus);
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
    ieee154_status_t status = m_txStatus;
    m_indirectTxPending = FALSE;
    m_lastFrame = NULL; // only now can the next transmission can begin 
    if (lastFrame) {
      dbg("DispatchSlottedCsmaP", "Transmit done, DSN: %lu, result: 0x%lx\n", 
          (uint32_t) MHR(lastFrame)[MHR_INDEX_SEQNO], (uint32_t) status);
      signal FrameTx.transmitDone(lastFrame, status);
    }
    updateState();
  }

  event message_t* RadioRx.received(message_t* frame, const ieee154_timestamp_t *timestamp)
  {
    // received a frame -> find out frame type and
    // signal it to responsible client component
    uint8_t *payload = (uint8_t *) frame->data;
    uint8_t *mhr = MHR(frame);
    uint8_t frameType = mhr[MHR_INDEX_FC1] & FC1_FRAMETYPE_MASK;

    if (frameType == FC1_FRAMETYPE_CMD)
      frameType += payload[0];
    dbg("DispatchSlottedCsmaP", "Received frame, DSN: %lu, type: 0x%lu\n", 
        (uint32_t) mhr[MHR_INDEX_SEQNO], (uint32_t) frameType);
    atomic {
      if (DEVICE_ROLE && (m_indirectTxPending || m_broadcastRxPending)) {
        message_t* frameBuf;
        call RxWaitAlarm.stop();
        // TODO: check the following: 
        // is this frame from our coordinator? hmm... we cannot say/ with
        // certainty, because we might only know either the  coordinator
        // extended or short address (and the frame could/ have been sent
        // with the other addressing mode) ??
        m_txStatus = IEEE154_SUCCESS;
        if (m_indirectTxPending)
          frameBuf = signal FrameExtracted.received[frameType](frame, m_lastFrame); // indirect tx from coord
        else
          frameBuf = signal FrameRx.received[frameType](frame); // broadcast from coordinator
        signal RxWaitAlarm.fired();
        return frameBuf;
      } else
        return signal FrameRx.received[frameType](frame);
    }
  }

  void backupCurrentFrame()
  {
    ieee154_cap_frame_backup_t backup = {m_currentFrame, m_csma, m_transactionTime};
    call FrameBackup.setNow(&backup);
  }

  void restoreFrameFromBackup()
  {
    ieee154_cap_frame_backup_t *backup = call FrameRestore.getNow();
    if (backup != NULL) {
      m_currentFrame = backup->frame;
      memcpy(&m_csma, &backup->csma, sizeof(ieee154_csma_t));
      m_transactionTime = backup->transactionTime;
    }
  }

  async command ieee154_status_t BroadcastTx.transmitNow(ieee154_txframe_t *frame) 
  {
    // if this command is called then it is (MUST be) called only just before
    // the token is transferred to this component and it is then called
    // only once per CAP (max. one broadcast is allowed after a beacon
    // transmission)
    atomic {
      if (!call RadioToken.isOwner() && m_bcastFrame == NULL) {
        m_bcastFrame = frame;
        return IEEE154_SUCCESS;
      } else {
        ASSERT(0);
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

  event void RadioToken.granted()
  {
    ASSERT(0); // should never happen
  }

  default event void FrameTx.transmitDone(ieee154_txframe_t *data, ieee154_status_t status) {}
  default event message_t* FrameRx.received[uint8_t client](message_t* data) {return data;}
  default async command bool IsRxEnableActive.getNow() {return FALSE;}

  default async command void RxWaitAlarm.start(uint32_t dt) {ASSERT(0);}
  default async command void RxWaitAlarm.stop() {ASSERT(0);}
  default async command void RxWaitAlarm.startAt(uint32_t t0, uint32_t dt) {ASSERT(0);}
  
  default async command bool SuperframeStructure.isBroadcastPending() { return FALSE;}
  default async event void BroadcastTx.transmitNowDone(ieee154_txframe_t *frame, ieee154_status_t status) {}
  default event message_t* FrameExtracted.received[uint8_t client](message_t* msg, ieee154_txframe_t *txFrame) {return msg;}
  default async command error_t FrameBackup.setNow(ieee154_cap_frame_backup_t* val) {return FAIL;}
  default async command ieee154_cap_frame_backup_t* FrameRestore.getNow() {return NULL;}
  default command error_t TrackSingleBeacon.start() {return FAIL;}

  command error_t WasRxEnabled.enable() {return FAIL;}
  command error_t WasRxEnabled.disable() {return FAIL;}
  async event void RadioTokenRequested.requested(){ updateState(); }
  async event void RadioTokenRequested.immediateRequested(){ updateState(); }
}
