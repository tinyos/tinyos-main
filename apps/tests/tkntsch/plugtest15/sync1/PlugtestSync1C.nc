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
 * @author Moksha Birk <birk@tkn.tu-berlin.de>
 */

/**
 * TODO
 **/

#include "Timer.h"
//#include "Timer62500hz.h"
#include "TimerSymbol.h"

#ifdef NEW_PRINTF_SEMANTICS
#include "printf.h"
#else
#define printf(...)
#define printfflush()
#endif

#ifndef APP_RADIO_CHANNEL
#define APP_RADIO_CHANNEL RADIO_CHANNEL
#endif

#include "app_profile.h"

#include "plain154_message_structs.h"
#include "plain154_values.h"

module PlugtestSync1C
{
  uses {
    interface Timer<TMilli> as Timer0;
    interface Timer<TMilli> as Timer1;
    interface Boot;

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
    interface Plain154PhyTx<TSymbol,uint32_t> as PhyTx;

    interface TknTschMlmeScan as MLME_SCAN;
    interface TknTschMcpsData as MCPS_DATA;
    interface Pool<message_t> as RxMsgPool @safe();

    interface TknTschInformationElement;
    interface TknTschFrames;
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
  // constants

  // Prototypes
  void task startTsch();
  void task startScan();


  // Interface commands and events
  event void Boot.booted()
  {
    bool is_coordinator;

    printf("PlugtestSync1C booted.\n");
    printf("Set PAN ID to: 0x%.2X, result: %d\n", PAN_ID, call MLME_SET.macPanId(PAN_ID));
    printf("Set short address to: 0x%.4X, result: %d\n", COORDINATOR_ADDRESS, call MLME_SET.macShortAddr(COORDINATOR_ADDRESS));

    call PLME_SET.phyCurrentChannel(APP_RADIO_CHANNEL);
    call TknTschInit.init();

#ifdef IS_COORDINATOR
    printf("This node is a coordinator!\n");
    is_coordinator = TRUE;
    call MLME_SET.isCoordinator(is_coordinator);
    post startTsch();
#else
    printf("Normal node.\n");
    post startScan();
    is_coordinator = FALSE;
    call MLME_SET.isCoordinator(is_coordinator);
#endif

    printfflush();
  }


  void task startTsch() {
    call TschMode.request(TKNTSCH_MODE_ON);
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
      printf("Scan was requested successfully.\n");
    } else if (status == PLAIN154_INVALID_PARAMETER) {
      printf("There was an invalid parameter in the scan request.\n");
    }
  }


  event void TschMode.confirm(tkntsch_mode_t TSCHMode, tkntsch_status_t Status) {
    printf("Received event TschMode.confirm with status 0x%x\n", Status);
    call Timer1.startOneShot(2048);
#ifdef IS_COORDINATOR
    call Timer0.startOneShot(1024);
#endif
  }


