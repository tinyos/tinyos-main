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
 * $Revision: 1.9 $
 * $Date: 2009-04-30 13:23:48 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 * This module is responsible for channel scanning.
 */

#include "TKN154_MAC.h"
module ScanP
{
  provides
  {
    interface Init;
    interface MLME_SCAN;
    interface MLME_BEACON_NOTIFY;
    interface GetNow<token_requested_t> as IsRadioTokenRequested;
  }
  uses
  {
    interface MLME_GET;
    interface MLME_SET;
    interface EnergyDetection;
    interface RadioOff;
    interface RadioRx;
    interface RadioTx;
    interface IEEE154Frame as Frame;
    interface IEEE154BeaconFrame as BeaconFrame;
    interface Timer<TSymbolIEEE802154> as ScanTimer;
    interface Pool<ieee154_txframe_t> as TxFramePool;
    interface Pool<ieee154_txcontrol_t> as TxControlPool;
    interface TransferableResource as RadioToken;
    interface FrameUtility;
    interface Leds;
  }
}
implementation
{
  enum {
    MAX_PAYLOAD_SIZE = 1,
    LAST_CHANNEL = 26,
  };
#define INVALID_CHANNEL_BITMASK 0xFC000000L

  ieee154_txframe_t *m_txFrame = NULL;
  uint8_t m_payload[MAX_PAYLOAD_SIZE];  
  uint8_t m_scanType;
  uint32_t m_scanChannels;
  norace uint8_t m_currentChannelNum;
  bool m_terminateScan;
  void* m_resultList;
  uint8_t m_resultListNumEntries;
  uint8_t m_resultIndex;
  ieee154_macPANId_t m_PANID;
  norace uint32_t m_scanDuration;
  norace bool m_busy = FALSE;

  void nextIteration();
  void continueScanRequest();
  task void startTimerTask();
  task void nextIterationTask();

  command error_t Init.init()
  {
    // triggered by MLME_RESET; Note: Init will not be called
    // while this component owns the RadioToken, so the worst case is 
    // that a MLME_SCAN was accepted (returned IEEE154_SUCCESS)  
    // but the RadioToken.granted() has not been signalled            
    if (m_busy) {
      m_terminateScan = TRUE;
      nextIteration(); // signals confirm and resets state
    }
    return SUCCESS;
  }

  /* ----------------------- MLME-SCAN ----------------------- */
  /* "The MLME-SCAN.request primitive is used to initiate a channel scan over a
   * given list of channels. A device can use a channel scan to measure the
   * energy on the channel, search for the coordinator with which it associated,
   * or search for all coordinators transmitting beacon frames within the POS of
   * the scanning device." (IEEE 802.15.4-2006 Sect. 7.1.11.1) 
   **/

  command ieee154_status_t MLME_SCAN.request  (
                          uint8_t ScanType,
                          uint32_t ScanChannels,
                          uint8_t ScanDuration,
                          uint8_t ChannelPage,
                          uint8_t EnergyDetectListNumEntries,
                          int8_t* EnergyDetectList,
                          uint8_t PANDescriptorListNumEntries,
                          ieee154_PANDescriptor_t* PANDescriptorList,
                          ieee154_security_t *security)
  {
    ieee154_status_t status = IEEE154_SUCCESS;
    ieee154_phyChannelsSupported_t supportedChannels = call MLME_GET.phyChannelsSupported();
    ieee154_txcontrol_t *txControl = NULL;

    if (m_busy) {
      status = IEEE154_SCAN_IN_PROGRESS;
    } else if (security && security->SecurityLevel) {
      status = IEEE154_UNSUPPORTED_SECURITY;
    } if ((ScanType > 3) || (ScanType < 3 && ScanDuration > 14) || 
        (ChannelPage != IEEE154_SUPPORTED_CHANNELPAGE) ||
        !(supportedChannels & ScanChannels) ||
        ((ScanType != ORPHAN_SCAN) &&
         ((EnergyDetectListNumEntries && PANDescriptorListNumEntries) ||
          (EnergyDetectList != NULL && PANDescriptorList != NULL) ||
          (EnergyDetectListNumEntries && EnergyDetectList == NULL) ||
          (PANDescriptorListNumEntries && PANDescriptorList == NULL)))) {
      status = IEEE154_INVALID_PARAMETER;
    } else if ((ScanType == ACTIVE_SCAN || ScanType == ORPHAN_SCAN) &&
        ((m_txFrame = call TxFramePool.get()) == NULL)) {
      status = IEEE154_TRANSACTION_OVERFLOW;
    } else if ((ScanType == ACTIVE_SCAN || ScanType == ORPHAN_SCAN) &&
        ((txControl = call TxControlPool.get()) == NULL)) { 
      call TxFramePool.put(m_txFrame);
      m_txFrame = NULL;
      status = IEEE154_TRANSACTION_OVERFLOW;
    } else {
      if (m_txFrame != NULL){
        m_txFrame->header = &txControl->header;
        m_txFrame->payload = m_payload;
        m_txFrame->metadata = &txControl->metadata;
      }
      m_busy = TRUE;
      m_scanType = ScanType;
      m_scanChannels = ScanChannels;
      m_scanDuration = (((uint32_t) 1 << ScanDuration) + 1) * IEEE154_aBaseSuperframeDuration;
      m_PANID = call MLME_GET.macPANId();
      m_currentChannelNum = 0;
      m_terminateScan = FALSE;
      m_resultIndex = 0;
      if (ScanType == ENERGY_DETECTION_SCAN) {
        m_resultList = EnergyDetectList;
        m_resultListNumEntries = EnergyDetectListNumEntries;
      } else {
        m_resultList = PANDescriptorList;
        m_resultListNumEntries = PANDescriptorListNumEntries;
      }
      if (m_resultList == NULL)
        m_resultListNumEntries = 0;
      call RadioToken.request();
    }
    dbg_serial("ScanP", "MLME_SCAN.request -> result: %lu\n", (uint32_t) status);
    return status;
  }

  event void RadioToken.granted()
  {
    if (call RadioOff.isOff())
      continueScanRequest();
    else 
      ASSERT(call RadioOff.off() == SUCCESS);
    // will continue in continueScanRequest()
  }

  task void continueScanRequestTask() 
  { 
    continueScanRequest(); 
  }

  void continueScanRequest()
  {
    uint8_t i;
    ieee154_macPANId_t bcastPANID = 0xFFFF;
    ieee154_macDSN_t dsn = call MLME_GET.macDSN();

    if (!m_busy) {
      call RadioToken.release();
      return;
    }
    switch (m_scanType) {
      case ACTIVE_SCAN:
        // beacon request frame
        m_txFrame->header->mhr[MHR_INDEX_FC1] = FC1_FRAMETYPE_CMD;
        m_txFrame->header->mhr[MHR_INDEX_FC2] = FC2_DEST_MODE_SHORT;
        m_txFrame->header->mhr[MHR_INDEX_SEQNO] = dsn;
        call MLME_SET.macDSN(dsn+1);
        for (i=0; i<4; i++) // broadcast dest PAN ID + broadcast dest addr
          m_txFrame->header->mhr[MHR_INDEX_ADDRESS + i] = 0xFF;    
        m_txFrame->headerLen = 7;
        m_payload[0] = CMD_FRAME_BEACON_REQUEST;
        m_txFrame->payloadLen = 1;
        // fall through
      case PASSIVE_SCAN:
        call MLME_SET.macPANId(bcastPANID);
        break;
      case ORPHAN_SCAN:
        // orphan notification frame
        m_scanDuration = call MLME_GET.macResponseWaitTime();
        m_txFrame->header->mhr[MHR_INDEX_FC1] = FC1_FRAMETYPE_CMD | FC1_PAN_ID_COMPRESSION;
        m_txFrame->header->mhr[MHR_INDEX_FC2] = FC2_SRC_MODE_EXTENDED | FC2_DEST_MODE_SHORT;
        m_txFrame->header->mhr[MHR_INDEX_SEQNO] = dsn;
        call MLME_SET.macDSN(dsn+1);
        for (i=0; i<4; i++) // broadcast dest PAN ID + broadcast dest addr
          m_txFrame->header->mhr[MHR_INDEX_ADDRESS + i] = 0xFF;
        call FrameUtility.copyLocalExtendedAddressLE((uint8_t*) &(m_txFrame->header[MHR_INDEX_ADDRESS + i]));
        m_txFrame->headerLen = 15;
        m_payload[0] = CMD_FRAME_ORPHAN_NOTIFICATION;
        m_txFrame->payloadLen = 1;
        break;
    }
    nextIteration();
  }

  void nextIteration()
  {
    ieee154_phyChannelsSupported_t supportedChannels = call MLME_GET.phyChannelsSupported();
    uint32_t currentChannelBit = (uint32_t) 1 << m_currentChannelNum;
    error_t radioStatus = SUCCESS;

    if (!m_terminateScan){
      while (m_currentChannelNum <= LAST_CHANNEL &&  
          !(m_scanChannels & currentChannelBit & supportedChannels)){
        m_currentChannelNum++;
        currentChannelBit <<= 1;
      }
    }

    if (m_currentChannelNum <= LAST_CHANNEL && !m_terminateScan) {
      // scan the next channel
      call MLME_SET.phyCurrentChannel(m_currentChannelNum);
      dbg_serial("ScanP", "Scanning channel %lu...\n", (uint32_t) m_currentChannelNum);
      switch (m_scanType) {
        case PASSIVE_SCAN:
          radioStatus = call RadioRx.enableRx(0, 0);
          break;
        case ACTIVE_SCAN: // fall through
        case ORPHAN_SCAN:
          radioStatus = call RadioTx.transmit(m_txFrame, NULL, 0);
          break;
        case ENERGY_DETECTION_SCAN:
          radioStatus = call EnergyDetection.start(m_scanDuration);
          break;
      }
      ASSERT(radioStatus == SUCCESS);
    } else {
      // we're done
      ieee154_status_t result = IEEE154_SUCCESS;
      uint32_t unscannedChannels = 0;

      if (m_terminateScan){
        // Scan operation terminated because the max. 
        // number of PAN descriptors/ED samples was reached.
        // Check if there are channels that were unscanned.
        // In active/passive scan we consider a channel 
        // unscanned if it was not completely scanned.
        if (m_scanType == PASSIVE_SCAN || m_scanType == ACTIVE_SCAN) 
          currentChannelBit >>= 1; // last (partially) scanned channel
        while (!(currentChannelBit & INVALID_CHANNEL_BITMASK) &&
               (m_scanChannels & currentChannelBit)){
          unscannedChannels |= currentChannelBit;
          currentChannelBit <<= 1;
        }
        if (unscannedChannels) // some channels were not (completely) scanned
          result = IEEE154_LIMIT_REACHED;
      } else if (m_scanType != ENERGY_DETECTION_SCAN && !m_resultIndex)
        result = IEEE154_NO_BEACON;

      if (m_scanType == PASSIVE_SCAN || m_scanType == ACTIVE_SCAN) 
        call MLME_SET.macPANId(m_PANID);
      if (m_txFrame != NULL) {
        call TxControlPool.put((ieee154_txcontrol_t*) ((uint8_t*) m_txFrame->header - offsetof(ieee154_txcontrol_t, header)));
        call TxFramePool.put(m_txFrame);
      }
      m_txFrame = NULL;
      if (call RadioToken.isOwner())
        call RadioToken.release();
      m_busy = FALSE;
      dbg_serial("ScanP", "MLME_SCAN.confirm()\n");
      signal MLME_SCAN.confirm (
          result,
          m_scanType,
          IEEE154_SUPPORTED_CHANNELPAGE,
          unscannedChannels,
          (m_scanType == ENERGY_DETECTION_SCAN) ? m_resultIndex : 0,
          (m_scanType == ENERGY_DETECTION_SCAN) ? (int8_t*) m_resultList : NULL,
          ((m_scanType == ACTIVE_SCAN ||
           m_scanType == PASSIVE_SCAN) && call MLME_GET.macAutoRequest()) ? m_resultIndex : 0,
          ((m_scanType == ACTIVE_SCAN ||
           m_scanType == PASSIVE_SCAN) && call MLME_GET.macAutoRequest()) ? (ieee154_PANDescriptor_t*) m_resultList : NULL);
    }
    dbg_serial_flush();
  }
  
  async event void RadioRx.enableRxDone()
  {
    post startTimerTask();
  }

  /* ----------------------- EnergyDetection ----------------------- */

  event void EnergyDetection.done(error_t status, int8_t EnergyLevel)
  {
    if (status == SUCCESS && m_resultListNumEntries)
      ((uint8_t*) m_resultList)[m_resultIndex++] = EnergyLevel;
    if (m_resultIndex == m_resultListNumEntries)
      m_terminateScan = TRUE; // done
    if (call RadioOff.off() == EALREADY)
      signal RadioOff.offDone();
  }

  /* ----------------------- Active/Orphan scan ----------------------- */
  
  async event void RadioTx.transmitDone(ieee154_txframe_t *frame, const ieee154_timestamp_t *timestamp, error_t result)
  {
    ASSERT(call RadioRx.enableRx(0, 0) == SUCCESS);
  }

  /* -------- Receive events (for  Active/Passive/Orphan scan) -------- */

  event message_t* RadioRx.received(message_t *frame, const ieee154_timestamp_t *timestamp)
  {
    if (!m_busy)
      return frame;
    if (m_scanType == ORPHAN_SCAN) {
      if (!m_resultIndex)
        if ((MHR(frame)[0] & FC1_FRAMETYPE_MASK) == FC1_FRAMETYPE_CMD &&
            ((uint8_t*)call Frame.getPayload(frame))[0] == CMD_FRAME_COORDINATOR_REALIGNMENT) {
          m_resultIndex++; 
          dbg_serial("ScanP", "Received coordinator realignment frame.\n");
          m_terminateScan = TRUE;
          call RadioOff.off();
        }
    } else if ((((ieee154_header_t*) frame->header)->mhr[0] & FC1_FRAMETYPE_MASK) == FC1_FRAMETYPE_BEACON) {
      //  PASSIVE_SCAN / ACTIVE_SCAN
      if (!call MLME_GET.macAutoRequest())
        return signal MLME_BEACON_NOTIFY.indication (frame);
      else if (m_resultIndex >= m_resultListNumEntries) {
        m_terminateScan = TRUE;
        call RadioOff.off();
      } else if (call BeaconFrame.parsePANDescriptor(
            frame, 
            m_currentChannelNum, 
            IEEE154_SUPPORTED_CHANNELPAGE,
            &((ieee154_PANDescriptor_t*) m_resultList)[m_resultIndex]) == SUCCESS) {

        // check uniqueness: both PAN ID and source address must not be in a previously received beacon
        uint8_t i;
        ieee154_PANDescriptor_t* descriptor = (ieee154_PANDescriptor_t*) m_resultList;

        dbg_serial("ScanP", "Received beacon, source: 0x%lx, channel: %lu.\n", 
            (uint32_t) descriptor[m_resultIndex].CoordAddress.shortAddress, (uint32_t) m_currentChannelNum);
        if (m_resultIndex)
          for (i=0; i<m_resultIndex; i++)
            if (descriptor[i].CoordPANId == descriptor[m_resultIndex].CoordPANId &&
                descriptor[i].CoordAddrMode == descriptor[m_resultIndex].CoordAddrMode)
              if ((descriptor[i].CoordAddrMode == ADDR_MODE_SHORT_ADDRESS &&
                    descriptor[i].CoordAddress.shortAddress ==
                    descriptor[m_resultIndex].CoordAddress.shortAddress) ||
                  (descriptor[i].CoordAddrMode == ADDR_MODE_EXTENDED_ADDRESS &&
                   descriptor[i].CoordAddress.extendedAddress ==
                   descriptor[m_resultIndex].CoordAddress.extendedAddress))
                return frame; // not unique
        m_resultIndex++; // was unique
      }
    } //  PASSIVE_SCAN / ACTIVE_SCAN
    return frame;
  }

  /* ----------------------- Common ----------------------- */

  task void startTimerTask() 
  { 
    call ScanTimer.startOneShot(m_scanDuration); 
  }

  event void ScanTimer.fired()
  {
    call RadioOff.off();
  }

  async event void RadioOff.offDone()
  {
    if (m_currentChannelNum == 0)
      post continueScanRequestTask();
    else {
      m_currentChannelNum++;    
      post nextIterationTask();
    }
  }

  task void nextIterationTask()
  {
    nextIteration();
  }

  async command token_requested_t IsRadioTokenRequested.getNow(){ return m_busy;}
  async event void RadioToken.transferredFrom(uint8_t id){ ASSERT(0);}
  default event message_t* MLME_BEACON_NOTIFY.indication (message_t *beaconFrame) {return beaconFrame;}
  default event void MLME_SCAN.confirm    (
                          ieee154_status_t status,
                          uint8_t ScanType,
                          uint8_t ChannelPage,
                          uint32_t UnscannedChannels,
                          uint8_t EnergyDetectListNumEntries,
                          int8_t* EnergyDetectList,
                          uint8_t PANDescriptorListNumEntries,
                          ieee154_PANDescriptor_t* PANDescriptorList) {}
}
