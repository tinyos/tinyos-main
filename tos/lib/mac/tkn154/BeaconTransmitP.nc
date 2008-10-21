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
 * $Revision: 1.4 $
 * $Date: 2008-10-21 17:29:00 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "TKN154_MAC.h"
#include "TKN154_PHY.h"
module BeaconTransmitP
{
  provides
  {
    interface Init as Reset;
    interface MLME_START;
    interface WriteBeaconField as SuperframeSpecWrite;
    interface GetNow<bool> as IsSendingBeacons;
    interface GetNow<uint32_t> as CapStart; 
    interface GetNow<ieee154_reftime_t*> as CapStartRefTime; 
    interface GetNow<uint32_t> as CapLen; 
    interface GetNow<uint32_t> as CapEnd; 
    interface GetNow<uint32_t> as CfpEnd; 
    interface GetNow<uint32_t> as CfpLen; 
    interface GetNow<bool> as IsBLEActive; 
    interface GetNow<uint16_t> as BLELen; 
    interface GetNow<uint8_t*> as GtsField; 
    interface GetNow<uint32_t> as SfSlotDuration; 
    interface GetNow<uint32_t> as BeaconInterval; 
    interface GetNow<uint8_t> as FinalCapSlot;
    interface GetNow<uint8_t> as NumGtsSlots;
    interface GetNow<bool> as BeaconFramePendingBit;
    interface IEEE154TxBeaconPayload;
  } uses {
    interface Notify<bool> as GtsSpecUpdated;
    interface Notify<bool> as PendingAddrSpecUpdated;
    interface Notify<const void*> as PIBUpdate[uint8_t attributeID];
    interface Alarm<TSymbolIEEE802154,uint32_t> as BeaconTxAlarm;
    interface Timer<TSymbolIEEE802154> as BeaconPayloadUpdateTimer;
    interface RadioOff;
    interface Get<bool> as IsBeaconEnabledPAN;
    interface RadioTx as BeaconTx;
    interface MLME_GET;
    interface MLME_SET;
    interface Resource as Token;
    interface ResourceTransferred as TokenTransferred;
    interface ResourceTransfer as TokenToBroadcast;
    interface FrameTx as RealignmentBeaconEnabledTx;
    interface FrameTx as RealignmentNonBeaconEnabledTx;
    interface FrameRx as BeaconRequestRx;
    interface WriteBeaconField as GtsInfoWrite;
    interface WriteBeaconField as PendingAddrWrite;
    interface FrameUtility;
    interface GetNow<bool> as IsTrackingBeacons;
    interface GetNow<uint32_t> as LastBeaconRxTime;
    interface GetNow<ieee154_reftime_t*> as LastBeaconRxRefTime; 
    interface Ieee802154Debug as Debug;
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

  norace ieee154_txframe_t m_beaconFrame;
  ieee154_header_t m_header; 
  uint8_t m_payload[MAX_BEACON_PAYLOAD_SIZE]; 
  ieee154_metadata_t m_metadata; 
  uint8_t m_gtsField[1+1+3*7];

  void *m_updateBeaconPayload;
  uint8_t m_updateBeaconOffset;
  uint8_t m_updateBeaconLength;
  uint8_t m_beaconPayloadLen;
  uint8_t m_pendingAddrLen;
  uint8_t m_pendingGtsLen;

  norace uint8_t m_requests; // TODO: check why norace?
  norace uint8_t m_txState;
  uint8_t m_payloadState;
  norace bool m_txOneBeaconImmediately;

  uint16_t m_PANId;
  norace uint32_t m_startTime;
  uint8_t m_logicalChannel;
  norace uint8_t m_beaconOrder;
  norace uint8_t m_superframeOrder;
  ieee154_macBattLifeExt_t m_batteryLifeExtension;
  bool m_PANCoordinator;
  norace uint32_t m_beaconInterval;
  norace uint32_t m_previousBeaconInterval;
  norace uint32_t m_dt;
  norace uint8_t m_bsn;
  norace uint32_t m_lastBeaconTxTime;
  norace ieee154_reftime_t m_lastBeaconTxRefTime;
  norace uint32_t m_coordCapLen;
  norace uint32_t m_coordCfpEnd;
  norace uint32_t m_sfSlotDuration;
  norace uint8_t m_finalCAPSlot;
  norace uint8_t m_numGtsSlots;
  norace uint16_t m_BLELen;
  norace ieee154_macBattLifeExtPeriods_t m_battLifeExtPeriods;
  norace bool m_framePendingBit;

  uint16_t m_updatePANId;
  uint8_t m_updateLogicalChannel;
  uint32_t m_updateStartTime;
  norace uint8_t m_updateBeaconOrder;
  uint8_t m_updateSuperframeOrder;
  bool m_updatePANCoordinator;
  bool m_updateBatteryLifeExtension;

  task void txDoneTask();
  task void signalStartConfirmSuccessTask();
  void prepareNextBeaconTransmission();
  void continueStartRequest();
  void finishRealignment(ieee154_txframe_t *frame, ieee154_status_t status);

  command error_t Reset.init()
  {
    m_beaconFrame.header = &m_header;
    m_beaconFrame.headerLen = 0;
    m_beaconFrame.payload = m_payload;
    m_beaconFrame.payloadLen = 0;
    m_beaconFrame.metadata = &m_metadata;
    m_updateBeaconPayload = 0;
    m_updateBeaconLength = 0;
    m_requests = m_payloadState = m_txState = 0;
    m_PANCoordinator = FALSE;
    m_beaconPayloadLen = m_pendingAddrLen = m_pendingGtsLen = 0;
    m_gtsField[0] = 0;
    m_finalCAPSlot = 15;
    m_beaconOrder = 15;
    call BeaconPayloadUpdateTimer.stop();
    call BeaconTxAlarm.stop();
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
    ieee154_macShortAddress_t shortAddress = call MLME_GET.macShortAddress();
    ieee154_status_t status = IEEE154_SUCCESS;

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
    else if (m_requests & (REQUEST_CONFIRM_PENDING | REQUEST_UPDATE_SF))
      status = IEEE154_TRANSACTION_OVERFLOW;
    else if ((call IsBeaconEnabledPAN.get() && beaconOrder > 14) ||
              (!call IsBeaconEnabledPAN.get() && beaconOrder < 15))
      status = IEEE154_INVALID_PARAMETER;
    else {
      // new configuration *will* be put in operation
      status = IEEE154_SUCCESS;
      if (panCoordinator)
        startTime = 0; // start immediately
      call Debug.log(LEVEL_INFO, StartP_REQUEST, logicalChannel, beaconOrder, superframeOrder);
      if (beaconOrder == 15){
        // beaconless PAN
        superframeOrder = 15;
      }
      m_updatePANId = panID;
      m_updateLogicalChannel = logicalChannel;
      m_updateStartTime = startTime;
      m_updateBeaconOrder = beaconOrder; 
      m_updateSuperframeOrder = superframeOrder;
      m_updatePANCoordinator = panCoordinator;
      m_updateBatteryLifeExtension = batteryLifeExtension;   
      m_requests = (REQUEST_CONFIRM_PENDING | REQUEST_UPDATE_SF); // lock
      if (coordRealignment)
        m_requests |= REQUEST_REALIGNMENT;
      if (m_beaconOrder == 15) // only request token if we're not already transmitting beacons
        call Token.request(); 
    }
    return status;
  }

  void continueStartRequest()
  {
    uint8_t offset;
    ieee154_macShortAddress_t shortAddress;
    bool isShortAddr;

    // (1) coord realignment?
    if (m_requests & REQUEST_REALIGNMENT){
      ieee154_txframe_t *realignmentFrame = call GetSetRealignmentFrame.get();
      m_requests &= ~REQUEST_REALIGNMENT;
      if (realignmentFrame == NULL){
        // allocation failed!
        m_requests = 0;
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
      
      if (m_beaconOrder < 15){
        // we're already transmitting beacons; the realignment frame
        // must be sent (broadcast) after the next beacon
        if (call RealignmentBeaconEnabledTx.transmit(realignmentFrame) != IEEE154_SUCCESS){
          m_requests = 0;
          call GetSetRealignmentFrame.set(realignmentFrame);
          signal MLME_START.confirm(IEEE154_TRANSACTION_OVERFLOW);
        } else {
          // The realignment frame will be transmitted immediately after 
          // the next beacon - the result will be signalled in 
          // RealignmentBeaconEnabledTx.transmitDone(). Only then the superframe
          // structure is updated and MLME_START.confirm signalled.
          m_requests |= REQUEST_REALIGNMENT_DONE_PENDING; // lock
        }
      } else {
        // send realignment frame in unslotted csma-ca now
        if (call RealignmentNonBeaconEnabledTx.transmit(realignmentFrame) != IEEE154_SUCCESS){
          m_requests = 0;
          call GetSetRealignmentFrame.set(realignmentFrame);
          signal MLME_START.confirm(IEEE154_TRANSACTION_OVERFLOW);
        } else {
          // A realignment frame will be transmitted now, the result will 
          // be signalled in RealignmentNonBeaconEnabledTx.transmitDone(). Only 
          // then the superframe structure is updated and MLME_START.confirm 
          // signalled.
          m_requests |= REQUEST_REALIGNMENT_DONE_PENDING; // lock
        }
      }
      return; 
    }

    // (2) update internal state
    m_startTime = m_updateStartTime;
    m_txOneBeaconImmediately = FALSE;
    m_previousBeaconInterval = 0;
    if (m_startTime){
      m_lastBeaconTxRefTime = *call LastBeaconRxRefTime.getNow();
      m_lastBeaconTxTime = call LastBeaconRxTime.getNow();
    } else {
      // no StartTime defined by next higher layer - but
      // if a realignment frame was transmitted, the next
      // beacon tx time must take the old BI into consideration
      if (m_requests & REQUEST_REALIGNMENT_DONE_PENDING)
        m_previousBeaconInterval = m_beaconInterval;
      else
        m_txOneBeaconImmediately = TRUE;
    }
    m_PANId = m_updatePANId;
    m_logicalChannel = m_updateLogicalChannel;
    m_beaconOrder = m_updateBeaconOrder; 
    m_superframeOrder = m_updateSuperframeOrder;
    m_PANCoordinator = m_updatePANCoordinator;
    if (m_beaconOrder < 15){
      m_batteryLifeExtension = m_updateBatteryLifeExtension;   
      m_beaconInterval = ((uint32_t) 1 << m_updateBeaconOrder) * IEEE154_aBaseSuperframeDuration;
    } else {
      m_batteryLifeExtension = FALSE;   
      m_beaconInterval = 0;
    }
    m_txState = S_TX_IDLE;
    m_bsn = call MLME_GET.macBSN()+1;
    m_battLifeExtPeriods = call MLME_GET.macBattLifeExtPeriods();

    // (3) update PIB
    call MLME_SET.macBeaconOrder(m_beaconOrder);
    call SetMacSuperframeOrder.set(m_superframeOrder);
    call MLME_SET.macPANId(m_PANId);
    call MLME_SET.phyCurrentChannel(m_logicalChannel);
    if (m_beaconOrder < 15)
      call MLME_SET.macBattLifeExt(m_batteryLifeExtension);
    call SetMacPanCoordinator.set(m_PANCoordinator);

    // (4) assemble beacon header and payload
    shortAddress = call MLME_GET.macShortAddress();
    isShortAddr = (shortAddress != 0xFFFE);
    m_beaconFrame.header->mhr[MHR_INDEX_FC1] = FC1_FRAMETYPE_BEACON;
    m_beaconFrame.header->mhr[MHR_INDEX_FC2] = isShortAddr ? FC2_SRC_MODE_SHORT : FC2_SRC_MODE_EXTENDED;
    offset = MHR_INDEX_ADDRESS;
    *((nxle_uint16_t*) &m_beaconFrame.header->mhr[offset]) = m_PANId;
    offset += sizeof(ieee154_macPANId_t);
    if (isShortAddr){
      *((nxle_uint16_t*) &m_beaconFrame.header->mhr[offset]) = shortAddress;
      offset += sizeof(ieee154_macShortAddress_t);
    } else {
      call FrameUtility.copyLocalExtendedAddressLE(&m_beaconFrame.header->mhr[offset]);
      offset += 8;
    }
    m_beaconFrame.headerLen = offset;
    m_payloadState |= MODIFIED_SPECS_MASK;    // update beacon payload
    signal BeaconPayloadUpdateTimer.fired();  // assemble initial beacon payload

    if (m_beaconOrder < 15){
      // beacon-enabled PAN, signal confirm after next 
      // beacon has been transmitted (see MSC, Fig. 38)
      m_requests = REQUEST_CONFIRM_PENDING;
    } else {
      // beaconless PAN, we're done
      m_requests = 0;
      signal MLME_START.confirm(IEEE154_SUCCESS);
    }
  }

  task void grantedTask()
  {
    signal Token.granted();
  }

  event void Token.granted()
  {
    call Debug.flush();
    call Debug.log(LEVEL_INFO, StartP_GOT_RESOURCE, m_lastBeaconTxTime, m_beaconInterval, m_requests);
    if (m_requests & REQUEST_REALIGNMENT_DONE_PENDING){
      // unlikely to occur: we have not yet received a done()
      // event after sending out a realignment frame 
      post grantedTask(); // spin
      return;
    }
    if (m_requests & REQUEST_UPDATE_SF){
      m_requests &= ~REQUEST_UPDATE_SF;
      continueStartRequest();
      call Debug.log(LEVEL_INFO, StartP_UPDATE_STATE, 0, 0, 0);
    }
    if (call RadioOff.isOff())
      prepareNextBeaconTransmission();
    else
      call RadioOff.off();
  }

  async event void TokenTransferred.transferred()
  {
    post grantedTask();
  }  

  async event void RadioOff.offDone()
  {
    prepareNextBeaconTransmission();
  }

  void prepareNextBeaconTransmission()
  {
    if (m_txState == S_TX_LOCKED){
      // have not had time to finish processing the last sent beacon
      post grantedTask();
      call Debug.log(LEVEL_CRITICAL, StartP_OWNER_TOO_FAST, 0, 0, 0);
      return;
    } else if (m_beaconOrder > 14){
      call Token.release();
    } else {
      atomic {
        m_txState = S_TX_WAITING;
        if (m_txOneBeaconImmediately){
          signal BeaconTxAlarm.fired();
          return;
        } else if (m_startTime != 0){
          // a new sf spec was put into operation, with a user-defined StartTime 
          // here m_lastBeaconTxTime is actually the last time a beacon was received
          m_dt = m_startTime;
          m_startTime = 0;
        } else if (m_previousBeaconInterval != 0){
          // a new sf spec was put into operation, after a realignment frame was
          // broadcast; the next beacon time should still be calculated using the
          // old BI (one last time)
          m_dt = m_previousBeaconInterval;
          m_previousBeaconInterval = 0;
          if (m_requests & REQUEST_CONFIRM_PENDING){
            // only now the next higher layer is to be informed 
            m_requests &= ~REQUEST_CONFIRM_PENDING;
            post signalStartConfirmSuccessTask();
          }
        } else {
          // the usual case: next beacon tx time = last time + BI
          m_dt = m_beaconInterval;
        }
        while (call TimeCalc.hasExpired(m_lastBeaconTxTime, m_dt)){ // missed sending a beacon
          call Debug.log(LEVEL_INFO, StartP_SKIPPED_BEACON, m_lastBeaconTxTime, m_dt, 0);
          m_dt += m_beaconInterval;
        }
        if (m_dt < IEEE154_RADIO_TX_PREPARE_DELAY)
          m_dt = IEEE154_RADIO_TX_PREPARE_DELAY;
        // don't call BeaconTx.load just yet, otherwise the next
        // higher layer cannot modify the beacon payload anymore;
        // rather, set an alarm 
        call BeaconTxAlarm.startAt(m_lastBeaconTxTime, m_dt - IEEE154_RADIO_TX_PREPARE_DELAY);
      }
    }
  }

  async event void BeaconTxAlarm.fired()
  {
    atomic {
      switch (m_txState)
      {
        case S_TX_WAITING: 
          m_txState = S_TX_LOCKED;
          if (call IsBroadcastReady.getNow())
            m_beaconFrame.header->mhr[MHR_INDEX_FC1] |= FC1_FRAME_PENDING;
          else
            m_beaconFrame.header->mhr[MHR_INDEX_FC1] &= ~FC1_FRAME_PENDING;
          m_beaconFrame.header->mhr[MHR_INDEX_SEQNO] = m_bsn; // update beacon seqno
          call Debug.log(LEVEL_INFO, StartP_PREPARE_TX, 0, m_lastBeaconTxTime, 0);
          call BeaconTx.load(&m_beaconFrame); 
          break;
        case S_TX_LOCKED: 
          call Debug.log(LEVEL_INFO, StartP_TRANSMIT, m_lastBeaconTxTime, m_dt, ((uint32_t)m_lastBeaconTxRefTime));
          call BeaconTx.transmit(&m_lastBeaconTxRefTime, m_dt, 0, FALSE);
          break;
      }
    }
  }

  async event void BeaconTx.loadDone()
  {
    atomic {
      call Debug.log(LEVEL_INFO, StartP_PREPARE_TXDONE, 0, m_lastBeaconTxTime, 0);
      if (m_txOneBeaconImmediately){
        m_txOneBeaconImmediately = FALSE;
        call BeaconTx.transmit(0, 0, 0, FALSE); // now!
      } else 
        call BeaconTxAlarm.startAt(m_lastBeaconTxTime, m_dt - IEEE154_RADIO_TX_SEND_DELAY);
    }
  }
    
  async event void BeaconTx.transmitDone(ieee154_txframe_t *frame, 
      ieee154_reftime_t *referenceTime, bool pendingFlag, error_t error)
  {
    // Coord CAP has just started...
    uint8_t gtsFieldLength;
    // Sec. 7.5.1.1: "start of slot 0 is defined as the point at which 
    // the first symbol of the beacon PPDU is transmitted" 
    call Debug.log(LEVEL_INFO, StartP_BEACON_TRANSMITTED, frame->metadata->timestamp, m_lastBeaconTxTime, m_dt);
    m_lastBeaconTxTime = frame->metadata->timestamp;
    memcpy(&m_lastBeaconTxRefTime, referenceTime, sizeof(ieee154_reftime_t));
    m_numGtsSlots = (frame->payload[2] & 0x07);
    gtsFieldLength = 1 + ((m_numGtsSlots > 0) ? 1 + m_numGtsSlots * 3: 0);
    m_finalCAPSlot = (frame->payload[1] & 0x0F);
    m_sfSlotDuration = (((uint32_t) 1) << ((frame->payload[0] & 0xF0) >> 4)) * IEEE154_aBaseSlotDuration;
    if (frame->header->mhr[0] & FC1_FRAME_PENDING)
      m_framePendingBit = TRUE;
    else
      m_framePendingBit = FALSE;
    memcpy(m_gtsField, &frame->payload[2], gtsFieldLength);
    if (frame->payload[1] & 0x10){
      // BLE is active; calculate the time offset from slot0
      m_BLELen = IEEE154_SHR_DURATION + 
        (frame->headerLen + frame->payloadLen) * IEEE154_SYMBOLS_PER_OCTET; 
      if (frame->headerLen + frame->payloadLen > IEEE154_aMaxSIFSFrameSize)
        m_BLELen += IEEE154_MIN_LIFS_PERIOD;
      else
        m_BLELen += IEEE154_MIN_SIFS_PERIOD;
      m_BLELen += m_battLifeExtPeriods;
    } else
      m_BLELen = 0;
    call Token.request();             // register another request, before ...
    call TokenToBroadcast.transfer(); // ... we let Broadcast module take over
    post txDoneTask();
  }

  task void txDoneTask()
  {
    call MLME_SET.macBSN(m_bsn++);
    call SetMacBeaconTxTime.set(m_lastBeaconTxTime); // start of slot0, ie. first preamble byte of beacon
    call BeaconPayloadUpdateTimer.startOneShotAt(m_lastBeaconTxTime, 
        (m_beaconInterval>BEACON_PAYLOAD_UPDATE_INTERVAL) ? (m_beaconInterval - BEACON_PAYLOAD_UPDATE_INTERVAL): 0);
    if (m_requests & REQUEST_CONFIRM_PENDING){
      m_requests &= ~REQUEST_CONFIRM_PENDING;
      signal MLME_START.confirm(IEEE154_SUCCESS);
    }
    m_txState = S_TX_IDLE;
    signal IEEE154TxBeaconPayload.beaconTransmitted();
    call Debug.flush();
  }


/* ----------------------- Beacon Payload ----------------------- */
/*
 * All access to the payload fields in the beacon happen
 * through a set of temporary variables/flags, and just before 
 * the frame is loaded into the radio these changes are 
 * propagated into the actual payload portion of the beacon frame.
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
    // (3) sf spec
    // (4) beacon payload (if there's enough time)
    uint8_t len=0, *beaconSpecs = &m_payload[IEEE154_aMaxBeaconOverhead]; // going backwards
    uint8_t beaconPayloadUpdated = 0, numGtsSlots = 15 - m_finalCAPSlot;

    atomic {
      if (m_txState == S_TX_LOCKED) 
      {
        call Debug.log(LEVEL_INFO, StartP_BEACON_UPDATE, 0, 0, m_txState);
        return; // too late !
      }
      if (m_payloadState & MODIFIED_PENDING_ADDR_FIELD){
        len = call PendingAddrWrite.getLength();
        beaconSpecs -= len;
        call PendingAddrWrite.write(beaconSpecs, len);
        if (len != m_pendingAddrLen){
          m_pendingAddrLen = len;
          m_payloadState |= MODIFIED_SPECS_MASK; // need to rewrite specs before
        }
      } else 
        beaconSpecs -= m_pendingAddrLen;
      if (m_payloadState & MODIFIED_GTS_FIELD){
        len = call GtsInfoWrite.getLength();
        beaconSpecs -= len;
        call GtsInfoWrite.write(beaconSpecs, len);
        numGtsSlots = getNumGtsSlots(beaconSpecs);
        if (len != m_pendingGtsLen || ((15-numGtsSlots) != m_finalCAPSlot)){
          m_pendingGtsLen = len;
          m_payloadState |= MODIFIED_SPECS_MASK; // need to rewrite specs before
        }
      } else 
        beaconSpecs -= m_pendingGtsLen;
      beaconSpecs -= 2; // sizeof SF Spec
      if (m_payloadState & MODIFIED_SF_SPEC){
        call SuperframeSpecWrite.write(beaconSpecs, 2);
        beaconSpecs[1] &= 0xF0; // clear FinalCAPSlot field
        beaconSpecs[1] |= ((15-numGtsSlots) & 0x0F); // update FinalCAPSlot field
      }
      m_beaconFrame.payloadLen = (m_pendingAddrLen + m_pendingGtsLen + 2) + m_beaconPayloadLen;
      m_beaconFrame.payload = beaconSpecs;
      m_payloadState &= ~MODIFIED_SPECS_MASK; // clear flags
    } // end atomic (give BeaconTxAlarm.fired() the chance to execute)
    signal IEEE154TxBeaconPayload.aboutToTransmit();
    atomic {
      if (m_txState == S_TX_LOCKED) 
      {
        call Debug.log(LEVEL_INFO, StartP_BEACON_UPDATE_2, 0, 0, m_txState);
        return; // too late !
      }
      if (m_payloadState & MODIFIED_BEACON_PAYLOAD){
        memcpy(&m_payload[IEEE154_aMaxBeaconOverhead + m_updateBeaconOffset], 
            m_updateBeaconPayload, m_updateBeaconLength);
        beaconPayloadUpdated = (m_payloadState & MODIFIED_BEACON_PAYLOAD_MASK);
        if (beaconPayloadUpdated & MODIFIED_BEACON_PAYLOAD_NEW)
          m_beaconPayloadLen = m_updateBeaconOffset + m_updateBeaconLength;
      }
      m_beaconFrame.payloadLen = (m_pendingAddrLen + m_pendingGtsLen + 2) + m_beaconPayloadLen;
      m_payloadState &= ~MODIFIED_BEACON_PAYLOAD_MASK;
    }
    if (beaconPayloadUpdated){
      if ((beaconPayloadUpdated & MODIFIED_BEACON_PAYLOAD_NEW))
        signal IEEE154TxBeaconPayload.setBeaconPayloadDone(m_updateBeaconPayload, m_updateBeaconLength);
      else
        signal IEEE154TxBeaconPayload.modifyBeaconPayloadDone(m_updateBeaconOffset,
            m_updateBeaconPayload, m_updateBeaconLength);
    }
  }

/* -----------------------  SuperframeSpec ----------------------- */

  command uint8_t SuperframeSpecWrite.write(uint8_t *superframeSpecField, uint8_t maxlen)
  {
    if (call SuperframeSpecWrite.getLength() > maxlen)
      return 0;
    superframeSpecField[0] = m_beaconOrder | (m_superframeOrder << 4);
    superframeSpecField[1] = m_finalCAPSlot;
    if (m_PANCoordinator)
      superframeSpecField[1] |= SF_SPEC2_PAN_COORD;
    if (call MLME_GET.macAssociationPermit())
      superframeSpecField[1] |= SF_SPEC2_ASSOCIATION_PERMIT;
    return 2;
  }

  command uint8_t SuperframeSpecWrite.getLength()
  {
    return 2;
  }

/* ----------------------- Realignment ----------------------- */
/* In beacon-enabled mode a realignment frame was broadcast in the CAP
 * immediately after the beacon was transmitted.  In non-beacon-enabled mode a
 * realignment frame was sent using unslotted CSMA. In both cases, if the
 * transmission was successful, the superframe spec must be updated now.
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
    if (status == IEEE154_SUCCESS){
      continueStartRequest();
      m_requests &= ~REQUEST_REALIGNMENT_DONE_PENDING; // unlock
      // signal confirm where we calculate the next beacon transmission time
    } else {
      m_requests = 0;
      signal MLME_START.confirm(status);
    }
  }

/* ----------------------- BeaconRequest ----------------------- */

  event message_t* BeaconRequestRx.received(message_t* frame)
  {
    if (m_beaconOrder == 15){
      // transmit the beacon frame using unslotted CSMA-CA
      // TODO
    }
    return frame;
  }

/* -----------------------  Defaults, etc. ----------------------- */

  task void signalStartConfirmSuccessTask()
  {
    signal MLME_START.confirm(SUCCESS);
  }

  async command bool IsSendingBeacons.getNow()
  { 
    return (m_beaconOrder < 15) || ((m_requests & REQUEST_CONFIRM_PENDING) && m_updateBeaconOrder < 15);
  }

  async command uint32_t BeaconInterval.getNow() { return m_beaconInterval; }
  async command uint32_t CapStart.getNow() { return m_lastBeaconTxTime; }
  async command ieee154_reftime_t* CapStartRefTime.getNow() { return &m_lastBeaconTxRefTime; }
  async command uint32_t CapLen.getNow() { return call SfSlotDuration.getNow() * (call FinalCapSlot.getNow() + 1);}
  async command uint32_t CapEnd.getNow() 
  {
    return call CapStart.getNow() + call CapLen.getNow();
  }
  async command uint32_t CfpEnd.getNow() 
  {
    return call CapStart.getNow() + call SfSlotDuration.getNow() * IEEE154_aNumSuperframeSlots;
  }
  async command uint32_t CfpLen.getNow()
  {
    return call SfSlotDuration.getNow() * (15 - call FinalCapSlot.getNow());
  }
  async command bool IsBLEActive.getNow(){ return m_BLELen>0;}
  async command uint16_t BLELen.getNow(){ return m_BLELen;}
  async command bool BeaconFramePendingBit.getNow(){ return m_framePendingBit;}

  async command uint8_t* GtsField.getNow() { return m_gtsField; }
  async command uint32_t SfSlotDuration.getNow() { return m_sfSlotDuration; }
  async command uint8_t FinalCapSlot.getNow() { return m_finalCAPSlot; }
  async command uint8_t NumGtsSlots.getNow() { return m_numGtsSlots; }

  default event void MLME_START.confirm    (
                          ieee154_status_t status
                        ){}

  default event void IEEE154TxBeaconPayload.setBeaconPayloadDone(void *beaconPayload, uint8_t length){}

  default event void IEEE154TxBeaconPayload.modifyBeaconPayloadDone(uint8_t offset, void *buffer, uint8_t bufferLength){}

  default event void IEEE154TxBeaconPayload.aboutToTransmit(){}

  default event void IEEE154TxBeaconPayload.beaconTransmitted(){}

}
