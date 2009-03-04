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
 * $Date: 2009-03-04 18:31:14 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 * This module is responsible for periodic beacon tracking in a 
 * beacon-enabled PAN.
 */

#include "TKN154_MAC.h"

module BeaconSynchronizeP
{
  provides
  {
    interface Init as Reset;
    interface MLME_SYNC;
    interface MLME_BEACON_NOTIFY;
    interface MLME_SYNC_LOSS;
    interface SuperframeStructure as IncomingSF;
    interface GetNow<bool> as IsTrackingBeacons;
    interface StdControl as TrackSingleBeacon;
  }
  uses
  {
    interface MLME_GET;
    interface MLME_SET;
    interface FrameUtility;
    interface IEEE154BeaconFrame as BeaconFrame;
    interface Alarm<TSymbolIEEE802154,uint32_t> as TrackAlarm;
    interface RadioRx as BeaconRx;
    interface RadioOff;
    interface DataRequest;
    interface FrameRx as CoordRealignmentRx;
    interface Resource as Token;
    interface GetNow<bool> as IsTokenRequested;
    interface ResourceTransferred as TokenTransferred;
    interface ResourceTransfer as TokenToCap;
    interface TimeCalc;
    interface IEEE154Frame as Frame;
    interface Leds;
  }
}
implementation
{
  /* state variables */
  norace bool m_tracking;
  bool m_stopTracking ;
  norace uint8_t m_numBeaconsLost;
  norace uint8_t m_state;
  norace bool m_bufferBusy;

  /* buffers for the parameters of the MLME-SYNC request */
  norace bool m_updatePending;
  uint8_t m_updateLogicalChannel;
  bool m_updateTrackBeacon;

  /* variables that describe the current configuration */
  norace uint32_t m_beaconInterval;
  norace uint32_t m_dt;
  norace uint32_t m_lastBeaconRxTime;
  norace ieee154_timestamp_t m_lastBeaconRxRefTime;
  norace uint8_t m_beaconOrder;
  message_t m_beacon;
  norace message_t *m_beaconPtr = &m_beacon;

  /* variables that describe the latest superframe */
  norace uint32_t m_sfSlotDuration;
  norace bool m_framePendingBit;
  norace uint8_t m_numCapSlots;
  norace uint8_t m_numGtsSlots;
  norace uint16_t m_battLifeExtDuration;
  uint8_t m_gtsField[1+1+3*7];
  
  enum {
    S_PREPARE = 0,
    S_RECEIVING = 1,
    S_RADIO_OFF = 2,
    S_INITIAL_SCAN= 3,

  };


  /* function/task prototypes */
  task void processBeaconTask();
  void trackNextBeacon();
  task void signalGrantedTask();

  command error_t Reset.init()
  {
    // reset this component. will only be called 
    // while we're not owning the token           
    if (m_tracking || m_updatePending)
      signal MLME_SYNC_LOSS.indication(
          IEEE154_BEACON_LOSS,
          call MLME_GET.macPANId(),
          call MLME_GET.phyCurrentChannel(),
          call MLME_GET.phyCurrentPage(),
          NULL);
    m_updatePending = m_stopTracking = m_tracking = FALSE;
    return SUCCESS;
  }  

  /* ----------------------- MLME-SYNC ----------------------- */
  /*
   * Allows to synchronize with the beacons from a coordinator.
   */

  command ieee154_status_t MLME_SYNC.request  (
      uint8_t logicalChannel,
      uint8_t channelPage,
      bool trackBeacon)
  {
    error_t status = IEEE154_SUCCESS;
    uint32_t supportedChannels = IEEE154_SUPPORTED_CHANNELS;
    uint32_t currentChannelBit = 1;

    currentChannelBit <<= logicalChannel;
    if (!(currentChannelBit & supportedChannels) || (call MLME_GET.macPANId() == 0xFFFF) ||
        (channelPage != IEEE154_SUPPORTED_CHANNELPAGE) || !IEEE154_BEACON_ENABLED_PAN)
      status = IEEE154_INVALID_PARAMETER;
    else {
      if (!trackBeacon && m_tracking) {
        // stop tracking after next received beacon
        m_stopTracking = TRUE;
      } else {
        m_stopTracking = FALSE;
        m_updateLogicalChannel = logicalChannel;
        m_updateTrackBeacon = trackBeacon;
        m_updatePending = TRUE;
        atomic {
          // if we are tracking then we'll get the Token automatically,
          // otherwise request it now
          if (!m_tracking && !call Token.isOwner())
            call Token.request();  
        }
      }
    }
    dbg_serial("BeaconSynchronizeP", "MLME_SYNC.request -> result: %lu\n", (uint32_t) status);
    return status;
  }

  event void Token.granted()
  {
    dbg_serial("BeaconSynchronizeP","Got token, expecting beacon in %lu\n",
        (uint32_t) ((m_lastBeaconRxTime + m_dt) - call TrackAlarm.getNow())); 
    if (m_updatePending) {
      dbg_serial("BeaconSynchronizeP", "Preparing initial scan\n"); 
      m_state = S_INITIAL_SCAN;
      m_updatePending = FALSE;      
      m_beaconOrder = call MLME_GET.macBeaconOrder();
      if (m_beaconOrder >= 15)
        m_beaconOrder = 14;
      call MLME_SET.phyCurrentChannel(m_updateLogicalChannel);
      m_tracking = m_updateTrackBeacon;
      m_beaconInterval = ((uint32_t) 1 << m_beaconOrder) * (uint32_t) IEEE154_aBaseSuperframeDuration; 
      m_dt = m_beaconInterval;
      m_numBeaconsLost = IEEE154_aMaxLostBeacons;  // will be reset when beacon is received
    }
    trackNextBeacon();
  }

  async event void TokenTransferred.transferred()
  {
    dbg_serial("BeaconSynchronizeP","Token.transferred(), expecting beacon in %lu symbols.\n",
        (uint32_t) ((m_lastBeaconRxTime + m_dt) - call TrackAlarm.getNow())); 
    if (call IsTokenRequested.getNow()) {
      // some other component needs the token - we give it up for now,  
      // but make another request to get it back later
      dbg_serial("BeaconSynchronizeP", "Token is requested, releasing it now.\n");
      call Token.request();
      call Token.release();
    } else if (m_updatePending)
      post signalGrantedTask();
    else
      trackNextBeacon();
  }


  task void signalGrantedTask()
  {
    signal Token.granted();
  }

  void trackNextBeacon()
  {
    bool missed = FALSE;

    if (m_state != S_INITIAL_SCAN) {
      // we have received at least one previous beacon
      m_state = S_PREPARE;
      if (!m_tracking) {
        // nothing to do, just give up the token
        dbg_serial("BeaconSynchronizeP", "Stop tracking.\n");
        call Token.release();
        return;
      }
      while (call TimeCalc.hasExpired(m_lastBeaconRxTime, m_dt)) { // missed a beacon!
        dbg_serial("BeaconSynchronizeP", "Missed a beacon, expected it: %lu, now: %lu\n", 
            m_lastBeaconRxTime + m_dt, call TrackAlarm.getNow());
        missed = TRUE;
        m_dt += m_beaconInterval;
        m_numBeaconsLost++;
      }
      if (m_numBeaconsLost >= IEEE154_aMaxLostBeacons) {
        dbg_serial("BeaconSynchronizeP", "Missed too many beacons.\n");
        post processBeaconTask();
        return;
      }
      if (missed) {
        // let other components get a chance to use the radio
        call Token.request();
        dbg_serial("BeaconSynchronizeP", "Allowing other components to get the token.\n");
        call Token.release();
        return;
      }
    }
    if (call RadioOff.isOff())
      signal RadioOff.offDone();
    else
      ASSERT(call RadioOff.off() == SUCCESS);
  }

  async event void RadioOff.offDone()
  {
    uint32_t delay = IEEE154_RADIO_RX_DELAY + IEEE154_MAX_BEACON_JITTER(m_beaconOrder);

    if (m_state == S_INITIAL_SCAN) {
      // initial scan
      call BeaconRx.enableRx(0, 0);
    } else if (m_state == S_PREPARE) {
      if (!call TimeCalc.hasExpired(m_lastBeaconRxTime - delay, m_dt))
        call TrackAlarm.startAt(m_lastBeaconRxTime - delay, m_dt);
      else
        signal TrackAlarm.fired();
    } else {
      post processBeaconTask();
    }
  }

  async event void BeaconRx.enableRxDone()
  {
    switch (m_state)
    {
      case S_INITIAL_SCAN: 
        m_state = S_RECEIVING;
        call TrackAlarm.start((((uint32_t) 1 << m_beaconOrder) + (uint32_t) 1) * 
          (uint32_t) IEEE154_aBaseSuperframeDuration * (uint32_t) IEEE154_aMaxLostBeacons);
        break;
      case S_PREPARE:
        m_state = S_RECEIVING;
        dbg_serial("BeaconSynchronizeP","Rx enabled, expecting beacon in %lu symbols.\n",
            (uint32_t) ((m_lastBeaconRxTime + m_dt) - call TrackAlarm.getNow())); 
        call TrackAlarm.startAt(m_lastBeaconRxTime, m_dt + IEEE154_MAX_BEACON_LISTEN_TIME(m_beaconOrder));
        break;
      default:
        ASSERT(0);
        break;
    }
  }

  async event void TrackAlarm.fired()
  {
    if (m_state == S_PREPARE) {
      uint32_t maxBeaconJitter = IEEE154_MAX_BEACON_JITTER(m_beaconOrder);
      if (maxBeaconJitter > m_dt)
        maxBeaconJitter = m_dt; // receive immediately
      call BeaconRx.enableRx(m_lastBeaconRxTime, m_dt - maxBeaconJitter);
    } else {
      ASSERT(m_state == S_RECEIVING && call RadioOff.off() == SUCCESS); 
    }
  }

  event message_t* BeaconRx.received(message_t *frame, const ieee154_timestamp_t *timestamp)
  {
    if (m_bufferBusy || !call FrameUtility.isBeaconFromCoord(frame))
    {
      if (m_bufferBusy) {
        dbg_serial("BeaconSynchronizeP", "Got another beacon, dropping it.\n");}
      else
        dbg_serial("BeaconSynchronizeP", "Got a beacon, but not from my coordinator.\n");
      return frame;
    } else {
      message_t *tmp = m_beaconPtr;
      m_bufferBusy = TRUE;
      m_beaconPtr = frame;
      if (timestamp != NULL)
        memcpy(&m_lastBeaconRxRefTime, timestamp, sizeof(ieee154_timestamp_t));
      if (m_state == S_RECEIVING) { 
        call TrackAlarm.stop(); // may fail
        call RadioOff.off();    // may fail
      }
      return tmp;
    }
  }

  task void processBeaconTask()
  {
    // if we received a beacon from our coordinator then it is processed now
    if (!m_bufferBusy || !call Frame.isTimestampValid(m_beaconPtr)) {
      // missed a beacon or received a beacon with invalid timestamp
      if (!m_bufferBusy)
        dbg_serial("BeaconSynchronizeP", "No beacon received!\n");
      else
        dbg_serial("BeaconSynchronizeP", "Beacon has invalid timestamp!\n");

      m_numBeaconsLost += 1;
      m_dt += m_beaconInterval;
      m_bufferBusy = FALSE;

      if (m_numBeaconsLost >= IEEE154_aMaxLostBeacons) {
        // lost too many beacons, give up!
        m_tracking = FALSE;
        dbg_serial("BeaconSynchronizeP", "MLME_SYNC_LOSS!\n");
        signal MLME_SYNC_LOSS.indication(
              IEEE154_BEACON_LOSS, 
              call MLME_GET.macPANId(),
              call MLME_GET.phyCurrentChannel(),
              call MLME_GET.phyCurrentPage(), 
              NULL);
      } else
        call Token.request(); // make another request again (before giving the token up)

      call Token.release();
    } else { 
      // got the beacon!
      uint8_t *payload = (uint8_t *) m_beaconPtr->data;
      ieee154_macAutoRequest_t autoRequest = call MLME_GET.macAutoRequest();
      uint8_t pendAddrSpecOffset = 3 + (((payload[2] & 7) > 0) ? 1 + (payload[2] & 7) * 3: 0); // skip GTS
      uint8_t pendAddrSpec = payload[pendAddrSpecOffset];
      uint8_t *beaconPayload = payload + pendAddrSpecOffset + 1;
      uint8_t beaconPayloadSize = call BeaconFrame.getBeaconPayloadLength(m_beaconPtr);
      uint8_t pendingAddrMode = ADDR_MODE_NOT_PRESENT;
      uint8_t coordBeaconOrder;
      uint8_t *mhr = MHR(m_beaconPtr);
      uint8_t frameLen = ((uint8_t*) m_beaconPtr)[0] & FRAMECTL_LENGTH_MASK;
      uint8_t gtsFieldLength;
      uint32_t timestamp = call Frame.getTimestamp(m_beaconPtr);

      dbg_serial("BeaconSynchronizeP", "Got beacon, timestamp: %lu, offset to previous: %lu\n", 
        (uint32_t) timestamp, (uint32_t) (timestamp - m_lastBeaconRxTime));

      m_numGtsSlots = (payload[2] & 7);
      gtsFieldLength = 1 + ((m_numGtsSlots > 0) ? 1 + m_numGtsSlots * 3: 0);
      m_lastBeaconRxTime = timestamp;
      m_numCapSlots = (payload[1] & 0x0F) + 1;
      m_sfSlotDuration = (((uint32_t) 1) << ((payload[0] & 0xF0) >> 4)) * IEEE154_aBaseSlotDuration;
      memcpy(m_gtsField, &payload[2], gtsFieldLength);

      // check for battery life extension
      if (payload[1] & 0x10) {
        // BLE is active; calculate the time offset from slot0
        m_battLifeExtDuration = IEEE154_SHR_DURATION + frameLen * IEEE154_SYMBOLS_PER_OCTET;
        if (frameLen > IEEE154_aMaxSIFSFrameSize)
          m_battLifeExtDuration += call MLME_GET.macMinLIFSPeriod();
        else
          m_battLifeExtDuration += call MLME_GET.macMinSIFSPeriod();
        m_battLifeExtDuration = m_battLifeExtDuration + call MLME_GET.macBattLifeExtPeriods() * 20;
      } else
        m_battLifeExtDuration = 0;

      m_framePendingBit = mhr[MHR_INDEX_FC1] & FC1_FRAME_PENDING ? TRUE : FALSE;
      coordBeaconOrder = (payload[0] & 0x0F); 
      m_dt = m_beaconInterval = ((uint32_t) 1 << coordBeaconOrder) * (uint32_t) IEEE154_aBaseSuperframeDuration; 

      if (m_stopTracking) {
        m_tracking = FALSE;
        dbg_serial("BeaconSynchronizeP", "Stop tracking.\n");
        if (m_updatePending) // there is already a new request ...
          call Token.request();
        call Token.release();
      } else {
        dbg_serial("BeaconSynchronizeP", "Handing over to CAP.\n");
        call TokenToCap.transfer(); 
      }
      
      if (pendAddrSpec & PENDING_ADDRESS_SHORT_MASK)
        beaconPayload += (pendAddrSpec & PENDING_ADDRESS_SHORT_MASK) * 2;
      if (pendAddrSpec & PENDING_ADDRESS_EXT_MASK)
        beaconPayload += ((pendAddrSpec & PENDING_ADDRESS_EXT_MASK) >> 4) * 8;

      // check for pending data (once we signal MLME_BEACON_NOTIFY we cannot
      // touch this frame anymore!)
      if (autoRequest)
        pendingAddrMode = call BeaconFrame.isLocalAddrPending(m_beaconPtr);
      if (pendingAddrMode != ADDR_MODE_NOT_PRESENT) {
        // the coord has pending data
        uint8_t CoordAddrMode;
        uint16_t CoordPANId;
        uint8_t *CoordAddress;
        uint8_t SrcAddrMode = pendingAddrMode;
        if ((mhr[MHR_INDEX_FC2] & FC2_SRC_MODE_MASK) == FC2_SRC_MODE_SHORT)
          CoordAddrMode = ADDR_MODE_SHORT_ADDRESS;
        else
          CoordAddrMode = ADDR_MODE_EXTENDED_ADDRESS;
        CoordAddress = &(mhr[MHR_INDEX_ADDRESS+2]);
        CoordPANId = *((nxle_uint16_t*) &(mhr[MHR_INDEX_ADDRESS]));
        call DataRequest.poll(CoordAddrMode, CoordPANId, CoordAddress, SrcAddrMode);
      }

      // Beacon Tracking: update state
      m_numBeaconsLost = 0;
      // TODO: check PAN ID conflict here?
      if (!autoRequest || beaconPayloadSize)
        m_beaconPtr = signal MLME_BEACON_NOTIFY.indication(m_beaconPtr);
      m_bufferBusy = FALSE;
    }
    dbg_serial_flush();
  }

  command error_t TrackSingleBeacon.start()
  {
    // Track a single beacon now
    if (!m_tracking && !m_updatePending && !call Token.isOwner()) {
      // find a single beacon now (treat this like a user request)
      m_updateLogicalChannel = call MLME_GET.phyCurrentChannel();
      m_updateTrackBeacon = FALSE;
      m_stopTracking = TRUE;
      m_updatePending = TRUE;
      call Token.request();
    }
    return SUCCESS;
  }

  command error_t TrackSingleBeacon.stop()
  {
    // will stop automatically after beacon was tracked/not found
    return FAIL;
  }
  
  /* -----------------------  SF Structure, etc. ----------------------- */

  async command uint32_t IncomingSF.sfStartTime()
  { 
    return m_lastBeaconRxTime; 
  }

  async command uint16_t IncomingSF.sfSlotDuration()
  { 
    return m_sfSlotDuration;
  }

  async command uint8_t IncomingSF.numCapSlots()
  {
    return m_numCapSlots;
  }

  async command uint8_t IncomingSF.numGtsSlots()
  {
    return m_numGtsSlots;
  }

  async command uint16_t IncomingSF.battLifeExtDuration()
  {
    return m_battLifeExtDuration;
  }

  async command const uint8_t* IncomingSF.gtsFields()
  {
    return m_gtsField;
  }

  async command uint16_t IncomingSF.guardTime()
  {
    return IEEE154_MAX_BEACON_JITTER(m_beaconOrder) + IEEE154_RADIO_RX_DELAY;
  }

  async command const ieee154_timestamp_t* IncomingSF.sfStartTimeRef()
  {
    return &m_lastBeaconRxRefTime;
  }

  async command bool IncomingSF.isBroadcastPending()
  {
    return m_framePendingBit;
  }

  async command bool IsTrackingBeacons.getNow()
  { 
    return m_tracking;
  }

  event void DataRequest.pollDone() {}

  default event message_t* MLME_BEACON_NOTIFY.indication (message_t* frame) {return frame;}
  default event void MLME_SYNC_LOSS.indication (
                          ieee154_status_t lossReason,
                          uint16_t panID,
                          uint8_t logicalChannel,
                          uint8_t channelPage,
                          ieee154_security_t *security) {}

  event message_t* CoordRealignmentRx.received(message_t* frame)
  {
    uint8_t *payload = call Frame.getPayload(frame);
    ieee154_macPANId_t panID = *(nxle_uint16_t*) &payload[1];
    if (panID == call MLME_GET.macPANId())
        signal MLME_SYNC_LOSS.indication(
          IEEE154_REALIGNMENT,   // LossReason
          panID,                 // PANId
          payload[5],            // LogicalChannel,
          call Frame.getPayloadLength(frame) == 9 ? payload[8] : call MLME_GET.phyCurrentPage(),
          NULL);
    return frame;
  }
}
