/**
 * Copyright (c) 2015, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:T
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
 *
 * Code fragements have been taken from tkn154/ScanP components of Jan Hauer.
 *
 * @author Jasper Buesch <buesch@tkn.tu-berlin.de>
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 */

#include "tkntsch_types.h"
#include "plain154_values.h"
#include "plain154_message_structs.h"

#ifdef NEW_PRINTF_SEMANTICS
#include "printf.h"
#else
#define printf(...)
#define printfflush()
#endif

/*
This module is responsible for scanning and
directly interacting with the radio.
*/

module TknTschScanP {
  provides {

    interface TknTschMlmeBeaconNotify;
    interface TknTschMlmeScan;
    interface Init;
    interface McuPowerOverride;

  } uses {
    interface McuPowerState;
    interface Plain154PhyTx<TSymbol,uint32_t> as PhyTx;
    interface Plain154PhyRx<TSymbol,uint32_t> as PhyRx;
    interface Plain154PhyOff;

    interface Alarm<T32khz,uint32_t> as ScanTimer;  // TSymbolIEEE802154

    interface Packet;
    interface Plain154Frame as Frame;
    interface Plain154Metadata as Metadata;

    interface TransferableResource as RadioToken;

    interface Plain154PlmeGet;
    interface Plain154PlmeSet;
    interface TknTschMlmeGet;
    interface TknTschMlmeSet;

    interface TknTschInformationElement;

    // TODO: We should consider using the Arbiter Interface here to
    // organize usage of the radio resource in a proper way
  }

} implementation {

  #define T32786_FROM_T62500(x) ((x*10)/19)
  #define T32786_TO_T62500(x) ((x*19)/10)

  // TODO (Jasper): Move the following in a better place..
  #define MAX_PAYLOAD_SIZE 10
  #define LAST_CHANNEL 26
  #define INVALID_CHANNEL_BITMASK 0xFC000000L
  // ------

  message_t m_receivedBeacon;
  norace bool m_rx_msg_lock;
  norace bool m_busy;
  uint8_t m_payload[MAX_PAYLOAD_SIZE];
  uint8_t m_scanType;
  uint32_t m_scanChannels;
  uint8_t m_currentChannelNum;
  bool m_terminateScan;
  bool m_cancelScan;
  void* m_resultList;
  uint8_t m_resultListNumEntries;
  uint8_t m_resultIndex;
  uint32_t m_scanDuration;
  plain154_macPANId_t m_PANID;
  uint8_t m_newScanStarted;

  void continueScanRequest();
  void nextIteration();
  void updateState();

  task void enableRadio();
  task void startTimerTask();
  task void nextIterationTask();
  task void forwardBeacon();
  task void continueScanRequestTask();

  // ---------------------------------------------------------------------



  command error_t Init.init()
  {
    atomic m_busy = FALSE;
    m_rx_msg_lock = FALSE;
    return SUCCESS;
  }

  async command mcu_power_t McuPowerOverride.lowestState() {
    if (m_busy)
      return JN516_POWER_DOZE;
    else
      return JN516_POWER_DEEP_SLEEP;
  }

  command plain154_status_t TknTschMlmeScan.cancel() {
    atomic {
      if (!m_busy) {
        return FAIL;
      } else {
        if (call RadioToken.isOwner())
          call Plain154PhyOff.off();
        else
          return FAIL;
        call ScanTimer.stop();
        m_cancelScan = TRUE;
        m_terminateScan = TRUE;
        call Plain154PhyOff.off();
      }
      return SUCCESS;
    }
  }


  command tkntsch_status_t TknTschMlmeScan.request  (
                          uint8_t  ScanType,
                          uint32_t ScanChannels,
                          uint8_t  ScanDuration,
                          uint8_t  ChannelPage,
                          uint8_t  PANDescriptorListNumEntries,
                          plain154_PANDescriptor_t* PANDescriptorList,
                          plain154_security_t *security
                        )
  {
    tkntsch_status_t status;
    //plain154_phyChannelsSupported_t supportedChannels = call Plain154PlmeGet.phyChannelsSupported();

    if (m_busy) {
      status = PLAIN154_SCAN_IN_PROGRESS;
      return status;
    } else if (security && security->SecurityLevel) {
      status = PLAIN154_UNSUPPORTED_SECURITY;
      return status;
    }
    if ((ScanType != 2) || ((ScanType < 3) && (ScanDuration > 14)) || (ChannelPage != 0)) {
      status = PLAIN154_INVALID_PARAMETER;
      return status;
    }
    atomic {
      m_busy = TRUE;
      call McuPowerState.update();
      m_scanType = ScanType;
      m_scanChannels = ScanChannels;
      m_scanDuration = (((uint32_t) 1 << ScanDuration) + 1) * PLAIN154_aBaseSuperframeDuration;
      m_PANID = call TknTschMlmeGet.macPanId();
      m_currentChannelNum = 0;
      m_terminateScan = FALSE;
      m_cancelScan = FALSE;
      m_resultIndex = 0;
      m_resultList = PANDescriptorList;
      m_resultListNumEntries = PANDescriptorListNumEntries;
      m_newScanStarted = TRUE;
      if (m_resultList == NULL)
        m_resultListNumEntries = 0;
    }

    // if macAutoRequest is TRUE and the PANDescriptorList is not valid -> non-sense
    if ((call TknTschMlmeGet.macAutoRequest()) && (m_resultListNumEntries == 0)) {
      return TKNTSCH_INVALID_PARAMETER;
    }

    call RadioToken.request();
    //return status;
    return SUCCESS;
  }



  event void RadioToken.granted()
  {
     continueScanRequest();
  }

  task void continueScanRequestTask()
  {
    continueScanRequest();
  }

  void continueScanRequest()
  {
    //uint8_t i;
    plain154_macPANId_t bcastPANID = 0xFFFF;
    //plain154_macDSN_t dsn = call TknTschMlmeGet.macDSN();

    if (!m_busy) {
      call RadioToken.release();
      return;
    }
    call TknTschMlmeSet.macPanId(bcastPANID);
    nextIteration();
  }

  void nextIteration()
  {
    uint8_t currentChannelNum;
    uint8_t resultIndex;
    bool terminateScan;
    plain154_phyChannelsSupported_t supportedChannels;
    uint32_t currentChannelBit;
    bool autorequest;

    atomic {
      supportedChannels = call Plain154PlmeGet.phyChannelsSupported();
      currentChannelBit = (uint32_t) 1 << m_currentChannelNum;
      currentChannelNum = m_currentChannelNum;
      terminateScan = m_terminateScan;
      resultIndex = m_resultIndex;
    }

    if (!terminateScan){
      while (currentChannelNum <= LAST_CHANNEL &&
          !(m_scanChannels & currentChannelBit & supportedChannels)){
        currentChannelNum++;
        currentChannelBit <<= 1;
      }
    }

    if ((currentChannelNum <= LAST_CHANNEL) && !terminateScan) {
      // scan the next channel
      call Plain154PlmeSet.phyCurrentChannel(currentChannelNum);
      atomic m_newScanStarted = TRUE;
      post enableRadio();
    } else { // we're done
      plain154_status_t result = PLAIN154_SUCCESS;
      uint32_t unscannedChannels = 0;
      call ScanTimer.stop();
      if (call RadioToken.isOwner())
        call RadioToken.release();
      if (m_cancelScan) {
        result = PLAIN154_USER_ABORTED;
      } else if (terminateScan){
        // Scan operation terminated because the max. number of PAN descriptors/ED samples was reached.
        // Check if there are channels that were unscanned. In active/passive scan we consider a channel
        // unscanned if it was not completely scanned.
        currentChannelBit >>= 1; // last (partially) scanned channel
        while (!(currentChannelBit & INVALID_CHANNEL_BITMASK) &&
               (m_scanChannels & currentChannelBit)){
          unscannedChannels |= currentChannelBit;
          currentChannelBit <<= 1;
        }
        if (unscannedChannels)  {// some channels were not (completely) scanned
          result = PLAIN154_LIMIT_REACHED;
        }
      } else if (!resultIndex) {
        result = PLAIN154_NO_BEACON;
      }

      call TknTschMlmeSet.macPanId(m_PANID);

      atomic {
        m_busy = FALSE;
        call McuPowerState.update();
        autorequest = call TknTschMlmeGet.macAutoRequest();
      }
      signal TknTschMlmeScan.confirm (
          result,
          m_scanType,
          PLAIN154_SUPPORTED_CHANNELPAGE,
          unscannedChannels,
          autorequest ? resultIndex : 0,
          autorequest ? (plain154_PANDescriptor_t*) m_resultList : NULL);
    }
    atomic m_currentChannelNum = currentChannelNum;
  }



  async event message_t* PhyRx.received(message_t *frame) {
    plain154_header_t* hdr;
    plain154_metadata_t* meta;
    uint8_t* payload;

    if (!m_busy)
      return frame;

    atomic {
    if (m_rx_msg_lock)
      // We have still an old beacon stored. We will neglect the new one for now.
      return frame; //TODO: Handle correctly
    }

    hdr = call Frame.getHeader(frame);
    meta = call Metadata.getMetadata(frame);
    payload = call Packet.getPayload(frame, call Packet.maxPayloadLength());

    if (call Frame.getFrameType(hdr) == PLAIN154_FRAMETYPE_BEACON) {
      // PASSIVE_SCAN:
      // A beacon frame containing a non-empty payload is always signalled
      // to the next higher layer (regardless of the value of macAutoRequest);
      // when macAutoRequest is set to TRUE, then the beacon is always
      // stored in the PAN Descriptor list (see 7.1.11.2.1 - Table 68)

      if (!(call TknTschMlmeGet.macAutoRequest())) {
        atomic m_rx_msg_lock = TRUE;
        memcpy(&m_receivedBeacon, frame, sizeof(message_t));
        post forwardBeacon();
        return frame;

      } else if (m_resultIndex >= m_resultListNumEntries) {
        m_terminateScan = TRUE;
        //call ScanTimer.stop();
        //call PhyRx.off();  // Jasper: calling PhyRx.off would cause the module - and the clock - to stop
        // and this would compromise the time reference we deliver to the upper layer..
        // thus we need to keep it active until the upper layer can synchronize to those time stamps

      } else {
        uint8_t i;
        plain154_PANDescriptor_t* descriptor = (plain154_PANDescriptor_t*) m_resultList;

        descriptor[m_resultIndex].CoordAddrMode = call Frame.getSrcAddrMode(hdr);
        if (call Frame.getSrcAddr(hdr, &(descriptor[m_resultIndex].CoordAddress)) != SUCCESS) {
          post enableRadio();
          return frame;
        }
        if (call Frame.getSrcPANId(hdr, &(descriptor[m_resultIndex].CoordPANId)) != SUCCESS) {
          descriptor[m_resultIndex].CoordPANIdPresent = FALSE;
        }

        // TODO: Fill the channel page! (is that necessary anyhow?!)
        // TODO: Link quality?

        // check uniqueness: PAN ID and source address must
        // not be found in a previously received beacon
        for (i=0; i<m_resultIndex; i++)
          if (descriptor[i].CoordPANId == descriptor[m_resultIndex].CoordPANId &&
              descriptor[i].CoordAddrMode == descriptor[m_resultIndex].CoordAddrMode)
            if ((descriptor[i].CoordAddrMode == PLAIN154_ADDR_SHORT &&
                  descriptor[i].CoordAddress.shortAddress ==
                  descriptor[m_resultIndex].CoordAddress.shortAddress) ||
                (descriptor[i].CoordAddrMode == PLAIN154_ADDR_EXTENDED &&
                 descriptor[i].CoordAddress.extendedAddress ==
                 descriptor[m_resultIndex].CoordAddress.extendedAddress))
              break; // not unique
        if (i == m_resultIndex) {
          uint8_t beaconJoinPriority;
          tkntsch_asn_t beaconASN;
          typeIE_t frameIE;

          if ((meta->valid_timestamp == FALSE) ||  (meta->timestamp == 0))
            post enableRadio();
            return frame;

          descriptor[m_resultIndex].TimeStamp = meta->timestamp;

          if (call Frame.isIEListPresent(hdr) == FALSE) {
            post enableRadio();
            return frame;
          }

          // TODO: Fix the payload length
          if (call TknTschInformationElement.presentPIEs(payload, 80, &frameIE) != TKNTSCH_SUCCESS) {
            if (call TknTschInformationElement.parseMlmeSync( frameIE.syncIEfrom, &beaconASN, &beaconJoinPriority, NULL) != SUCCESS) {
              post enableRadio();
              return frame;
            }
            post enableRadio();
            return frame;
          }

          descriptor[m_resultIndex].ASN = beaconASN;

          m_resultIndex++; // was unique
        } else {
          post enableRadio();
          return frame;
        }
      }
      memcpy(&m_receivedBeacon, frame, sizeof(message_t));
      post forwardBeacon();
    } //  PASSIVE_SCAN
    else {
      post enableRadio();
    }
    return frame;
  }

  task void enableRadio() {
    error_t radioStatus;

    radioStatus = call PhyRx.enableRx(0, 0);

    if (radioStatus != SUCCESS) {
      printf("ScanP: Re-enabling the radio failed.\n");
      post enableRadio();
    }
  }

  async event void PhyRx.enableRxDone()
  {
    if (!m_busy)
      return;
    if (m_newScanStarted == TRUE) {
      post startTimerTask();
      m_newScanStarted = FALSE;
    }
  }



  task void startTimerTask()
  {
    call ScanTimer.start(T32786_FROM_T62500(m_scanDuration));
  }



  async event void ScanTimer.fired()
  {
    if (!m_busy)
      return;
    if (call RadioToken.isOwner())
      call Plain154PhyOff.off();
  }



  async event void Plain154PhyOff.offDone()
  {
    if (!m_busy)
      return;
    if (m_currentChannelNum == 0)  // first round
      post continueScanRequestTask();
    else {
      m_currentChannelNum++;
      post nextIterationTask();
    }
  }



  task void nextIterationTask() {
    nextIteration();
  }



  task void forwardBeacon() {
    signal TknTschMlmeBeaconNotify.indication ( // TODO: Fill and transfer the correct values
                          &m_receivedBeacon );
    atomic m_rx_msg_lock = FALSE;
    post enableRadio();
  }



  async event void PhyTx.transmitDone(plain154_txframe_t *frame, error_t result){
    if (!m_busy)
      return;
    // TODO: handle this correctly
  }



  async event void RadioToken.transferredFrom(uint8_t srcClient) {}


  default event message_t* TknTschMlmeBeaconNotify.indication(message_t* beaconFrame) {
    return beaconFrame;
  }


  default event void TknTschMlmeScan.confirm(
      plain154_status_t status,
      uint8_t  ScanType,
      uint8_t  ChannelPage,
      uint32_t UnscannedChannels,
      uint8_t  PANDescriptorListNumResults,
      plain154_PANDescriptor_t* PANDescriptorList
    ) {}

}
