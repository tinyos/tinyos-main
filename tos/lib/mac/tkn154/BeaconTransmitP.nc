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
 * $Revision: 1.8 $
 * $Date: 2009-03-24 12:56:46 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 * This module is responsible for periodic beacon transmission in a 
 * beacon-enabled PAN.
 */

#include "TKN154_MAC.h"
#include "TKN154_PHY.h"
module BeaconTransmitP
{
  provides
  {
    interface Init as Reset;
    interface MLME_START;
    interface IEEE154TxBeaconPayload;
    interface SuperframeStructure as OutgoingSF;
    interface GetNow<bool> as IsSendingBeacons;
  } uses {
    interface Notify<bool> as GtsSpecUpdated;
    interface Notify<bool> as PendingAddrSpecUpdated;
    interface Notify<const void*> as PIBUpdate[uint8_t attributeID];
    interface Alarm<TSymbolIEEE802154,uint32_t> as BeaconSendAlarm;
    interface Timer<TSymbolIEEE802154> as BeaconPayloadUpdateTimer;
    interface RadioOff;
    interface RadioTx as BeaconTx;
    interface MLME_GET;
    interface MLME_SET;
    interface TransferableResource as RadioToken;
    interface FrameTx as RealignmentBeaconEnabledTx;
    interface FrameTx as RealignmentNonBeaconEnabledTx;
    interface FrameRx as BeaconRequestRx;
    interface WriteBeaconField as GtsInfoWrite;
    interface WriteBeaconField as PendingAddrWrite;
    interface FrameUtility;
    interface GetNow<bool> as IsTrackingBeacons;
    interface SuperframeStructure as IncomingSF;
    interface Set<ieee154_macSuperframeOrder_t> as SetMacSuperframeOrder;
    interface Set<ieee154_macBeaconTxTime_t> as SetMacBeaconTxTime;
    interface Set<ieee154_macPanCoordinator_t> as SetMacPanCoordinator;
    interface GetSet<ieee154_txframe_t*> as GetSetRealignmentFrame;
    interface GetNow<bool> as IsBroadcastReady; 
    interface TimeCalc;
    interface Leds;
  }
}
implementation
{
  /* state variables */
  norace uint8_t m_requestBitmap;
  norace uint8_t m_txState;
  uint8_t m_payloadState;
  norace bool m_txOneBeaconImmediately;

  /* variables that describe the current superframe configuration */
  norace uint32_t m_startTime;
  norace uint8_t m_beaconOrder;
  norace uint8_t m_superframeOrder;
  norace uint32_t m_beaconInterval;
  norace uint32_t m_previousBeaconInterval;
  norace uint32_t m_dt;
  norace uint8_t m_bsn;
  norace uint32_t m_lastBeaconTxTime;
  norace ieee154_timestamp_t m_lastBeaconTxRefTime;
  norace ieee154_macBattLifeExtPeriods_t m_battLifeExtPeriods;

  /* variables that describe the latest superframe */
  norace uint32_t m_sfSlotDuration;
  norace bool m_framePendingBit;
  norace uint8_t m_numCapSlots;
  norace uint8_t m_numGtsSlots;
  norace uint16_t m_battLifeExtDuration;
  uint8_t m_gtsField[1+1+3*7];

  /* variables that describe the beacon (payload) */
  norace ieee154_txframe_t m_beaconFrame;
  ieee154_header_t m_header; 
  ieee154_metadata_t m_metadata; 
  void *m_updateBeaconPayload;
  uint8_t m_updateBeaconOffset;
  uint8_t m_updateBeaconLength;
  uint8_t m_beaconPayloadLen;
  uint8_t m_pendingAddrLen;
  uint8_t m_pendingGtsLen;

  /* buffers for the parameters of the MLME-START request */
  uint16_t m_updatePANId;
  uint8_t m_updateLogicalChannel;
  uint32_t m_updateStartTime;
  norace uint8_t m_updateBeaconOrder;
  uint8_t m_updateSuperframeOrder;
  bool m_updatePANCoordinator;
  bool m_updateBatteryLifeExtension;

  enum {
    MAX_BEACON_PAYLOAD_SIZE =  IEEE154_aMaxBeaconOverhead + IEEE154_aMaxBeaconPayloadLength,

    REQUEST_UPDATE_SF = 0x01,
    REQUEST_REALIGNMENT = 0x02,
    REQUEST_CONFIRM_PENDING = 0x04,
    REQUEST_REALIGNMENT_DONE_PENDING = 0x08,

    MODIFIED_SF_SPEC = 0x01,
    MODIFIED_GTS_FIELD = 0x02,
    MODIFIED_PENDING_ADDR_FIELD = 0x04,
    MODIFIED_SPECS_MASK = 0x0F,

    MODIFIED_BEACON_PAYLOAD = 0x10,
    MODIFIED_BEACON_PAYLOAD_NEW = 0x20,
    MODIFIED_BEACON_PAYLOAD_MASK = 0xF0,

    S_TX_IDLE = 0,
    S_TX_LOCKED = 1,
    S_TX_WAITING = 2,
  };
  uint8_t m_payload[MAX_BEACON_PAYLOAD_SIZE]; 

  /* function/task prototypes */
  task void txDoneTask();
  task void signalStartConfirmSuccessTask();
  void nextRound();
  void prepareBeaconTransmission();
  void continueStartRequest();
  void finishRealignment(ieee154_txframe_t *frame, ieee154_status_t status);

  command error_t Reset.init()
  {
    // reset this component, will only be called while we're not owning the token
    // TODO: check to signal MLME_START.confirm ?
    m_beaconFrame.header = &m_header;
    m_beaconFrame.headerLen = 0;
    m_beaconFrame.payload = m_payload;
    m_beaconFrame.payloadLen = 0;
    m_beaconFrame.metadata = &m_metadata;
    m_updateBeaconPayload = NULL;
    m_updateBeaconLength = 0;
    m_requestBitmap = m_payloadState = m_txState = 0;
    m_beaconPayloadLen = m_pendingAddrLen = m_pendingGtsLen = 0;
    m_gtsField[0] = 0;
    m_numCapSlots = 0;
    m_numGtsSlots = 0;
    m_beaconOrder = 15;
    call BeaconPayloadUpdateTimer.stop();
    call BeaconSendAlarm.stop();
    return SUCCESS;
  }

  /* ----------------------- MLME-START ----------------------- */
  /* "The MLME-START.request primitive allows the PAN coordinator to initiate a
   * new PAN or to begin using a new superframe configuration. This primitive may
   * also be used by a device already associated with an existing PAN to begin
   * using a new superframe configuration." (IEEE 802.15.4-2006 Sect. 7.1.14.1)
   **/

  command ieee154_status_t MLME_START.request  (
                          uint16_t panID,
                          uint8_t logicalChannel,
                          uint8_t channelPage,
                          uint32_t startTime,
                          uint8_t beaconOrder,
                          uint8_t superframeOrder,
                          bool panCoordinator,
                          bool batteryLifeExtension,
                          bool coordRealignment,
                          ieee154_security_t *coordRealignSecurity,
                          ieee154_security_t *beaconSecurity)
  {
    ieee154_status_t status = IEEE154_SUCCESS;
    ieee154_macShortAddress_t shortAddress = call MLME_GET.macShortAddress();

    // check parameters
    if ((coordRealignSecurity && coordRealignSecurity->SecurityLevel) ||
        (beaconSecurity && beaconSecurity->SecurityLevel))
      status = IEEE154_UNSUPPORTED_SECURITY;
    else if (shortAddress == 0xFFFF) 
      status = IEEE154_NO_SHORT_ADDRESS;
    else if (logicalChannel > 26 || beaconOrder > 15 || 
        (channelPage != IEEE154_SUPPORTED_CHANNELPAGE) ||
        !(IEEE154_SUPPORTED_CHANNELS & ((uint32_t) 1 << logicalChannel)) ||
        (superframeOrder > beaconOrder))
      status =  IEEE154_INVALID_PARAMETER;
    else if (startTime && !call IsTrackingBeacons.getNow())
      status = IEEE154_TRACKING_OFF;
    else if (startTime && 0xFF000000)
      status = IEEE154_INVALID_PARAMETER;
    else if (m_requestBitmap & (REQUEST_CONFIRM_PENDING | REQUEST_UPDATE_SF))
      status = IEEE154_TRANSACTION_OVERFLOW;
    else {

      // New configuration *will* be put in operation, we'll buffer
      // the parameters now, and continue once we get the token.
      if (panCoordinator)
        startTime = 0;        // start immediately
      if (beaconOrder == 15)
        superframeOrder = 15; // beaconless PAN 
      m_updatePANId = panID;
      m_updateLogicalChannel = logicalChannel;
      m_updateStartTime = startTime;
      m_updateBeaconOrder = beaconOrder; 
      m_updateSuperframeOrder = superframeOrder;
      m_updatePANCoordinator = panCoordinator;
      m_updateBatteryLifeExtension = batteryLifeExtension;   
      m_requestBitmap = (REQUEST_CONFIRM_PENDING | REQUEST_UPDATE_SF); // lock

      if (coordRealignment)
        m_requestBitmap |= REQUEST_REALIGNMENT;
      if (m_beaconOrder == 15) {
        // We're not already transmitting beacons, i.e. we have to request the token
        // (otherwise we'd get the token "automatically" for the next scheduled beacon).
        call RadioToken.request();
      }
      // We'll continue the MLME_START operation in continueStartRequest() once we have the token
    }
    dbg_serial("BeaconTransmitP", "MLME_START.request -> result: %lu\n", (uint32_t) status);
    return status;
  }

  void continueStartRequest()
  {
    uint8_t offset;
    ieee154_macShortAddress_t shortAddress;
    bool isShortAddr;

    // (1) coord realignment?
    if (m_requestBitmap & REQUEST_REALIGNMENT) {
      ieee154_txframe_t *realignmentFrame = call GetSetRealignmentFrame.get();
      m_requestBitmap &= ~REQUEST_REALIGNMENT;
      if (realignmentFrame == NULL) {
        // allocation failed!
        m_requestBitmap = 0;
        signal MLME_START.confirm(IEEE154_TRANSACTION_OVERFLOW);
        return;
      }
      // set the payload portion of the realignmentFrame
      // (the header fields are already set correctly)
      realignmentFrame->payload[0] = CMD_FRAME_COORDINATOR_REALIGNMENT;
      *((nxle_uint16_t*) &realignmentFrame->payload[1]) = m_updatePANId;
      *((nxle_uint16_t*) &realignmentFrame->payload[3]) = call MLME_GET.macShortAddress();
      realignmentFrame->payload[5] = m_updateLogicalChannel;
      *((nxle_uint16_t*) &realignmentFrame->payload[6]) = 0xFFFF;
      realignmentFrame->payloadLen = 8;
      
      if (m_beaconOrder < 15) {
        // we're already transmitting beacons; the realignment frame
        // must be sent (broadcast) after the next beacon
        if (call RealignmentBeaconEnabledTx.transmit(realignmentFrame) != IEEE154_SUCCESS) {
          m_requestBitmap = 0;
          call GetSetRealignmentFrame.set(realignmentFrame);
          signal MLME_START.confirm(IEEE154_TRANSACTION_OVERFLOW);
        } else {
          // The realignment frame will be transmitted immediately after 
          // the next beacon - the result will be signalled in 
          // RealignmentBeaconEnabledTx.transmitDone(). Only then the superframe
          // structure is updated and MLME_START.confirm signalled.
          m_requestBitmap |= REQUEST_REALIGNMENT_DONE_PENDING; // lock
        }
      } else {
        // send realignment frame in unslotted csma-ca now
        if (call RealignmentNonBeaconEnabledTx.transmit(realignmentFrame) != IEEE154_SUCCESS) {
          m_requestBitmap = 0;
          call GetSetRealignmentFrame.set(realignmentFrame);
          signal MLME_START.confirm(IEEE154_TRANSACTION_OVERFLOW);
        } else {
          // A realignment frame will be transmitted now, the result will 
          // be signalled in RealignmentNonBeaconEnabledTx.transmitDone(). Only 
          // then the superframe structure is updated and MLME_START.confirm 
          // signalled.
          m_requestBitmap |= REQUEST_REALIGNMENT_DONE_PENDING; // lock
        }
      }
      return; 
    }

    // (2) update internal state
    m_startTime = m_updateStartTime;
    m_txOneBeaconImmediately = FALSE;
    m_previousBeaconInterval = 0;
    if (m_startTime) {
      memcpy(&m_lastBeaconTxRefTime, call IncomingSF.sfStartTimeRef(), sizeof(ieee154_timestamp_t));
      m_lastBeaconTxTime = call IncomingSF.sfStartTime();
    } else {
      // no StartTime defined by next higher layer - but
      // if a realignment frame was transmitted, the next
      // beacon tx time must take the old BI into consideration
      if (m_requestBitmap & REQUEST_REALIGNMENT_DONE_PENDING)
        m_previousBeaconInterval = m_beaconInterval;
      else
        m_txOneBeaconImmediately = TRUE;
    }
    m_beaconOrder = m_updateBeaconOrder; 
    m_superframeOrder = m_updateSuperframeOrder;
    if (m_beaconOrder < 15) {
      m_beaconInterval = ((uint32_t) 1 << m_updateBeaconOrder) * IEEE154_aBaseSuperframeDuration;
    } else {
      m_beaconInterval = 0;
    }
    m_dt = m_beaconInterval;
    m_txState = S_TX_IDLE;
    m_bsn = call MLME_GET.macBSN()+1;
    m_battLifeExtPeriods = call MLME_GET.macBattLifeExtPeriods();

    // (3) update PIB
    call MLME_SET.macBeaconOrder(m_beaconOrder);
    call SetMacSuperframeOrder.set(m_superframeOrder);
    call MLME_SET.macPANId(m_updatePANId);
    call MLME_SET.phyCurrentChannel(m_updateLogicalChannel);
    if (m_beaconOrder < 15)
      call MLME_SET.macBattLifeExt(m_updateBatteryLifeExtension);
    call SetMacPanCoordinator.set(m_updatePANCoordinator);

    // (4) assemble beacon header and payload
    shortAddress = call MLME_GET.macShortAddress();
    isShortAddr = (shortAddress != 0xFFFE);
    m_beaconFrame.header->mhr[MHR_INDEX_FC1] = FC1_FRAMETYPE_BEACON;
    m_beaconFrame.header->mhr[MHR_INDEX_FC2] = isShortAddr ? FC2_SRC_MODE_SHORT : FC2_SRC_MODE_EXTENDED;
    offset = MHR_INDEX_ADDRESS;
    *((nxle_uint16_t*) &m_beaconFrame.header->mhr[offset]) = m_updatePANId;
    offset += sizeof(ieee154_macPANId_t);
    if (isShortAddr) {
      *((nxle_uint16_t*) &m_beaconFrame.header->mhr[offset]) = shortAddress;
      offset += sizeof(ieee154_macShortAddress_t);
    } else {
      call FrameUtility.copyLocalExtendedAddressLE(&m_beaconFrame.header->mhr[offset]);
      offset += 8;
    }
    m_beaconFrame.headerLen = offset;
    m_payloadState |= MODIFIED_SPECS_MASK;    // update beacon payload
    signal BeaconPayloadUpdateTimer.fired();  // assemble initial beacon payload

    if (m_beaconOrder < 15) {
      // beacon-enabled PAN, signal confirm after next 
      // beacon has been transmitted (see MSC, Fig. 38)
      m_requestBitmap = REQUEST_CONFIRM_PENDING;
    } else {
      // beaconless PAN, we're done
      m_requestBitmap = 0;
      signal MLME_START.confirm(IEEE154_SUCCESS);
    }
  }

  task void signalGrantedTask()
  {
    signal RadioToken.granted();
  }

  event void RadioToken.granted()
  {
    dbg_serial("BeaconSynchronizeP","Token granted.\n");
    if (m_requestBitmap & REQUEST_REALIGNMENT_DONE_PENDING) {
      // very unlikely: we have not yet received a done()
      // event after sending out a realignment frame 
      dbg_serial("BeaconTransmitP", "Realignment pending (request: %lu) !\n", (uint32_t) m_requestBitmap);
      post signalGrantedTask(); // spin
      return;
    } else if (m_requestBitmap & REQUEST_UPDATE_SF) {
      dbg_serial("BeaconTransmitP","Putting new superframe spec into operation\n"); 
      m_requestBitmap &= ~REQUEST_UPDATE_SF;
      continueStartRequest();
    }
    nextRound();
  }

  void nextRound()
  {
    if (call RadioOff.isOff())
      prepareBeaconTransmission();
    else
      ASSERT(call RadioOff.off() == SUCCESS); // will continue in prepareBeaconTransmission()
  }

  async event void RadioToken.transferredFrom(uint8_t fromClientID)
  {
    dbg_serial("BeaconSynchronizeP","Token transferred, will Tx beacon in %lu\n",
        (uint32_t) ((m_lastBeaconTxTime + m_dt) - call BeaconSendAlarm.getNow())); 
    if (m_requestBitmap & (REQUEST_REALIGNMENT_DONE_PENDING | REQUEST_UPDATE_SF))
      post signalGrantedTask(); // need to be in sync context
    else
      nextRound();
  }  

  async event void RadioOff.offDone()
  {
    prepareBeaconTransmission();
  }

  void prepareBeaconTransmission()
  {
    if (m_txState == S_TX_LOCKED) {
      // have not had time to finish processing the last sent beacon
      dbg_serial("BeaconTransmitP", "Token was returned too fast!\n");
      post signalGrantedTask();
    } else if (m_beaconOrder == 15) {
      // we're not sending any beacons!?
      dbg_serial("BeaconTransmitP", "Stop sending beacons.\n");
      call RadioToken.release();
    } else {
      // get ready for next beacon transmission
      atomic {
        uint32_t delay = IEEE154_RADIO_TX_DELAY; 
        m_txState = S_TX_WAITING;
        if (m_txOneBeaconImmediately) {
          // transmit the beacon now
          dbg_serial("BeaconTransmitP", "Sending a beacon immediately.\n");
          signal BeaconSendAlarm.fired();
          return;
        } else if (m_startTime != 0) {
          // a new sf spec was put into operation, with a user-defined StartTime    
          // here m_lastBeaconTxTime is actually the last time a beacon was received

          dbg_serial("BeaconTransmitP", "First beacon to be sent at %lu.\n", m_startTime);
          m_dt = m_startTime;
          m_startTime = 0;
        } else if (m_previousBeaconInterval != 0) {
          // a new sf spec was put into operation, after a realignment frame 
          // broadcast; the next beacon time should still be calculated using the
          // old BI (one last time)

          dbg_serial("BeaconTransmitP", "Sending beacon after realignment dt=%lu.\n", m_previousBeaconInterval);
          m_dt = m_previousBeaconInterval;
          m_previousBeaconInterval = 0;
          if (m_requestBitmap & REQUEST_CONFIRM_PENDING) {
            // only now the next higher layer is to be informed 
            m_requestBitmap &= ~REQUEST_CONFIRM_PENDING;
            post signalStartConfirmSuccessTask();
          }
        }

        // The next beacon should be transmitted at time m_lastBeaconTxTime + m_dt, where m_dt
        // is typically the beacon interval. First we check if we're still in time.
        while (call TimeCalc.hasExpired(m_lastBeaconTxTime, m_dt)) { 
          // too late, we need to skip a beacon!
          dbg_serial("BeaconTransmitP", "Skipping a beacon: scheduled=%lu, now=%lu.\n", 
              (uint32_t) m_lastBeaconTxTime + m_dt, (uint32_t) call BeaconSendAlarm.getNow());
          m_dt += m_beaconInterval;
        }
        if (!call TimeCalc.hasExpired(m_lastBeaconTxTime - delay, m_dt)) {
          // don't load the beacon frame in the radio just yet - rather set a timer and
          // give the next higher layer the chance to modify the beacon payload 
          call BeaconSendAlarm.startAt(m_lastBeaconTxTime - delay, m_dt);
        } else
          signal BeaconSendAlarm.fired();
      }
    }
  }

  task void signalStartConfirmSuccessTask()
  {
    signal MLME_START.confirm(SUCCESS);
  }

  async event void BeaconSendAlarm.fired()
  {
    // start/schedule beacon transmission
    ieee154_timestamp_t *timestamp = &m_lastBeaconTxRefTime;
    m_txState = S_TX_LOCKED;

    if (call IsBroadcastReady.getNow())
      m_beaconFrame.header->mhr[MHR_INDEX_FC1] |= FC1_FRAME_PENDING;
    else
      m_beaconFrame.header->mhr[MHR_INDEX_FC1] &= ~FC1_FRAME_PENDING;

    m_beaconFrame.header->mhr[MHR_INDEX_SEQNO] = m_bsn; // update beacon seqno
    if (m_txOneBeaconImmediately) {
      m_txOneBeaconImmediately = FALSE;
      timestamp = NULL;
    }
    call BeaconTx.transmit(&m_beaconFrame, timestamp, m_dt);
    dbg_serial("BeaconTransmitP","Beacon Tx scheduled for %lu.\n", (uint32_t) (*timestamp + m_dt));
  }

  async event void BeaconTx.transmitDone(ieee154_txframe_t *frame, const ieee154_timestamp_t *timestamp, error_t result)
  {
    // The beacon frame was transmitted, i.e. the CAP has just started
    // update the state then pass the token on to the next component 

    uint8_t gtsFieldLength;

    ASSERT(result == SUCCESS); // must succeed, we're sending without CCA or ACK request
    if (timestamp != NULL) {
      m_lastBeaconTxTime = frame->metadata->timestamp;
      memcpy(&m_lastBeaconTxRefTime, timestamp, sizeof(ieee154_timestamp_t));
      m_dt = m_beaconInterval; // transmit the next beacon at m_lastBeaconTxTime + m_dt 
      dbg_serial("BeaconTransmitP", "Beacon Tx success at %lu\n", (uint32_t) m_lastBeaconTxTime);
    } else {
      // Timestamp is invalid; this is bad. We need the beacon timestamp for the 
      // slotted CSMA-CA, because it defines the slot reference time. We can't use this superframe
      // TODO: check if this was the initial beacon (then m_lastBeaconTxRefTime is invalid)
      dbg_serial("BeaconTransmitP", "Invalid timestamp!\n");
      m_dt += m_beaconInterval;
      call RadioToken.request();
      call RadioToken.release();      
      return;
    }

    // update superframe-related variables
    m_numGtsSlots = (frame->payload[2] & 0x07);
    gtsFieldLength = 1 + ((m_numGtsSlots > 0) ? 1 + m_numGtsSlots * 3: 0);
    m_numCapSlots = (frame->payload[1] & 0x0F) + 1;
    m_sfSlotDuration = (((uint32_t) 1) << ((frame->payload[0] & 0xF0) >> 4)) * IEEE154_aBaseSlotDuration;

    if (frame->header->mhr[0] & FC1_FRAME_PENDING)
      m_framePendingBit = TRUE;
    else
      m_framePendingBit = FALSE;
    memcpy(m_gtsField, &frame->payload[2], gtsFieldLength);
    if (frame->payload[1] & 0x10) {
      // BLE is active; calculate the time offset from slot 0
      m_battLifeExtDuration = IEEE154_SHR_DURATION + 
        (frame->headerLen + frame->payloadLen + 2) * IEEE154_SYMBOLS_PER_OCTET; 
      if (frame->headerLen + frame->payloadLen + 2 > IEEE154_aMaxSIFSFrameSize)
        m_battLifeExtDuration += IEEE154_MIN_LIFS_PERIOD;
      else
        m_battLifeExtDuration += IEEE154_MIN_SIFS_PERIOD;
      m_battLifeExtDuration = m_battLifeExtDuration + m_battLifeExtPeriods * 20;
    } else
      m_battLifeExtDuration = 0;

    // we pass on the token now, but make a reservation to get it back 
    // to transmit the next beacon (at the start of the next superframe)
    call RadioToken.request();  
    call RadioToken.transferTo(RADIO_CLIENT_COORDBROADCAST); 
    post txDoneTask();
  }

  task void txDoneTask()
  {
    call MLME_SET.macBSN(m_bsn++);
    call SetMacBeaconTxTime.set(m_lastBeaconTxTime); // start of slot0, ie. first preamble byte of beacon
    call BeaconPayloadUpdateTimer.startOneShotAt(m_lastBeaconTxTime, 
        (m_beaconInterval>BEACON_PAYLOAD_UPDATE_INTERVAL) ? (m_beaconInterval - BEACON_PAYLOAD_UPDATE_INTERVAL): 0);
    if (m_requestBitmap & REQUEST_CONFIRM_PENDING) {
      m_requestBitmap &= ~REQUEST_CONFIRM_PENDING;
      signal MLME_START.confirm(IEEE154_SUCCESS);
    }
    m_txState = S_TX_IDLE;
    signal IEEE154TxBeaconPayload.beaconTransmitted();
    dbg_serial_flush();
  }


  /* ----------------------- Beacon Payload ----------------------- */
  /*
   * All access to the payload fields in the beacon happen
   * through a set of temporary variables/flags, and just before 
   * the frame is loaded into the radio these changes are 
   * written into the actual payload portion of the beacon frame.
   */

  command error_t IEEE154TxBeaconPayload.setBeaconPayload(void *beaconPayload, uint8_t length)
  {
    if (length > IEEE154_aMaxBeaconPayloadLength)
      return ESIZE;
    else {
      if (m_payloadState & MODIFIED_BEACON_PAYLOAD)
        return EBUSY;
      m_updateBeaconPayload = beaconPayload;
      m_updateBeaconLength = length;
      m_updateBeaconOffset = 0;
      m_payloadState |= (MODIFIED_BEACON_PAYLOAD | MODIFIED_BEACON_PAYLOAD_NEW);
    }
    return SUCCESS;
  }

  command const void* IEEE154TxBeaconPayload.getBeaconPayload()
  {
    return &m_payload[IEEE154_aMaxBeaconOverhead];
  }

  command uint8_t IEEE154TxBeaconPayload.getBeaconPayloadLength()
  {
    return m_beaconFrame.payloadLen - (m_pendingAddrLen + m_pendingGtsLen + 2);
  }

  command error_t IEEE154TxBeaconPayload.modifyBeaconPayload(uint8_t offset, void *buffer, uint8_t bufferLength)
  {
    uint16_t totalLen = offset + bufferLength;
    if (totalLen > IEEE154_aMaxBeaconPayloadLength ||
        call IEEE154TxBeaconPayload.getBeaconPayloadLength() < totalLen)
      return ESIZE;
    else {
      if (m_payloadState & MODIFIED_BEACON_PAYLOAD)
        return EBUSY;
      m_updateBeaconPayload = buffer;
      m_updateBeaconOffset = offset;
      m_updateBeaconLength = bufferLength;
      m_payloadState |= MODIFIED_BEACON_PAYLOAD;
    }
    return SUCCESS;
  }

  event void PIBUpdate.notify[uint8_t attributeID](const void* attributeValue)
  {
    switch (attributeID)
    {
      case IEEE154_macAssociationPermit:  
        atomic m_payloadState |= MODIFIED_SF_SPEC;
        break;
      case IEEE154_macGTSPermit:
        atomic m_payloadState |= MODIFIED_GTS_FIELD;
        break;
      default:
        break;
    }
  }

  event void PendingAddrSpecUpdated.notify(bool val)
  {
    atomic m_payloadState |= MODIFIED_PENDING_ADDR_FIELD;
  }

  event void GtsSpecUpdated.notify(bool val)
  {
    atomic m_payloadState |= MODIFIED_GTS_FIELD;
  }

  uint8_t getNumGtsSlots(uint8_t *gtsInfoField)
  {
    uint8_t i, num=0;
    for (i=0; i<(gtsInfoField[0] & GTS_DESCRIPTOR_COUNT_MASK); i++)
      num += ((gtsInfoField[4+i*3] & GTS_LENGTH_MASK) >> GTS_LENGTH_OFFSET);
    return num;
  }

  event void BeaconPayloadUpdateTimer.fired()
  {
    // in this order the MAC payload is updated:
    // (1) pending addresses
    // (2) GTS spec
    // (3) SF spec
    // (4) beacon payload (if there's enough time)
    uint8_t len=0, *beaconSpecs = &m_payload[IEEE154_aMaxBeaconOverhead]; // going backwards
    uint8_t beaconPayloadUpdated = 0, numGtsSlots = m_numGtsSlots;

    atomic {
      if (m_txState == S_TX_LOCKED) 
      {
        dbg_serial("BeaconTransmitP", "BeaconPayloadUpdateTimer fired too late!\n");
        return; // too late !
      }

      // (1) update pending addresses
      if (m_payloadState & MODIFIED_PENDING_ADDR_FIELD) {
        len = call PendingAddrWrite.getLength();
        beaconSpecs -= len;
        call PendingAddrWrite.write(beaconSpecs, len);
        if (len != m_pendingAddrLen) {
          m_pendingAddrLen = len;
          m_payloadState |= MODIFIED_SPECS_MASK; // need to rewrite specs before
        }
      } else 
        beaconSpecs -= m_pendingAddrLen;
      
      // (2) update GTS spec
      if (m_payloadState & MODIFIED_GTS_FIELD) {
        len = call GtsInfoWrite.getLength();
        beaconSpecs -= len;
        call GtsInfoWrite.write(beaconSpecs, len);
        numGtsSlots = getNumGtsSlots(beaconSpecs);
        if (len != m_pendingGtsLen || ((15-numGtsSlots) != m_numCapSlots-1)) {
          m_pendingGtsLen = len;
          m_payloadState |= MODIFIED_SPECS_MASK; // need to rewrite specs before
        }
      } else 
        beaconSpecs -= m_pendingGtsLen;

      // (3) update SF spec
      beaconSpecs -= 2; // sizeof SF Spec
      if (m_payloadState & MODIFIED_SF_SPEC) {
        beaconSpecs[0] = m_beaconOrder | (m_superframeOrder << 4);
        beaconSpecs[1] = 0;
        if (call MLME_GET.macAssociationPermit())
          beaconSpecs[1] |= SF_SPEC2_ASSOCIATION_PERMIT;        
        if (call MLME_GET.macPanCoordinator())
          beaconSpecs[1] |= SF_SPEC2_PAN_COORD;
        beaconSpecs[1] |= ((15-numGtsSlots) & 0x0F); // update FinalCAPSlot field
      }
      m_beaconFrame.payloadLen = (m_pendingAddrLen + m_pendingGtsLen + 2) + m_beaconPayloadLen;
      m_beaconFrame.payload = beaconSpecs;
      m_payloadState &= ~MODIFIED_SPECS_MASK; // clear flags
    } // end atomic (give BeaconSendAlarm.fired() the chance to execute)

    signal IEEE154TxBeaconPayload.aboutToTransmit();

    atomic {
      // (4) try to update beacon payload 
      if (m_txState == S_TX_LOCKED) 
      {
        dbg_serial("BeaconTransmitP", "Not enough time for beacon payload update!\n");
        return; // too late !
      }
      if (m_payloadState & MODIFIED_BEACON_PAYLOAD) {
        memcpy(&m_payload[IEEE154_aMaxBeaconOverhead + m_updateBeaconOffset], 
            m_updateBeaconPayload, m_updateBeaconLength);
        beaconPayloadUpdated = (m_payloadState & MODIFIED_BEACON_PAYLOAD_MASK);
        if (beaconPayloadUpdated & MODIFIED_BEACON_PAYLOAD_NEW)
          m_beaconPayloadLen = m_updateBeaconOffset + m_updateBeaconLength;
      }
      m_beaconFrame.payloadLen = (m_pendingAddrLen + m_pendingGtsLen + 2) + m_beaconPayloadLen;
      m_payloadState &= ~MODIFIED_BEACON_PAYLOAD_MASK;
    }
    if (beaconPayloadUpdated) {
      if ((beaconPayloadUpdated & MODIFIED_BEACON_PAYLOAD_NEW))
        signal IEEE154TxBeaconPayload.setBeaconPayloadDone(m_updateBeaconPayload, m_updateBeaconLength);
      else
        signal IEEE154TxBeaconPayload.modifyBeaconPayloadDone(m_updateBeaconOffset,
            m_updateBeaconPayload, m_updateBeaconLength);
    }
  }

  /* ----------------------- Realignment ----------------------- */
  /* In beaconenabled mode a realignment frame is broadcast in the CAP
   * immediately after the beacon was transmitted.  In non-beaconenabled mode a
   * realignment frame is sent using unslotted CSMA. In both cases, if the
   * transmission was successful, the superframe spec should be updated now.
   **/

  event void RealignmentBeaconEnabledTx.transmitDone(ieee154_txframe_t *frame, ieee154_status_t status)
  {
    finishRealignment(frame, status);
  }
 
  event void RealignmentNonBeaconEnabledTx.transmitDone(ieee154_txframe_t *frame, ieee154_status_t status)
  {
    finishRealignment(frame, status);
  }

  void finishRealignment(ieee154_txframe_t *frame, ieee154_status_t status)
  {
    call GetSetRealignmentFrame.set(frame);
    if (status == IEEE154_SUCCESS) {
      continueStartRequest();
      m_requestBitmap &= ~REQUEST_REALIGNMENT_DONE_PENDING; // unlock
      // signal confirm where we calculate the next beacon transmission time
    } else {
      m_requestBitmap = 0;
      signal MLME_START.confirm(status);
    }
  }

  /* ----------------------- BeaconRequest ----------------------- */

  event message_t* BeaconRequestRx.received(message_t* frame)
  {
    if (m_beaconOrder == 15) {
      // transmit the beacon frame using unslotted CSMA-CA
      // TODO
    }
    return frame;
  }

  /* -----------------------  SF Structure, etc. ----------------------- */

  async command uint32_t OutgoingSF.sfStartTime()
  { 
    return m_lastBeaconTxTime; 
  }

  async command uint16_t OutgoingSF.sfSlotDuration()
  { 
    return m_sfSlotDuration;
  }

  async command uint8_t OutgoingSF.numCapSlots()
  {
    return m_numCapSlots;
  }

  async command uint8_t OutgoingSF.numGtsSlots()
  {
    return m_numGtsSlots;
  }

  async command uint16_t OutgoingSF.battLifeExtDuration()
  {
    return m_battLifeExtDuration;
  }

  async command const uint8_t* OutgoingSF.gtsFields()
  {
    return m_gtsField;
  }

  async command uint16_t OutgoingSF.guardTime()
  {
    return IEEE154_MAX_BEACON_JITTER(m_beaconOrder) + IEEE154_RADIO_TX_DELAY;
  }

  async command const ieee154_timestamp_t* OutgoingSF.sfStartTimeRef()
  {
    return &m_lastBeaconTxRefTime;
  }

  async command bool OutgoingSF.isBroadcastPending()
  {
    return m_framePendingBit;
  }

  async command bool IsSendingBeacons.getNow()
  { 
    return (m_beaconOrder < 15) || ((m_requestBitmap & REQUEST_CONFIRM_PENDING) && m_updateBeaconOrder < 15);
  }

  default event void MLME_START.confirm(ieee154_status_t status) {}
  default event void IEEE154TxBeaconPayload.setBeaconPayloadDone(void *beaconPayload, uint8_t length) {}
  default event void IEEE154TxBeaconPayload.modifyBeaconPayloadDone(uint8_t offset, void *buffer, uint8_t bufferLength) {}
  default event void IEEE154TxBeaconPayload.aboutToTransmit() {}
  default event void IEEE154TxBeaconPayload.beaconTransmitted() {}

}
