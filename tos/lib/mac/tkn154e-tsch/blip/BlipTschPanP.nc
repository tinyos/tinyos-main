/*
 * Copyright (c) 2015, Technische Universitaet Berlin
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
 * @author Moksha Birk <tinyos-code@tkn.tu-berlin.de>
 * @author Jasper Buesch <tinyos-code@tkn.tu-berlin.de>
 */

/**
 * TODO
 **/

#include "Timer.h"
//#include "Timer62500hz.h"

#include <lib6lowpan/ip.h>
#include "RPL.h"

#include "TknTschConfigLog.h"
//ifndef TKN_TSCH_LOG_ENABLED_TSSM_TX
//undef TKN_TSCH_LOG_ENABLED
//endif
#include "tkntsch_log.h"

/*#ifndef APP_RADIO_CHANNEL
#define APP_RADIO_CHANNEL RADIO_CHANNEL
#endif
*/

enum {
  RADIO_CHANNEL = 16,
  BEACON_ORDER = 8,
  SEARCH_CHANNELS = 1 << RADIO_CHANNEL,
};

#include "plain154_message_structs.h"
#include "plain154_values.h"

module BlipTschPanP
{
  provides {
    interface BlipTschPan;
  }
  uses {
    interface Timer<TMilli> as BeaconTimer;
    interface Timer<TMilli> as TimeParentTimer;

    // Frame handling
    interface Plain154Frame as Frame;
    interface Packet as PacketPayload;
    interface Plain154Metadata as Metadata;

    interface Init as TknTschInit;
    interface TknTschMlmeTschMode as TschMode;
    interface TknTschMlmeSet as MLME_SET;
    interface TknTschMlmeGet as MLME_GET;
    interface Plain154PlmeSet as PLME_SET;
    interface TknTschMlmeBeacon as MLME_BEACON;
    interface TknTschMlmeBeaconNotify as MLME_BEACON_NOTIFY;

    interface TknTschMlmeScan as MLME_SCAN;

    interface TknTschInformationElement;
    interface TknTschFrames;

    interface RPLOF;
  }
}
implementation
{

  // Variables
  bool m_synchronized = FALSE;
  uint32_t m_beaconReception;
  bool m_scanRunning = TRUE;

  plain154_address_t coordAddress;

  message_t m_dataFrame;
  bool m_isCoordinator;
  bool m_signalStatus;

  plain154_address_t m_timeParent;

  // constants

  // Prototypes
  void task startTsch();
  void task stopTsch();
  void task startScan();


  // Interface commands and events
  command error_t BlipTschPan.start()
  {
    T_LOG_INIT("BlipTschPan.start()\n");

    call PLME_SET.phyCurrentChannel(RADIO_CHANNEL);
    call TknTschInit.init();

    T_LOG_INIT("This node is a coordinator!\n");
    atomic m_isCoordinator = TRUE;
    atomic m_scanRunning = FALSE;
    call MLME_SET.isCoordinator(m_isCoordinator);
    post startTsch();
    call MLME_SET.macPanId(DEFINED_TOS_AM_GROUP);
    T_LOG_FLUSH;
    return SUCCESS;
  }

  command error_t BlipTschPan.join()
  {
    T_LOG_INIT("BlipTschPan.join()\n");

    call PLME_SET.phyCurrentChannel(RADIO_CHANNEL);
    call TknTschInit.init();

    T_LOG_INIT("Joining node.\n");
    atomic m_isCoordinator = FALSE;
    call MLME_SET.isCoordinator(m_isCoordinator);
    post startScan();

    T_LOG_FLUSH;
    return SUCCESS;
  }

  command error_t BlipTschPan.shutdown()
  {
    T_LOG_INFO("BlipTschPan.shutdown()\n");

    post stopTsch();

    T_LOG_FLUSH;
    return SUCCESS;
  }


  void task startTsch() {
    call TschMode.request(TKNTSCH_MODE_ON);
  }


  void task stopTsch() {
    // TODO is there anything else to do on shutdown?
    call TschMode.request(TKNTSCH_MODE_OFF);
  }


  void task startScan() {
    plain154_status_t status;
    status = call MLME_SCAN.request(
                          PASSIVE_SCAN, // uint8_t  ScanType,
                          SEARCH_CHANNELS, // uint32_t ScanChannels,0x001ffffe0
                          BEACON_ORDER, // uint8_t  ScanDuration,
                          0, // uint8_t  ChannelPage,
                          0, // uint8_t  PANDescriptorListNumEntries,
                          NULL, // plain154_PANDescriptor_t* PANDescriptorList,
                          NULL // plain154_security_t *security
                          );
    if (status == PLAIN154_SUCCESS) {
      T_LOG_INFO("Scan was requested successfully.\n");
    } else if (status == PLAIN154_INVALID_PARAMETER) {
      T_LOG_ERROR("There was an invalid parameter in the scan request.\n");
    }
  }


  task void signalJoinDone() {
      signal BlipTschPan.joinDone(m_signalStatus);
  }

  task void signalStartDone() {
      signal BlipTschPan.startDone(m_signalStatus);
  }

  task void signalShutdownDone() {
      signal BlipTschPan.shutdownDone(m_signalStatus);
  }

  event void TschMode.confirm(tkntsch_mode_t TSCHMode, tkntsch_status_t Status) {
    T_LOG_DEBUG("Received event TschMode.confirm with status 0x%x\n", Status);

    // start beacon sending if this is the coordinator
    // TODO beacons should be sent by all nodes
    if (m_isCoordinator == TRUE)
      call BeaconTimer.startOneShot(1024);

    m_signalStatus = Status;
    if (TSCHMode == TKNTSCH_MODE_ON) {
      if (m_isCoordinator == TRUE)
        post signalStartDone();
      else
        post signalJoinDone();
    }
    else {
      post signalShutdownDone();
    }
  }


  event message_t* MLME_BEACON_NOTIFY.indication  (
                        message_t* beaconFrame
                      ) {
    /* This function is only being called during the scan process, if macAutoRequest is set to FALSE */
    /* The content of this function is only for demonstrating purposes. To show how it could be used. */
    plain154_header_t* header;
    plain154_metadata_t* metadata;
    plain154_address_t addr;
    //uint8_t i;

    uint8_t* payload;
    uint8_t payloadLen;
    typeIE_t frameIE;
    //uint8_t headerLength;
    tkntsch_asn_t beaconASN;
    uint8_t beaconJoinPriority;
    uint16_t dstPanID;

    T_LOG_BLIP_RXTX_STATE("TknTschMlmeBeaconNotify.indication: received a beacon.\n");
    T_LOG_FLUSH;

    /* Here the beacon can be imediatly processed.
    But for now we don't want to do that... */

    header = call Frame.getHeader(beaconFrame);
    metadata = call Metadata.getMetadata(beaconFrame);
    payloadLen = call PacketPayload.payloadLength(beaconFrame);
    payload = call PacketPayload.getPayload(beaconFrame, payloadLen);

    if (call TknTschInformationElement.presentPIEs(payload, 70, &frameIE) != TKNTSCH_SUCCESS) {
      T_LOG_ERROR("IE parsing failed.\n");
      return beaconFrame;
    }

    if (frameIE.syncIEpresent == FALSE) {
      T_LOG_INFO("Recv. Beacon doesn't include sync info\n");
      return beaconFrame;
    }
    if (call Frame.getDstPANId(header, &dstPanID) != SUCCESS){
        return beaconFrame; // No src nor dest PAN
    }
    if (dstPanID != DEFINED_TOS_AM_GROUP) {
        T_LOG_INFO("Wrong PAN (%x != %x) \n", dstPanID, DEFINED_TOS_AM_GROUP);
        return beaconFrame;  // src PAN there but the wrong
      }

    if (call Frame.getSrcAddrMode(header) != PLAIN154_ADDR_EXTENDED)
      return beaconFrame;

    call Frame.getSrcAddr(header, &addr);
    if (call Frame.getFrameType(header) != PLAIN154_FRAMETYPE_BEACON)
      return beaconFrame;

    if (call TknTschInformationElement.parseMlmeSync( frameIE.syncIEfrom, &beaconASN, &beaconJoinPriority, NULL) != SUCCESS) {
      T_LOG_INFO("Parsing the MLME SYNC wasn't successful.\n");
      return beaconFrame;
    }

    if (!metadata->valid_timestamp)
      return beaconFrame;

    atomic T_LOG_INFO("BCN_NTFY.ind (%x:%x:%x:%x:%x:%x:%x:%x)(A: %u, pr: %u, lqi: %u)\n",(uint8_t)(((uint8_t *)(&addr.extendedAddress))[0]),(uint8_t)(((uint8_t *)(&addr.extendedAddress))[1]),(uint8_t)(((uint8_t *)(&addr.extendedAddress))[2]),(uint8_t)(((uint8_t *)(&addr.extendedAddress))[3]),(uint8_t)(((uint8_t *)(&addr.extendedAddress))[4]),(uint8_t)(((uint8_t *)(&addr.extendedAddress))[5]),(uint8_t)(((uint8_t *)(&addr.extendedAddress))[6]),(uint8_t)(((uint8_t *)(&addr.extendedAddress))[7]), (uint32_t) beaconASN, beaconJoinPriority, metadata->lqi);

    if (m_scanRunning) {
      uint8_t lqi = metadata->lqi;
      if (lqi < 10)
        return beaconFrame;

      m_synchronized = TRUE;
      m_beaconReception = metadata->timestamp;
      call MLME_SET.macASN(beaconASN);
      call MLME_SET.macJoinPriority(beaconJoinPriority + 1);
      call MLME_SET.macBeaconSyncRxTimestamp(m_beaconReception);
      call MLME_SET.macTimeParent(addr);
      memcpy((uint8_t *) &m_timeParent, (uint8_t *) &addr.extendedAddress, 8);
      T_LOG_INFO("BeaconASN: %u \n", (uint32_t) beaconASN);
      T_LOG_INFO("BeaconJoin: %u\n", beaconJoinPriority);
    }
    return beaconFrame;
  }


  event void BeaconTimer.fired() {
    plain154_address_t dstaddr;
    uint8_t ret;

    dstaddr.shortAddress = 0xFFFF;
    ret = call MLME_BEACON.request (
        TKNTSCH_BEACON_TYPE_BEACON,
        0, // channel
        0, // channel page
        NULL, // security
        PLAIN154_ADDR_SHORT, // dst mode
        &dstaddr,
        FALSE // BSN suppresion
      );

    if (ret != TKNTSCH_SUCCESS) {
      call BeaconTimer.startOneShot(1024 * 5);
      T_LOG_DEBUG("MLME_BEACON.request returned: 0x%x\n", ret);
    }
  }


  event void MLME_SCAN.confirm    (
                        plain154_status_t status,
                        uint8_t  ScanType,
                        uint8_t  ChannelPage,
                        uint32_t UnscannedChannels,
                        uint8_t  PANDescriptorListNumResults,
                        plain154_PANDescriptor_t* PANDescriptorList
                      ){
    T_LOG_INFO("MLME_SCAN.confirm: Scan finished.\n");
    T_LOG_FLUSH;

    if (!m_synchronized) {
      T_LOG_INFO("No EBeacon received... Restarting scanning now.\n");
      post startScan();
    } else {
      // start the TSSM
      m_scanRunning = FALSE;
      call MLME_SET.macPanId(DEFINED_TOS_AM_GROUP);
      post startTsch();
      call TimeParentTimer.startOneShot(1024 * 10);
      call BeaconTimer.startOneShot(1024 * 5);
    }
  }

  event void TimeParentTimer.fired() {
    struct in6_addr *parent;

    parent = call RPLOF.getParent();
    if (parent != NULL) {
      if ( (((parent->s6_addr[8]) ^ 2) != ((uint8_t *) &m_timeParent.extendedAddress)[0]) ||
          (memcmp((uint8_t *) &(parent->s6_addr[9]), &((uint8_t *) &m_timeParent.extendedAddress)[1], 7) != 0)) {
        memcpy((uint8_t *) &m_timeParent.extendedAddress, (uint8_t *) &(parent->s6_addr[8]), 8);
        ((uint8_t *) &m_timeParent.extendedAddress)[0] ^= 2;
        call MLME_SET.macTimeParent(m_timeParent);
#ifdef TKN_TSCH_LOG_INFO
        {
          uint8_t * p;
          p = (uint8_t *) &m_timeParent;
          T_LOG_INFO("TimeParent adjusted to changed RPL parent (0x%x 0x%x 0x%x 0x%x)\n", p[0], p[1], p[6], p[7]);
        }
#endif
      }
    } else {
      T_LOG_WARN("RPLParent not available for timeparent selection\n");
    }
    call TimeParentTimer.startOneShot(1024 * 10);
  }


  event void MLME_BEACON.confirm(plain154_status_t Status) {
    T_LOG_BLIP_RXTX_STATE("Received event MLME_BEACON.confirm with status 0x%x\n", Status);
    call BeaconTimer.startOneShot(6*1024);
  }
}