  event message_t* MLME_BEACON_NOTIFY.indication  (
                        message_t* beaconFrame
                      ){
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

    /* Here the beacon can be imediatly processed.
    But for now we don't want to do that... */

    header = call Frame.getHeader(beaconFrame);
    metadata = call Metadata.getMetadata(beaconFrame);
    payloadLen = call PacketPayload.payloadLength(beaconFrame);
    payload = call PacketPayload.getPayload(beaconFrame, payloadLen);

    // TODO: Fix the 70 here
    if (call TknTschInformationElement.presentPIEs(payload, 70, &frameIE) != TKNTSCH_SUCCESS) {
      printf("Rx Beacon: IE parsing failed.\n");
      return beaconFrame;
    }

    if (frameIE.syncIEpresent == FALSE) {
      printf("Rx Beacon: no sync info included\n");
      return beaconFrame;
    }

    if (call Frame.getSrcAddrMode(header) == PLAIN154_ADDR_EXTENDED) {
      call Frame.getSrcAddr(header, &addr);
      if (call Frame.getFrameType(header) == PLAIN154_FRAMETYPE_BEACON) {
        if (call TknTschInformationElement.parseMlmeSync( frameIE.syncIEfrom, &beaconASN, &beaconJoinPriority, NULL) == SUCCESS) {
          if (metadata->valid_timestamp) {
            if (!m_scanRunning) {
              atomic printf("MLME_BEACON_NOTIFY.indication (ASN: %u, prio: %u)\n", (uint32_t) beaconASN, beaconJoinPriority);
            } else {
              m_synchronized = TRUE;
              m_beaconReception = metadata->timestamp;
              call MLME_SET.macASN(beaconASN);
              call MLME_SET.macBeaconSyncRxTimestamp(m_beaconReception);
              coordAddress = addr;
              call MLME_SET.macTimeParent(addr);
              call MLME_SCAN.cancel();
              m_scanRunning = FALSE;
              printf("BeaconASN: %u \n", (uint32_t) beaconASN);
              printf("BeaconJoin: %u\n", beaconJoinPriority);
            }
          } else {
            printf("Parsing the MLME SYNC wasn't successful.\n");
            return beaconFrame;
          }
        }
      } 
    }
    return beaconFrame;
  }

  event void Timer1.fired() {
    uint8_t ret;

    atomic printf("MCPS_DATA.request\n");
    ret = call MCPS_DATA.request (
        PLAIN154_ADDR_EXTENDED,
        PLAIN154_ADDR_EXTENDED,
        0xaabb,
        &coordAddress,
        &m_dataFrame,
        0,
        1,
        0, 0, 0, 0
      );
    if (ret != TKNTSCH_SUCCESS) {
      //call Timer1.startOneShot(1024*10);
      //printf("\nMCPS_DATA.request returned: 0x%x\n", ret);
    }
  }

  event void Timer0.fired() {
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
      call Timer0.startOneShot(1024);
      printf("MLME_BEACON.request (0x%x)\n", ret);
    }
  }

  event void MLME_BEACON.confirm(plain154_status_t Status) {
    printf("MLME_BEACON.confirm (status 0x%x)\n", Status);
    call Timer0.startOneShot(1024);
  }

  event void MLME_SCAN.confirm    (
                        plain154_status_t status,
                        uint8_t  ScanType,
                        uint8_t  ChannelPage,
                        uint32_t UnscannedChannels,
                        uint8_t  PANDescriptorListNumResults,
                        plain154_PANDescriptor_t* PANDescriptorList
                      ){
    printf("MLME_SCAN.confirm: Scan finished.\n");
    printfflush();
    call Timer1.startOneShot(1024*3);
    if (!m_synchronized) {
      printf("No EBeacon received... Restarting scanning now.\n");
      post startScan();
    } else {
      post startTsch();
    }

  }


  async event void PhyTx.transmitDone(plain154_txframe_t *frame, error_t result)  {}


  event void MCPS_DATA.confirm(
      uint8_t msduHandle,
      plain154_status_t status
    )
  {
    atomic printf("MCPS_DATA.confirm (handle 0x%x, status 0x%x)\n", msduHandle, status);
    call Timer1.startOneShot(1024*5);
  }


  event void MCPS_DATA.indication(
      message_t* msg,
      uint8_t mpduLinkQuality,
      uint8_t SecurityLevel,
      uint8_t KeyIdMode,
      plain154_sec_keysource_t KeySource,
      uint8_t KeyIndex
    )
  {
    int i;
    plain154_header_t* header;
    header = call Frame.getHeader(msg);

    atomic printf("Rx DATA frame (DSN %.2X)\n", call Frame.getDSN(header));
    for (i = 0; i < sizeof(message_t); i++) {
      printf("%.2X ", ((uint8_t*) msg)[i]);
    }
    printf("\n");

    atomic call RxMsgPool.put(msg);

  }
}
