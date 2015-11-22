/**
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
 * @author Sonali Deo <deo@tkn.tu-berlin.de>
 */

#include "plain154_types.h"
#include "plain154_message_structs.h"
#include "message.h"
#include "plain154_values.h"
#include "tkntsch_lock.h"
#include "tkntsch_pib.h"
#include "tkntsch_types.h"
#include "tkntsch_ie.h"

#include "TknTschConfigLog.h"
//ifndef TKN_TSCH_LOG_ENABLED_FRAMES
//undef TKN_TSCH_LOG_ENABLED
//endif
#include "tkntsch_log.h"

/**
 * Provides creation and(or) parsing capabilities for these frames:
 * Enhanced Frames in compliance with IEEE Std 802.15.4e-2012
 *   5.2.2.1 Beacon frame format
 *   5.2.2.3 Acknowledgment frame format
 *
 * Short Frames in compliance with IEEE Std 802.15.4-2006
 *   7.2.2.2 Data frame format
 *   7.2.2.3 Acknowledgment frame format
 */





module TknTschFramesP {
  provides
  {
    interface TknTschFrames;
  }
  uses
  {
    interface TknTschInformationElement as IE;

    interface TknTschMlmeGet;
    interface TknTschPib;

    interface Plain154Frame as Frame;
    interface Plain154Metadata as Metadata;
    interface Packet as PacketPayload;
  }
}
implementation {


  command tkntsch_status_t TknTschFrames.createAckFrame(message_t* msg, uint8_t msglength) {
    bool framePending;
    uint8_t seqno;
    plain154_header_t* hdr;

    if(msg == NULL)
      return TKNTSCH_INVALID_PARAMETER;

    // TODO these values should be provided by arguments
    framePending = FALSE;
    seqno = 0x0a;

    hdr = call Frame.getHeader(msg);

    call Frame.setAddressingFields(hdr,
        PLAIN154_ADDR_NOT_PRESENT, // src addressing mode
        PLAIN154_ADDR_NOT_PRESENT, // dest addressing mode
        0, // src pan
        0, // dest pan
        NULL, // src address
        NULL, // dest address
        PLAIN154_FRAMEVERSION_1, // frame version
        FALSE // PAN ID Compression T/F
      );

    call Frame.setFrameType(hdr, PLAIN154_FRAMETYPE_ACK);
    call Frame.setFramePending(hdr, framePending);
    call Frame.setAckRequest(hdr, FALSE);
    call Frame.setIEListPresent(hdr, FALSE);
    call Frame.setDSN(hdr, seqno);

    return TKNTSCH_SUCCESS;
  }


  command tkntsch_status_t TknTschFrames.createEnhancedAckFrame(message_t* msg,
                                                                uint8_t dstAddrMode,
                                                                plain154_address_t* dstAddr,
                                                                uint16_t dstPanID,
                                                                int16_t timeCorrection,
                                                                bool ack) {

    plain154_header_t* hdr;
    tkntsch_status_t timeCorrectionIEStatus;
    uint8_t ieLen = 0;
    plain154_address_t addr;

    addr.extendedAddress = call TknTschMlmeGet.macExtAddr();

    if(msg == NULL || dstAddr == NULL)
      return TKNTSCH_INVALID_PARAMETER;

    hdr = call Frame.getHeader(msg);

    call Frame.setAddressingFields(hdr,
        PLAIN154_ADDR_EXTENDED,
        dstAddrMode,
        call TknTschMlmeGet.macPanId(),
        dstPanID,
        &addr,
        dstAddr,
        PLAIN154_FRAMEVERSION_2,
        FALSE
      );

    call Frame.setFrameType(hdr, PLAIN154_FRAMETYPE_ACK);
    call Frame.setDSN(hdr, call TknTschMlmeGet.macDSN());
    call Frame.setIEListPresent(hdr, TRUE);

    timeCorrectionIEStatus = call IE.createTimeCorrection((uint8_t *) (hdr->hie), ack, timeCorrection, &ieLen);

    if (timeCorrectionIEStatus != TKNTSCH_SUCCESS) {
      T_LOG_ERROR("Creation of time correction IE failed!\n");
      hdr->hie[0] = HIE_TERM_NOPIE_LOWER;
      hdr->hie[1] = HIE_TERM_NOPIE_UPPER;
      return timeCorrectionIEStatus;
    }

    hdr->hie[4] = HIE_TERM_NOPIE_LOWER;
    hdr->hie[5] = HIE_TERM_NOPIE_UPPER;
    return TKNTSCH_SUCCESS;
  }


  command tkntsch_status_t TknTschFrames.createEnhancedBeaconFrame(
                              message_t* msg,
                              plain154_txframe_t *txFrame,
                              uint8_t *payloadLen,
                              bool hasSyncIE,
                              bool hasTsIE,
                              bool hasHoppingIE,
                              bool hasSfIE) {
    tkntsch_status_t tknTschStatus;
    plain154_header_t* hdr;
    uint8_t* payload;
    plain154_address_t srcAddr;
    plain154_address_t dstAddr;
    uint8_t payloadIndex = 0;
    uint8_t ieLen;
    error_t status;

    if(msg == NULL)
      return TKNTSCH_INVALID_PARAMETER;

    hdr = call Frame.getHeader(msg);
    payload = call PacketPayload.getPayload(msg, call PacketPayload.maxPayloadLength());

    srcAddr.extendedAddress = call TknTschMlmeGet.macExtAddr();
    dstAddr.shortAddress = 0xffff;

    //LOG_INFO("macPanId: %x\n", call TknTschMlmeGet.macPanId());

    status = call Frame.setAddressingFields(hdr,
        PLAIN154_ADDR_EXTENDED, // src. addressing mode
        PLAIN154_ADDR_SHORT,   // dest. addressing mode
        call TknTschMlmeGet.macPanId(),
        call TknTschMlmeGet.macPanId(), // dest. pan ID
        &srcAddr,
        &dstAddr, // dest. address
        PLAIN154_FRAMEVERSION_2,
        FALSE  // PAN ID compression
      );
    if (status != PLAIN154_SUCCESS) {
      // TODO handle error in Frame.setAddressingFields
    }

    call Frame.setFrameType(hdr, PLAIN154_FRAMETYPE_BEACON);
    call Frame.setFramePending(hdr, FALSE);
    call Frame.setAckRequest(hdr, FALSE);
    call Frame.setDSN(hdr, 0x00);

    //IE list
    if (hasSyncIE || hasTsIE || hasHoppingIE || hasSfIE) { // IE list present
      call Frame.setIEListPresent(hdr, TRUE);
      hdr->hie[0] = HIE_TERM_PIE_LOWER;
      hdr->hie[1] = HIE_TERM_PIE_UPPER;

      payload[payloadIndex++] = 0;  // to be set at the end
      payload[payloadIndex++] = ((PIE_MLME_GROUP_ID << PIE_GROUP_ID_SHIFT) | PIE_MASK) >> 8;

      if (hasSyncIE == TRUE) {
        uint8_t *payloadPtr = &(payload[payloadIndex]);
        tkntsch_asn_t asn = call TknTschMlmeGet.macASN();
        uint8_t joinPriority = call TknTschMlmeGet.macJoinPriority();
        tknTschStatus = call IE.createMlmeSync(payloadPtr, &asn, joinPriority, &ieLen);
        if(tknTschStatus != TKNTSCH_SUCCESS) {
          return tknTschStatus;
        }
        payloadIndex += ieLen;
      }

      if (hasTsIE == TRUE) {
        uint8_t *payloadPtr = &(payload[payloadIndex]);
        macTimeslotTemplate_t template;

        // TODO: use IE.parseMlmeTimeslot(..) here

        template.macTimeslotTemplateId = 0x55;
        template.macTsCCAOffset = 0x4444;
        template.macTsCCA = 0x7654;
        template.macTsTxOffset = 0x0003;
        template.macTsRxOffset = 0x0005;
        template.macTsRxAckDelay = 0x0008;
        template.macTsTxAckDelay = 0x0009;
        template.macTsRxWait = 0x0012;
        template.macTsAckWait = 0x0048;
        template.macTsRxTx = 0x0064;
        template.macTsMaxAck = 0x0054;
        template.macTsMaxTx = 0x0060;
        template.macTsTimeslotLength = 0x0029;

        tknTschStatus = call IE.createMlmeTimeslot(payloadPtr, &template, &ieLen);
        if(tknTschStatus != TKNTSCH_SUCCESS) {
          return tknTschStatus;
        }
        payloadIndex += ieLen;
      }

      if(hasHoppingIE == TRUE) {
        uint8_t *payloadPtr = &(payload[payloadIndex]);
        tknTschStatus = call IE.createMlmeHoppingSequence(payloadPtr, 0, &ieLen);
        if(tknTschStatus != TKNTSCH_SUCCESS) {
          return tknTschStatus;
        }
        payloadIndex += ieLen;
      }

      if(hasSfIE == TRUE) {
        macSlotframeEntry_t slotframes;
        macLinkEntry_t links;
        uint8_t *payloadPtr;

        payloadPtr = &(payload[payloadIndex]);
        slotframes.macSlotframeHandle = 0x00;
        slotframes.macSlotframeSize = 0x0065;

        links.macLinkHandle = 0xa1a1;
        links.macLinkOptions = 0x0f;
        links.macLinkType = 0xdddd;
        links.sfHandle = 0x00;
        links.macNodeAddress.addr.shortAddress = 0x0120;
        links.macNodeAddress.mode = PLAIN154_ADDR_SHORT;
        links.macTimeslot = 0x0000;
        links.macChannelOffset = 0x0000;

        tknTschStatus = call IE.createMlmeSlotframe(payloadPtr, 1, &slotframes, 1, &links, &ieLen);
        if(tknTschStatus != TKNTSCH_SUCCESS) {
          return tknTschStatus;
        }
        payloadIndex += ieLen;
      }

      if (txFrame != NULL) {
        uint8_t headerLen = 0;
        txFrame->header = hdr;
        txFrame->metadata = call Metadata.getMetadata(msg);
        txFrame->payload = payload;
        call Frame.getActualHeaderLength(txFrame->header, &headerLen);
        txFrame->headerLen = headerLen;
        txFrame->payloadLen = payloadIndex;
      }
      payload[0] = payloadIndex - 2; // set PIE MLME length (-2 because the PIE MLME header doesn't counts)
      if (payloadLen != NULL)
        *payloadLen = payloadIndex;

      call PacketPayload.setPayloadLength(msg, payloadIndex);
    }

    return TKNTSCH_SUCCESS;
  }


  command tkntsch_status_t TknTschFrames.createDataFrame(message_t* msg, uint8_t* payload, uint8_t payloadlength) {
    bool ackRequest;
    uint8_t seqno;
    uint8_t srcAddrMode;
    uint8_t dstAddrMode;
    uint16_t srcPANID;
    uint16_t dstPANID;
    plain154_address_t srcAddr;
    plain154_address_t dstAddr;
    bool compressPanId;

    plain154_header_t* hdr;
    bool framePending;
    uint8_t* frame_payload;
    int i;

    // check arguments
    if(msg == NULL || payload == NULL)
      return TKNTSCH_INVALID_PARAMETER;

    // TODO these values should be provided by arguments
    ackRequest = TRUE;
    seqno = 0x0d;
    srcAddrMode = PLAIN154_ADDR_SHORT;
    dstAddrMode = PLAIN154_ADDR_SHORT;
    srcPANID = 0x1000;
    dstPANID = 0x2000;
    srcAddr.shortAddress = 0x11cd;
    dstAddr.shortAddress = 0x12ef;
    compressPanId = FALSE;

    hdr = call Frame.getHeader(msg);
    framePending = FALSE;
    frame_payload = (uint8_t*) msg->data; // TODO replace with call to Packet.getPayload() and check whether there is enough space

    call Frame.setAddressingFields(hdr,
        srcAddrMode,
        dstAddrMode,
        srcPANID,
        dstPANID,
        &srcAddr,
        &dstAddr,
        PLAIN154_FRAMEVERSION_1,
        compressPanId
      );
    call Frame.setFrameType(hdr, PLAIN154_FRAMETYPE_DATA);
    call Frame.setFramePending(hdr, framePending);
    call Frame.setAckRequest(hdr, ackRequest);
    call Frame.setIEListPresent(hdr, FALSE);
    call Frame.setDSN(hdr, seqno);
    //payload
    for(i = 0; i < payloadlength; i++) {
      frame_payload[i] = payload[i];
    }
    return TKNTSCH_SUCCESS;
  }


  command tkntsch_status_t TknTschFrames.parseEnhancedAckFrame(message_t* msg, uint8_t* payload, uint8_t* payloadlength) {
    plain154_header_t* hdr;
    bool IEListPresent;
    bool* ack;
    int16_t* timecorrection;
    uint8_t curr_len;
    uint8_t IElen;
    uint16_t typeIE;
    uint8_t payloadlen;
    uint8_t* frame_payload;
    int i;
    uint8_t elementId;
    uint8_t IE_len;

    if(msg == NULL || payload == NULL || payloadlength == NULL)
      return TKNTSCH_INVALID_PARAMETER;

    hdr = call Frame.getHeader(msg);
    IEListPresent = call Frame.isIEListPresent(hdr);
    curr_len = 0;
    IE_len = 0;
    payloadlen = hdr->payloadlen; // TODO replace with call to Packet.getPayloadLength()...
  //  payloadlen = 14; // for testing
    frame_payload = (uint8_t*) msg->data; // TODO replace with call to Packet.getPayload() and check whether there is enough space

    // Parsing IE list in loop
    if (IEListPresent == TRUE) {

      for(i = 0; i < payloadlen; i += curr_len) {
        // length(7 bits)=4 | Element ID(8 bits)=0x1e | Type(1 bit)=0 = 0000100 | 0001 1110 | 0
        typeIE = frame_payload[i+1] | frame_payload[i] << 8;
        elementId = (uint8_t)((typeIE & ELEMENT_ID_MASK) >> 1);

        switch(elementId) {

          case TYPE_TIMECORRECTION_IE: // Time correction IE
            if (payloadlen < HIE_TIMECORRECTION_BYTE_LENGTH)
              return TKNTSCH_MALFORMED_FRAME;
            call IE.parseTimeCorrection(&(frame_payload[i]), ack, timecorrection);
            curr_len = HIE_TIMECORRECTION_BYTE_LENGTH;
            IE_len += HIE_TIMECORRECTION_BYTE_LENGTH;
          break;

          // Other IEs - skip parsing
          // Element IDs of known Header IE's
          case TYPE_LE_CSL_IE: // LE CSL IE
          case TYPE_LE_RIT_IE: // LE RIT IE
          case TYPE_PAN_DESCRIPTOR_IE: // DSME PAN Descriptor IE
          case TYPE_RZ_TIME_IE: // RZ Time IE
          case TYPE_GROUP_ACK_IE: // Group ACK (GACK) IE
          case TYPE_LOW_LATENCY_NW_IE: // Low Latency Network Info IE
          case TYPE_LIST_TERMINATION_1: // List Termination 1
          case TYPE_LIST_TERMINATION_2: // List Termination 2
            IElen = (uint8_t)((frame_payload[i] & IE_LEN_MASK) >> 1); // first 7 bits of Header IE denote its length
            curr_len = IElen;
            IE_len += IElen;
          break;

          default:  // Unmanaged IEs, Reserved values
          curr_len += 0;
          IE_len += 0;
        }

      }
    }
    payload = &(frame_payload[IE_len]);
    *payloadlength = payloadlen - IE_len;
    return TKNTSCH_SUCCESS;
  }


  command tkntsch_status_t TknTschFrames.parseEnhancedBeaconFrame(message_t* msg, uint8_t* payload,
    uint8_t* payloadlength) {

    plain154_header_t* hdr;
    bool IEListPresent;
    typeIE_t frameIE;
    uint8_t lenIEs;
    uint8_t payloadlen;
    uint8_t* frame_payload;

    if(msg == NULL || payload == NULL || payloadlength == NULL)
      return TKNTSCH_INVALID_PARAMETER;

    hdr = call Frame.getHeader(msg);
    IEListPresent = call Frame.isIEListPresent(hdr);
    payloadlen = hdr->payloadlen;
    frame_payload = (uint8_t*) msg->data; // TODO replace with call to Packet.getPayload() and check whether there is enough space

    if(IEListPresent == TRUE) { // IEListPresent = T/F

      if(payloadlen < HIE_TERM_BYTE_LENGTH)
        return TKNTSCH_MALFORMED_FRAME;

      // to check which IEs are present
      call IE.presentPIEs(frame_payload, payloadlen, &frameIE);

      lenIEs = frameIE.totalIEsLength;
      payload = &(frame_payload[lenIEs]); // pointer to payload
      *payloadlength = payloadlen - lenIEs;
      return TKNTSCH_SUCCESS;
    }
    else {
      payload = frame_payload; // pointer to payload
      *payloadlength = payloadlen;
      return TKNTSCH_SUCCESS;
    }
  }
}
