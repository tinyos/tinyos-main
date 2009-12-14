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
 * $Revision: 1.11 $
 * $Date: 2009-12-14 12:50:06 $
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
    interface SplitControl as TrackSingleBeacon;
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
    interface TransferableResource as RadioToken;
    interface TimeCalc;
    interface IEEE154Frame as Frame;
    interface Leds;
  }
}
implementation
{
  /* state variables */
  norace uint8_t m_state;
  norace uint8_t m_numBeaconsMissed;

  /* temporary buffers for the MLME-SYNC parameters */
  uint8_t m_updateLogicalChannel;
  bool m_updateTrackBeacon;

  /* variables that describe the current beacon configuration */
  norace ieee154_macBeaconOrder_t m_beaconOrder;
  norace uint32_t m_dt;
  norace uint32_t m_lastBeaconRxTime;
  norace ieee154_timestamp_t m_lastBeaconRxRefTime;
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
    RX_PREPARE = 0x00,
    RX_RECEIVING = 0x01,
    RX_RADIO_OFF = 0x02,
    RX_FIRST_SCAN= 0x03,
    RX_MASK = 0x03,

    MODE_INACTIVE = 0x00,
    MODE_TRACK_SINGLE = 0x04,
    MODE_TRACK_CONTINUOUS = 0x08,
    MODE_MASK = 0x0C,

    BEACON_RECEIVED = 0x10,
    UPDATE_PENDING = 0x20,
    INTERNAL_REQUEST = 0x40,
    EXTERNAL_REQUEST = 0x80,
  };

  /* function/task prototypes */
  void trackNextBeacon();
  uint32_t getBeaconInterval(ieee154_macBeaconOrder_t BO);
  task void processBeaconTask();
  task void signalGrantedTask();

  /* accessing/manipulating the current state */
  void setBeaconReceived() { m_state |= BEACON_RECEIVED; }
  void resetBeaconReceived() { m_state &= ~BEACON_RECEIVED; }
  bool wasBeaconReceived() { return (m_state & BEACON_RECEIVED) ? TRUE : FALSE; }
  void setUpdatePending() { m_state |= UPDATE_PENDING; }
  void resetUpdatePending() { m_state &= ~UPDATE_PENDING; }
  bool isUpdatePending() { return (m_state & UPDATE_PENDING) ? TRUE : FALSE; }
  void setInternalRequest() { m_state |= INTERNAL_REQUEST; }
  void resetInternalRequest() { m_state &= ~INTERNAL_REQUEST; }
  bool isInternalRequest() { return (m_state & INTERNAL_REQUEST) ? TRUE : FALSE; }
  void setExternalRequest() { m_state |= EXTERNAL_REQUEST; }
  void resetExternalRequest() { m_state &= ~EXTERNAL_REQUEST; }
  bool isExternalRequest() { return (m_state & EXTERNAL_REQUEST) ? TRUE : FALSE; }
  uint8_t getMode() { return (m_state & MODE_MASK); }
  void setMode(uint8_t mode) { m_state &= ~MODE_MASK; m_state |= (mode & MODE_MASK); }
  uint8_t getRxState() { return (m_state & RX_MASK); }
  void setRxState(uint8_t state) { m_state &= ~RX_MASK; m_state |= (state & RX_MASK); }  
  
  command error_t Reset.init()
  {
    // Reset this component - will only be called while we're not owning the token
    if (call IsTrackingBeacons.getNow() || 
        (isUpdatePending() && isExternalRequest() && m_updateTrackBeacon))
      signal MLME_SYNC_LOSS.indication(
          IEEE154_BEACON_LOSS,
          call MLME_GET.macPANId(),
          call MLME_GET.phyCurrentChannel(),
          call MLME_GET.phyCurrentPage(),
          NULL);
    if (isInternalRequest())
      signal TrackSingleBeacon.startDone(FAIL);
    resetUpdatePending();
    resetInternalRequest();
    resetExternalRequest();
    setMode(MODE_INACTIVE); 
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
      m_updateTrackBeacon = trackBeacon;
      m_updateLogicalChannel = logicalChannel;
      setExternalRequest();
      setUpdatePending();
      call RadioToken.request();
    }

    dbg_serial("BeaconSynchronizeP", "MLME_SYNC.request -> result: %lu\n", (uint32_t) status);
    return status;
  }

  event void RadioToken.granted()
  {
    if (isUpdatePending()) {
      dbg_serial("BeaconSynchronizeP", "Updating configuration...\n"); 
      if (m_updateTrackBeacon)
        setMode(MODE_TRACK_CONTINUOUS);
      else
        setMode(MODE_TRACK_SINGLE);
      call MLME_SET.phyCurrentChannel(m_updateLogicalChannel);
      m_beaconOrder = call MLME_GET.macBeaconOrder();
      m_dt = getBeaconInterval(m_beaconOrder);
      m_numBeaconsMissed = IEEE154_aMaxLostBeacons;  // will be reset when first beacon is received
      resetUpdatePending();
      setRxState(RX_FIRST_SCAN);
    } 
    trackNextBeacon();
  }

  async event void RadioToken.transferredFrom(uint8_t clientFrom)
  {
    dbg_serial("BeaconSynchronizeP", "Got token (transferred).\n");
    if (isUpdatePending())
      post signalGrantedTask();
    else
      trackNextBeacon();
  }

  task void signalGrantedTask()
  {
    signal RadioToken.granted();
  }

  void trackNextBeacon()
  {
    bool missed = FALSE;

    if (getMode() == MODE_INACTIVE) {
      // nothing to do, just give up the token
      dbg_serial("BeaconSynchronizeP", "Stop tracking.\n");
      call RadioToken.release();
      return;
    }

    if (getRxState() != RX_FIRST_SCAN) {

      dbg_serial("BeaconSynchronizeP","Token.transferred(), expecting beacon in %lu symbols.\n",
        (uint32_t) ((m_lastBeaconRxTime + m_dt) - call TrackAlarm.getNow())); 

      // we have received at least one previous beacon, get ready for the next
      setRxState(RX_PREPARE);

      while (call TimeCalc.hasExpired(m_lastBeaconRxTime, m_dt)) { // missed a beacon!
        dbg_serial("BeaconSynchronizeP", "Missed a beacon, expected it: %lu, now: %lu\n", 
            m_lastBeaconRxTime + m_dt, call TrackAlarm.getNow());
        missed = TRUE;
        m_dt += getBeaconInterval(m_beaconOrder);
        m_numBeaconsMissed++;
      }

      if (m_numBeaconsMissed >= IEEE154_aMaxLostBeacons) {
        dbg_serial("BeaconSynchronizeP", "Missed too many beacons.\n");
        post processBeaconTask();
        return;
      }

      if (missed) {
        // let other components get a chance to use the radio
        call RadioToken.request();
        dbg_serial("BeaconSynchronizeP", "Skipping a beacon.\n");
        call RadioToken.release();
        return;
      }
    }

    if (call RadioOff.isOff())
      signal RadioOff.offDone();
    else if (call RadioOff.off() != SUCCESS) 
      ASSERT(0);
  }

  async event void RadioOff.offDone()
  {
    uint32_t delay = IEEE154_RADIO_RX_DELAY + IEEE154_MAX_BEACON_JITTER(m_beaconOrder);

    if (getRxState() == RX_FIRST_SCAN) {
      // initial scan: switch to Rx immediately
      call BeaconRx.enableRx(0, 0);
    } else if (getRxState() == RX_PREPARE) {
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
    uint32_t dt;
    uint8_t previousState = getRxState();

    setRxState(RX_RECEIVING);

    switch (previousState)
    {
      case RX_FIRST_SCAN: 
        // "To acquire beacon synchronization, a device shall enable its 
        // receiver and search for at most [aBaseSuperframeDuration * (2^n + 1)]
        // symbols, where n is the value of macBeaconOrder [...] Once the number
        // of missed beacons reaches aMaxLostBeacons, the MLME shall notify the 
        // next higher layer." (Sect. 7.5.4.1)
        dt = (((uint32_t) 1 << m_beaconOrder) + (uint32_t) 1) * 
          (uint32_t) IEEE154_aBaseSuperframeDuration * 
          (uint32_t) IEEE154_aMaxLostBeacons;
        call TrackAlarm.start(dt);
        dbg_serial("BeaconSynchronizeP","Rx enabled, expecting first beacon within next %lu symbols.\n", dt);
        break;
      case RX_PREPARE:
        dt = m_dt + IEEE154_MAX_BEACON_LISTEN_TIME(m_beaconOrder);
        call TrackAlarm.startAt(m_lastBeaconRxTime, dt);
        dbg_serial("BeaconSynchronizeP","Rx enabled, expecting beacon within next %lu symbols.\n",
            (uint32_t) ((m_lastBeaconRxTime + dt) - call TrackAlarm.getNow())); 
        break;
      default:
        ASSERT(0);
        break;
    }
  }

  async event void TrackAlarm.fired()
  {
    if (getRxState() == RX_PREPARE) { // enable Rx
      uint32_t maxBeaconJitter = IEEE154_MAX_BEACON_JITTER(m_beaconOrder);
      if (maxBeaconJitter > m_dt)
        maxBeaconJitter = m_dt; // receive immediately
      call BeaconRx.enableRx(m_lastBeaconRxTime, m_dt - maxBeaconJitter);
    } else { // disable Rx
      error_t error = call RadioOff.off();
      ASSERT(getRxState() == RX_RECEIVING && error == SUCCESS); 
    }
  }

  event message_t* BeaconRx.received(message_t *frame, const ieee154_timestamp_t *timestamp)
  {
    if (wasBeaconReceived()) {
      dbg_serial("BeaconSynchronizeP", "Got another beacon! -> ignoring it ...\n");
      return frame;
    } else if (!call FrameUtility.isBeaconFromCoord(frame)) {
      dbg_serial("BeaconSynchronizeP", "Got a beacon, but not from my coordinator.\n");
      return frame;
    } else {
      message_t *tmp = m_beaconPtr;
      setBeaconReceived();
      m_beaconPtr = frame;
      if (timestamp != NULL)
        memcpy(&m_lastBeaconRxRefTime, timestamp, sizeof(ieee154_timestamp_t));
      if (getRxState() == RX_RECEIVING) { 
        call TrackAlarm.stop(); // may fail
        call RadioOff.off();    // may fail
      }
      return tmp;
    }
  }



  task void processBeaconTask()
  {
    // task will be executed after every (un)successful attempt to track a beacon
    bool wasInternalRequest = isInternalRequest();
    
    if (wasBeaconReceived() && !call Frame.isTimestampValid(m_beaconPtr)) {
      dbg_serial("BeaconSynchronizeP", "Received beacon has invalid timestamp, discarding it!\n");
      resetBeaconReceived();
    }

    if (getMode() == MODE_TRACK_SINGLE)
      setMode(MODE_INACTIVE); // we're done with a single shot
    resetInternalRequest();

    // whether we next release the token or pass it to the CAP 
    // component, we want it back (because we decide later
    // whether we'll actually stop tracking the beacon in future)
    call RadioToken.request();  

    if (!wasBeaconReceived()) {

      resetBeaconReceived(); // buffer ready
      m_numBeaconsMissed += 1;
      m_dt += getBeaconInterval(m_beaconOrder);
      dbg_serial("BeaconSynchronizeP", "Missed a beacon (total missed: %lu).\n", (uint32_t) m_numBeaconsMissed);

      if (wasInternalRequest) {
        // note: if it only was an internal request, the
        // mode was reset above already (SINGLE_SHOT)
        signal TrackSingleBeacon.startDone(FAIL);
      } 
      if (isExternalRequest() && m_numBeaconsMissed >= IEEE154_aMaxLostBeacons) {
        resetExternalRequest();
        setMode(MODE_INACTIVE);
        dbg_serial("BeaconSynchronizeP", "MLME_SYNC_LOSS!\n");
        signal MLME_SYNC_LOSS.indication( 
            IEEE154_BEACON_LOSS, 
            call MLME_GET.macPANId(),
            call MLME_GET.phyCurrentChannel(),
            call MLME_GET.phyCurrentPage(), 
            NULL);
      }

      call RadioToken.release();
    
    } else { 
      // received the beacon!
      uint8_t *payload = (uint8_t *) m_beaconPtr->data;
      ieee154_macAutoRequest_t autoRequest = call MLME_GET.macAutoRequest();
      uint8_t pendAddrSpecOffset = 3 + (((payload[2] & 7) > 0) ? 1 + (payload[2] & 7) * 3: 0); // skip GTS
      uint8_t pendAddrSpec = payload[pendAddrSpecOffset];
      uint8_t *beaconPayload = payload + pendAddrSpecOffset + 1;
      uint8_t beaconPayloadSize = call BeaconFrame.getBeaconPayloadLength(m_beaconPtr);
      uint8_t pendingAddrMode = ADDR_MODE_NOT_PRESENT;
      uint8_t *mhr = MHR(m_beaconPtr);
      uint8_t frameLen = ((uint8_t*) m_beaconPtr)[0] & FRAMECTL_LENGTH_MASK;
      uint8_t gtsFieldLength;
      uint32_t timestamp = call Frame.getTimestamp(m_beaconPtr);

      dbg_serial("BeaconSynchronizeP", "Got beacon, timestamp: %lu, offset to previous: %lu\n", 
        (uint32_t) timestamp, (uint32_t) (timestamp - m_lastBeaconRxTime));

      m_numBeaconsMissed = 0;
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
      m_beaconOrder = (payload[0] & 0x0F); 
      m_dt = getBeaconInterval(m_beaconOrder);

      dbg_serial("BeaconSynchronizeP", "Handing over to CAP.\n");
      call RadioToken.transferTo(RADIO_CLIENT_DEVICECAP); 
      
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

      if (!autoRequest || beaconPayloadSize)
        m_beaconPtr = signal MLME_BEACON_NOTIFY.indication(m_beaconPtr);
      resetBeaconReceived(); // buffer ready
    }
    dbg_serial_flush();
  }

  command error_t TrackSingleBeacon.start()
  {
    // Track a single beacon now
    dbg_serial("BeaconSynchronizeP", "Internal request.\n");
    setInternalRequest();
    call RadioToken.request();
    if (!isUpdatePending()) {
      m_updateLogicalChannel = call MLME_GET.phyCurrentChannel();
      m_updateTrackBeacon = FALSE;
      setUpdatePending();
    }
    return SUCCESS;
  }

  command error_t TrackSingleBeacon.stop()
  {
    // we will stop automatically after beacon was tracked/not found
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
    return (getMode() == MODE_TRACK_CONTINUOUS);
  }

  uint32_t getBeaconInterval(ieee154_macBeaconOrder_t BO)
  {
    if (BO >= 15)
      BO = 14;
    return (((uint32_t) 1 << BO) * (uint32_t) IEEE154_aBaseSuperframeDuration);
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
