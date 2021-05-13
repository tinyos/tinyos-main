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
 */

#include "Timer.h"
#include "printf.h"
#include "app_profile.h"
#include "plain154_message_structs.h"
#include "plain154_values.h"
#include "plain154_phy_pib.h"

#include "tkntsch_pib.h"

module BeaconScanningC
{
  uses {
    interface Leds;
    interface Boot;

    interface Init as TknTschInit;


    interface TknTschMlmeGet;
    interface TknTschMlmeSet;
    interface TknTschMlmeScan;
    interface TknTschMlmeBeaconNotify;
    interface Packet as PacketPayload;
    interface Plain154Frame as Frame;
    interface Plain154PlmeSet;
    interface Plain154Metadata as Metadata;
    interface Plain154PhyTx<TMicro,uint32_t> as PhyTx;

    interface Alarm<T32khz, uint32_t>  as Alarm;

    interface TknTschInformationElement;
    interface TknTschFrames;
  }
} implementation {

  // Variables
  uint32_t m_rxTimestamp;
  message_t msg;
  plain154_txframe_t txFrame;
  bool m_synchronized = FALSE;

  message_t ackMsg;
  plain154_txframe_t ackTxFrame;

  plain154_PANDescriptor_t panDescriptors[PAN_DESCRIPTOR_LIST_ENTRIES];

  void task startScan();

  event void Boot.booted()
  {
    plain154_status_t status;
    plain154_address_t addr;
    uint8_t headerLength;
    memset(&msg, 0, sizeof(message_t));

    txFrame.header = call Frame.getHeader(&msg);
    txFrame.metadata = call Metadata.getMetadata(&msg);
    txFrame.payload = call PacketPayload.getPayload(&msg, 20);

    addr.shortAddress = 0xffee;
    if (SUCCESS != call Frame.setAddressingFields(txFrame.header,
              PLAIN154_ADDR_SHORT,
              PLAIN154_ADDR_NOT_PRESENT,
              0xc0fe,
              0x1ee7,
              &addr,
              &addr,
              PLAIN154_FRAMEVERSION_2,
              TRUE))

    call Frame.setDSN(txFrame.header, 0x99);
    call Frame.setFrameType(txFrame.header, PLAIN154_FRAMETYPE_BEACON);
    //call Frame.setFrameVersion(txFrame.header, PLAIN154_FRAMEVERSION_2);
    call Frame.setAckRequest(txFrame.header, FALSE);
    call Frame.setFramePending(txFrame.header, FALSE);
    call Frame.setIEListPresent(txFrame.header, TRUE);
    txFrame.header->hie[0] = 0x80;
    txFrame.header->hie[1] = 0x3e;
    call Frame.getActualHeaderLength(txFrame.header, &headerLength);
    txFrame.headerLen = headerLength;

    call Plain154PlmeSet.phyCurrentChannel(17);
    call TknTschInit.init();
    call TknTschMlmeSet.macAutoRequest(TRUE);

    printf("BeaconScanningC booted.\n");
    printf("Set PAN ID to: 0x%.2X, result: %d\n", PAN_ID, call TknTschMlmeSet.macPanId(PAN_ID));
    printf("Set short address to: 0x%.4X, result: %d\n", COORDINATOR_ADDRESS, call TknTschMlmeSet.macShortAddr(COORDINATOR_ADDRESS));

    printf("Everything set up and ready...\n");
    printfflush();

    printf("Request a passive channel scan on the following channels (channel bit mask): %x\n", SEARCH_CHANNELS);
    printfflush();

    post startScan();
  }


  void task startScan() {
    plain154_status_t status;
    status = call TknTschMlmeScan.request(
                          PASSIVE_SCAN, // uint8_t  ScanType,
                          SEARCH_CHANNELS, // uint32_t ScanChannels,0x001ffffe0
                          BEACON_ORDER, // uint8_t  ScanDuration,
                          0, // uint8_t  ChannelPage,
                          PAN_DESCRIPTOR_LIST_ENTRIES, // uint8_t  PANDescriptorListNumEntries,
                          panDescriptors, // plain154_PANDescriptor_t* PANDescriptorList,
                          NULL // plain154_security_t *security
                          );
    if (status == PLAIN154_SUCCESS) {
      printf("Scan was requested successfully.\n");
    } else if (status == PLAIN154_INVALID_PARAMETER) {
      printf("There was an invalid parameter in the scan request.\n");
    }
    printfflush();
  }


  event message_t* TknTschMlmeBeaconNotify.indication  (
                          message_t* beaconFrame
                        ){
    /* This function is only being called during the scan process, if macAutoRequest is set to FALSE */
    /* The content of this function is only for demonstrating purposes. To show how it could be used. */
    plain154_header_t* header;
    plain154_metadata_t* metadata;
    plain154_address_t addr;

    uint8_t i;

    uint8_t* payload;
    uint8_t payloadLen;
    typeIE_t frameIE;
    uint8_t headerLength;


    printf("TknTschMlmeBeaconNotify.indication: received a beacon.\n");

    /* Here the beacon can be imediatly processed.
    But for now we don't want to do that... */

    header = call Frame.getHeader(beaconFrame);
    metadata = call Metadata.getMetadata(beaconFrame);
    payloadLen = call PacketPayload.payloadLength(beaconFrame);
    payload = call PacketPayload.getPayload(beaconFrame, payloadLen);

    if (call TknTschInformationElement.presentPIEs(payload, 30, &frameIE) != TKNTSCH_SUCCESS)
      printf("The IE parsing FAILED? \n");

    printf("syncIEpresent(%d), slotframeIEpresent(%d), timeslotIEpresent(%d), hoppingIEpresent(%d)\n", frameIE.syncIEpresent, frameIE.slotframeIEpresent, frameIE.timeslotIEpresent, frameIE.hoppingIEpresent);
    // printf("Total IE (%d), total length (%d)\n", frameIE.totalIEs, frameIE.totalIEsLength);

    memset(&ackMsg, 0, sizeof(message_t));

    addr.extendedAddress = 0x1111222233334444;

    call TknTschFrames.createEnhancedAckFrame(&ackMsg, PLAIN154_ADDR_EXTENDED, &addr, 0x4819, -777);
    ackTxFrame.header = call Frame.getHeader(&ackMsg);
    ackTxFrame.metadata = call Metadata.getMetadata(&ackMsg);
    ackTxFrame.payload = call PacketPayload.getPayload(&ackMsg, 20);
    call Frame.getActualHeaderLength(ackTxFrame.header, &headerLength);
    ackTxFrame.headerLen = headerLength;
    ackTxFrame.payload = 0;

    /*
    if (m_synchronized == TRUE)
      return beaconFrame;

    if (call Frame.getSrcAddrMode(header) == PLAIN154_ADDR_EXTENDED) {
      call Frame.getSrcAddr(header, &addr);
      if (addr.extendedAddress == 0x1122334455667788) {
        if (call Frame.getFrameType(header) == PLAIN154_FRAMETYPE_BEACON) {
          if (metadata->valid_timestamp) {
            uint32_t delta;
            m_synchronized = TRUE;

            delta = call PhyTx.getNow();
            if (delta >= metadata->timestamp)
              delta = delta - metadata->timestamp;
            else
              delta = ~(metadata->timestamp - delta) + 1;
            m_rxTimestamp = call Alarm.getNow() - T32_FROM_US(delta);
          }
        }
      }
    }
    */
    return beaconFrame;
  }

  async event void PhyTx.transmitDone(plain154_txframe_t *frame, error_t result) {
    //call PhyTx.transmit(&ackTxFrame, call PhyTx.getNow(), 1000000);
    post startScan();
  }

  event void TknTschMlmeScan.confirm    (
                          plain154_status_t status,
                          uint8_t  ScanType,
                          uint8_t  ChannelPage,
                          uint32_t UnscannedChannels,
                          uint8_t  PANDescriptorListNumResults,
                          plain154_PANDescriptor_t* PANDescriptorList
                        ){
    uint8_t i;
    uint32_t now, timedelta;
    call Plain154PlmeSet.phyCurrentChannel(17);

    printf("Recoreded PANs: %d\n", PANDescriptorListNumResults);
    printfflush();
    for (i=0; i<PANDescriptorListNumResults; i++) {
      if (! PANDescriptorList[i].CoordPANIdPresent) {
        printf("There was no PAN ID included...\n");
      } else {
        printf("PAN: %x\n", PANDescriptorList[i].CoordPANId);
      }
      if (PANDescriptorList[i].CoordAddrMode == PLAIN154_ADDR_EXTENDED) {
          printf("Coord addr: %x\n", PANDescriptorList[i].CoordAddress.extendedAddress);
        } else {
          printf("Coord addr: %x\n", PANDescriptorList[i].CoordAddress.shortAddress);
        }
      if (PANDescriptorList[i].TimeStamp != 0) {
        uint32_t radioDelta, radioNow, radioRecordTime, systemNow, delay62500;

        m_synchronized = TRUE;
        radioRecordTime = PANDescriptorList[i].TimeStamp;
        radioNow = call PhyTx.getNow();
        systemNow = call Alarm.getNow();

        if (radioNow >= radioRecordTime)
          radioDelta = radioNow - radioRecordTime;
        else
          radioDelta = ~(radioRecordTime - radioNow) + 1;

        delay62500 = (33095 * 2) - ( T32_FROM_US(radioDelta) % 33095);

        call Alarm.start(delay62500);

/*
        printf("Received the beacon at %d\n", radioRecordTime);
        printf("The delta is %d\n", radioDelta);
        printf("In 32khz the delta is %d\n", T32_FROM_US(radioDelta));
        printf("Devided through 101 this is %d (%d)\n", T32_FROM_US(radioDelta) % 33095, (33095 - ( T32_FROM_US(radioDelta) % 33095) ));
        printfflush();


        printf("--------: %d\n", (33095 - ( T32_FROM_US(radioDelta) % 33095) ) );
*/
      } else {
        printf("The time stamp was invalid!\n");
      }
    }
    printf("\n Scan confirmed ( code: %d )\n", status);
    printfflush();
  }

  async event void Alarm.fired() {
    //call PhyTx.transmit(&txFrame, 0,0);
    //printf("Alarm.fired: TS %d\n", call PhyTx.getNow());
    if (call PhyTx.transmit(&ackTxFrame, call PhyTx.getNow(), 1200) != SUCCESS) {
      printf("BeaconScanning: Transmitting failed. Trying again later\n");
      call Alarm.start(3277);  // 100ms
    }
  }


}
