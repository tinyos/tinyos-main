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
 * $Date: 2008-07-24 11:06:24 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */


#include "TKN154_MAC.h"
#include "TKN154_DEBUG.h"

module BeaconSynchronizeP
{
  provides
  {
    interface Init as Reset;
    interface MLME_SYNC;
    interface MLME_BEACON_NOTIFY;
    interface MLME_SYNC_LOSS;
    interface GetNow<bool> as IsTrackingBeacons;
    interface GetNow<uint32_t> as CapStart;
    interface GetNow<ieee154_reftime_t*> as CapStartRefTime; 
    interface GetNow<uint32_t> as CapLen;
    interface GetNow<uint32_t> as CapEnd;
    interface GetNow<uint32_t> as CfpEnd;
    interface GetNow<uint32_t> as CfpLen;
    interface GetNow<uint32_t> as BeaconInterval; 
    interface GetNow<bool> as IsBLEActive; 
    interface GetNow<uint16_t> as BLELen; 
    interface GetNow<uint8_t*> as GtsField;
    interface GetNow<uint32_t> as SfSlotDuration; 
    interface GetNow<uint8_t> as FinalCapSlot; 
    interface GetNow<uint8_t> as NumGtsSlots;
    interface GetNow<bool> as IsRxBroadcastPending; 
  }
  uses
  {
    interface MLME_GET;
    interface MLME_SET;
    interface FrameUtility;
    interface Notify<bool> as FindBeacon;
    interface IEEE154BeaconFrame as BeaconFrame;
    interface Alarm<TSymbolIEEE802154,uint32_t> as TrackAlarm;
    interface RadioRx as BeaconRx;
    interface RadioOff;
    interface Get<bool> as IsBeaconEnabledPAN;
    interface DataRequest;
    interface FrameRx as CoordRealignmentRx;
    interface Resource as Token;
    interface ResourceTransfer as TokenToCap;
    interface TimeCalc;
    interface IEEE154Frame as Frame;
    interface Leds;
    interface Ieee802154Debug as Debug;
  }
}
implementation
{

  enum {
    S_PREPARE = 0,
    S_RXNOW = 1,
    S_RADIO_OFF = 2,
    S_FIRST_SCAN= 3,

    RX_DURATION = 1000,    // listen for a beacon for RX_DURATION symbols
    RX_LAG = 100,          // start to listen for a RX_LAG before expected arrival
  };

  norace bool m_tracking = FALSE;
  bool m_updatePending = FALSE;
  uint8_t m_updateLogicalChannel;
  bool m_updateTrackBeacon;
  bool m_stopTracking = FALSE;
  bool m_internalRequest = FALSE;

  uint8_t m_numBeaconsLost;
  uint8_t m_coordAddress[8];
  message_t m_beaconBuffer;
  norace message_t *m_beaconBufferPtr = &m_beaconBuffer;
  norace bool m_beaconSwapBufferReady = TRUE;
  norace uint32_t m_beaconInterval;
  norace uint32_t m_dt;
  norace uint32_t m_lastBeaconRxTime;
  norace ieee154_reftime_t m_lastBeaconRxRefTime;
  norace uint8_t m_state;
  norace uint8_t m_beaconOrder;
  norace uint32_t m_sfSlotDuration;
  norace uint8_t m_finalCapSlot;
  norace uint8_t m_numGtsSlots;
  norace uint16_t m_BLELen;
  norace bool m_broadcastPending;
  uint8_t m_gtsField[1+1+3*7];
  task void processBeaconTask();

  command error_t Reset.init()
  {
    if (call Token.isOwner()){
      call Leds.led0On(); // internal error
      return FAIL;
    }    
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
 * Allows to synchronize with a coordinator.
 */

  command ieee154_status_t MLME_SYNC.request  (
      uint8_t logicalChannel,
      uint8_t channelPage,
      bool trackBeacon)
  {
    uint32_t supportedChannels = IEEE154_SUPPORTED_CHANNELS;
    uint32_t currentChannelBit = 1;

    currentChannelBit <<= logicalChannel;
    if (!(currentChannelBit & supportedChannels) || (call MLME_GET.macPANId() == 0xFFFF) ||
        (channelPage != IEEE154_SUPPORTED_CHANNELPAGE) || !call IsBeaconEnabledPAN.get())
      return IEEE154_INVALID_PARAMETER;

    call Debug.log(LEVEL_INFO,SyncP_REQUEST, logicalChannel, channelPage, trackBeacon);
    if (!trackBeacon && m_tracking){
      // stop tracking after next received beacon
      m_stopTracking = TRUE;
    } else {
      m_stopTracking = FALSE;
      m_updateLogicalChannel = logicalChannel;
      m_updateTrackBeacon = trackBeacon;
      m_updatePending = TRUE;
      m_internalRequest = FALSE;
      call Debug.log(LEVEL_INFO,SyncP_RESOURCE_REQUEST, 0, 0, 0);
      call Token.request();
    }
    call Debug.flush();
    return IEEE154_SUCCESS;
  }

  event void FindBeacon.notify( bool val )
  {
    if (!m_tracking && !m_updatePending){
      // find a single beacon now (treat this like a user request)
      m_updateLogicalChannel = call MLME_GET.phyCurrentChannel();
      m_updateTrackBeacon = FALSE;
      m_updatePending = TRUE;
      m_internalRequest = TRUE;
      call Token.request();
    }
  }

  event void Token.granted()
  {
    bool missed = FALSE;
    call Debug.flush();
    call Debug.log(LEVEL_INFO,SyncP_GOT_RESOURCE, m_lastBeaconRxTime+m_beaconInterval, 
        m_beaconInterval, (m_updatePending<<1)+m_tracking);
    if (m_updatePending){
      m_state = S_FIRST_SCAN;
      m_updatePending = FALSE;      
      m_beaconOrder = call MLME_GET.macBeaconOrder();
      if (m_beaconOrder >= 15)
        m_beaconOrder = 14;
      call MLME_SET.phyCurrentChannel(m_updateLogicalChannel);
      m_tracking = m_updateTrackBeacon;
      m_beaconInterval = ((uint32_t) 1 << m_beaconOrder) * (uint32_t) IEEE154_aBaseSuperframeDuration; 
      m_dt = m_beaconInterval;
      m_numBeaconsLost = IEEE154_aMaxLostBeacons;  // will be reset when beacon is received
      call Debug.log(LEVEL_INFO,SyncP_UPDATING, call MLME_GET.macCoordShortAddress(), 
          call MLME_GET.macPANId(), m_updateLogicalChannel);
    } else {
      m_state = S_PREPARE;
      if (!m_tracking){
        call Debug.log(LEVEL_INFO,SyncP_RELEASE_RESOURCE, 0, 0, 0);
        call Token.release();
        return;
      }
      while (call TimeCalc.hasExpired(m_lastBeaconRxTime, m_dt)){ // missed a beacon
        call Debug.log(LEVEL_INFO,SyncP_BEACON_MISSED_1, m_lastBeaconRxTime, m_dt, missed);
        m_dt += m_beaconInterval;
        m_numBeaconsLost++;
        missed = TRUE;
      }
      if (m_numBeaconsLost >= IEEE154_aMaxLostBeacons){
        post processBeaconTask();
        return;
      }
      if (missed){
        call Token.request();
        call Debug.log(LEVEL_INFO,SyncP_RELEASE_RESOURCE, m_lastBeaconRxTime, m_dt, missed);
        call Token.release();
        return;
      }
    }
    if (!call RadioOff.isOff())
      call RadioOff.off();
    else
      signal RadioOff.offDone();
  }

  async event void TrackAlarm.fired()
  {
    call Debug.log(LEVEL_IMPORTANT,SyncP_TRACK_ALARM, m_state,m_lastBeaconRxTime,m_dt);
    atomic {
      switch (m_state)
      {
        case S_PREPARE:
          call BeaconRx.prepare();
          break;
        case S_RADIO_OFF: 
          call RadioOff.off(); 
          break;
      }
    }
  }

  async event void BeaconRx.prepareDone()
  {
    error_t result;
    if (m_state == S_FIRST_SCAN){
      m_state = S_RADIO_OFF;
      atomic {
        call BeaconRx.receive(NULL, 0);
        call TrackAlarm.start((((uint32_t) 1 << m_beaconOrder) + (uint32_t) 1) * 
            (uint32_t) IEEE154_aBaseSuperframeDuration * (uint32_t) IEEE154_aMaxLostBeacons);
      }
    } else {
      m_state = S_RADIO_OFF;
      result = call BeaconRx.receive(&m_lastBeaconRxRefTime, m_dt-RX_LAG);
      call Debug.log(LEVEL_IMPORTANT,SyncP_RX_ON, m_lastBeaconRxTime, call TrackAlarm.getNow(), m_dt+RX_DURATION);
      if (result != SUCCESS)
        call Debug.log(LEVEL_IMPORTANT,SyncP_RADIO_BUSY, result, 0, 0);
      call TrackAlarm.startAt(m_lastBeaconRxTime, m_dt + RX_DURATION);
    }
  }

  event message_t* BeaconRx.received(message_t *frame, ieee154_reftime_t *timestamp)
  {
    uint8_t *mhr = MHR(frame);
    call Debug.log(LEVEL_INFO,SyncP_RX_PACKET,*((nxle_uint32_t*) &mhr[MHR_INDEX_ADDRESS]), 
        mhr[MHR_INDEX_FC1] & FC1_FRAMETYPE_MASK,mhr[MHR_INDEX_SEQNO]);
    if (!m_beaconSwapBufferReady || !call FrameUtility.isBeaconFromCoord(frame))
    {
      call Debug.log(LEVEL_IMPORTANT,SyncP_RX_GARBAGE, m_beaconSwapBufferReady, 0, 0);
      return frame;
    } else {
      message_t *tmp = m_beaconBufferPtr;
      call TrackAlarm.stop();
      m_beaconSwapBufferReady = FALSE;
      m_beaconBufferPtr = frame;
      if (timestamp != NULL)
        memcpy(&m_lastBeaconRxRefTime, timestamp, sizeof(ieee154_reftime_t));
      call RadioOff.off();
      return tmp;
    }
  }

  async event void RadioOff.offDone()
  {
    if (m_state == S_FIRST_SCAN)
      call BeaconRx.prepare();
    else if (m_state == S_PREPARE)
      call TrackAlarm.startAt(m_lastBeaconRxTime, m_dt - IEEE154_RADIO_RX_PREPARE_DELAY);
    else
      post processBeaconTask();
  }

  task void processBeaconTask()
  {

    // valid beacon timestamp is pre-condition for slotted CSMA-CA
    if (m_beaconSwapBufferReady || !call Frame.isTimestampValid(m_beaconBufferPtr)){
      // missed a beacon!
      m_numBeaconsLost++;
      m_dt += m_beaconInterval;
      call Debug.log(LEVEL_IMPORTANT, SyncP_BEACON_MISSED_3,m_numBeaconsLost,0,m_lastBeaconRxTime);
      if (m_numBeaconsLost >= IEEE154_aMaxLostBeacons){
        m_tracking = FALSE;
        call Debug.log(LEVEL_IMPORTANT, SyncP_LOST_SYNC,0,0,0);
        call Leds.led2Off();
        if (m_internalRequest)
          call TokenToCap.transfer();
        else
          signal MLME_SYNC_LOSS.indication(
              IEEE154_BEACON_LOSS, 
              call MLME_GET.macPANId(),
              call MLME_GET.phyCurrentChannel(),
              call MLME_GET.phyCurrentPage(), 
              NULL // security
              );
      } else
        call Token.request(); // make another request again (before giving the token up)
      call Debug.log(LEVEL_INFO,SyncP_RELEASE_RESOURCE, 0, 0, 0);
      call Token.release();
    } else { 
      // got the beacon!
      uint8_t *payload = (uint8_t *) m_beaconBufferPtr->data;
      ieee154_macAutoRequest_t autoRequest = call MLME_GET.macAutoRequest();
      uint8_t pendAddrSpecOffset = 3 + (((payload[2] & 7) > 0) ? 1 + (payload[2] & 7) * 3: 0); // skip GTS
      uint8_t pendAddrSpec = payload[pendAddrSpecOffset];
      uint8_t *beaconPayload = payload + pendAddrSpecOffset + 1;
      uint8_t beaconPayloadSize = call BeaconFrame.getBeaconPayloadLength(m_beaconBufferPtr);
      uint8_t pendingAddrMode = ADDR_MODE_NOT_PRESENT;
      uint8_t coordBeaconOrder;
      uint8_t *mhr = MHR(m_beaconBufferPtr);
      uint8_t frameLen = ((uint8_t*) m_beaconBufferPtr)[0] & FRAMECTL_LENGTH_MASK;
      uint8_t gtsFieldLength;
      uint32_t timestamp = call Frame.getTimestamp(m_beaconBufferPtr);

      call Debug.log(LEVEL_INFO, SyncP_BEACON_RX, m_lastBeaconRxTime, timestamp, mhr[2]);
      m_numGtsSlots = (payload[2] & 7);
      gtsFieldLength = 1 + ((m_numGtsSlots > 0) ? 1 + m_numGtsSlots * 3: 0);
      m_lastBeaconRxTime = timestamp;
      m_finalCapSlot = (payload[1] & 0x0F);
      m_sfSlotDuration = (((uint32_t) 1) << ((payload[0] & 0xF0) >> 4)) * IEEE154_aBaseSlotDuration;
      memcpy(m_gtsField, &payload[2], gtsFieldLength);

      // check for battery life extension
      if (payload[1] & 0x10){
        // BLE is active; calculate the time offset from slot0
        m_BLELen = IEEE154_SHR_DURATION + frameLen * IEEE154_SYMBOLS_PER_OCTET;
        if (frameLen > IEEE154_aMaxSIFSFrameSize)
          m_BLELen += call MLME_GET.macMinLIFSPeriod();
        else
          m_BLELen += call MLME_GET.macMinSIFSPeriod();
        m_BLELen += call MLME_GET.macBattLifeExtPeriods();
      } else
        m_BLELen = 0;
      m_broadcastPending = mhr[MHR_INDEX_FC1] & FC1_FRAME_PENDING ? TRUE : FALSE;
      coordBeaconOrder = (payload[0] & 0x0F); 
      m_dt = m_beaconInterval = ((uint32_t) 1 << coordBeaconOrder) * (uint32_t) IEEE154_aBaseSuperframeDuration; 
      if (m_stopTracking){
        m_tracking = FALSE;
        call Debug.log(LEVEL_INFO,SyncP_RELEASE_RESOURCE, 0, 0, 0);
        call Token.release();
      } else {
        error_t req = call Token.request();
        call Debug.log(LEVEL_INFO,SyncP_TRANSFER_RESOURCE, req, 0, 0);
        call TokenToCap.transfer(); 
      }
      
      if (pendAddrSpec & PENDING_ADDRESS_SHORT_MASK)
        beaconPayload += (pendAddrSpec & PENDING_ADDRESS_SHORT_MASK) * 2;
      if (pendAddrSpec & PENDING_ADDRESS_EXT_MASK)
        beaconPayload += ((pendAddrSpec & PENDING_ADDRESS_EXT_MASK) >> 4) * 8;
      // check for pending data (once we signal MLME_BEACON_NOTIFY we cannot
      // touch the frame anymore)
      if (autoRequest)
        pendingAddrMode = call BeaconFrame.isLocalAddrPending(m_beaconBufferPtr);
      if (pendingAddrMode != ADDR_MODE_NOT_PRESENT){
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
      call Debug.log(LEVEL_INFO, SyncP_NEXT_RX_TIME, 0, timestamp, m_beaconInterval);
      m_numBeaconsLost = 0;
      // TODO: check PAN ID conflict here?
      if (!autoRequest || beaconPayloadSize)
        m_beaconBufferPtr = signal MLME_BEACON_NOTIFY.indication(m_beaconBufferPtr);
      m_beaconSwapBufferReady = TRUE;
    }
  }

  async command bool IsTrackingBeacons.getNow(){ return m_tracking;}

  default event message_t* MLME_BEACON_NOTIFY.indication (message_t* frame){return frame;}

  default event void MLME_SYNC_LOSS.indication (
                          ieee154_status_t lossReason,
                          uint16_t panID,
                          uint8_t logicalChannel,
                          uint8_t channelPage,
                          ieee154_security_t *security){}
  
  event void DataRequest.pollDone(){}

  async command uint8_t* GtsField.getNow() { return m_gtsField; }
  async command uint32_t SfSlotDuration.getNow() { return m_sfSlotDuration; }
  async command uint8_t FinalCapSlot.getNow() { return m_finalCapSlot; }
  async command uint32_t CapStart.getNow() { return m_lastBeaconRxTime; }
  async command ieee154_reftime_t* CapStartRefTime.getNow() { return &m_lastBeaconRxRefTime; }
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
  async command uint32_t BeaconInterval.getNow()
  {
    return m_beaconInterval;
  }
  async command uint8_t NumGtsSlots.getNow() { return m_numGtsSlots; }
  async command bool IsBLEActive.getNow(){ return m_BLELen>0;}
  async command uint16_t BLELen.getNow(){ return m_BLELen;}
  async command bool IsRxBroadcastPending.getNow() { return m_broadcastPending; }

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
          NULL
          );
    return frame;
  }
}
