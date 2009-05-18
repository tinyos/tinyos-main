/*
 * Copyright (c) 2009, Technische Universitaet Berlin
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
 * $Revision: 1.1 $
 * $Date: 2009-05-18 12:54:10 $
 * @author: Jasper Buesch <buesch@tkn.tu-berlin.de>
 * ========================================================================
 */


#include "TKN154_MAC.h"
#include "TKN154.h"
module BeaconRequestRxP
{
  provides
  {
    interface Init as Reset;
    interface IEEE154TxBeaconPayload;
  }
  uses
  {
    interface FrameRx as BeaconRequestRx;
    interface FrameTx as BeaconRequestResponseTx;
    interface MLME_GET;
    interface FrameUtility;
    interface IEEE154Frame as Frame;

  }
}
implementation
{
  /* variables that describe the beacon (payload) */
  norace ieee154_txframe_t  m_beaconFrame;
  ieee154_header_t          m_header;
  ieee154_metadata_t        m_metadata;  
  uint8_t                   m_beaconPayloadLen;
  uint8_t                   m_payload[IEEE154_aMaxBeaconPayloadLength];

  /* ------------------- Init ------------------- */

  command error_t Reset.init()
  {
    m_beaconPayloadLen = 0;
    m_beaconFrame.header = &m_header;
    m_beaconFrame.headerLen = 0;
    m_beaconFrame.payload = m_payload;
    m_beaconFrame.payloadLen = 4;  // first 4 bytes belong to superframe- & gts-fields
    m_beaconFrame.metadata = &m_metadata;

    dbg_serial("BeaconRequestResponderP","Init()\n");
    return SUCCESS;
  }

  /* ------------------- Beacon-Request Response ------------------- */

  task void sendBeaconTask(){
    call BeaconRequestResponseTx.transmit(&m_beaconFrame);
  }

  event message_t* BeaconRequestRx.received(message_t* frame) 
  {
    uint8_t offset = 0;
    ieee154_macShortAddress_t shortAddress = call MLME_GET.macShortAddress();
    bool isShortAddr;

    shortAddress = call MLME_GET.macShortAddress();
    isShortAddr = (shortAddress != 0xFFFE);
    m_beaconFrame.header->mhr[MHR_INDEX_FC1] = FC1_FRAMETYPE_BEACON;
    m_beaconFrame.header->mhr[MHR_INDEX_FC2] = isShortAddr ? FC2_SRC_MODE_SHORT : FC2_SRC_MODE_EXTENDED;
    offset = MHR_INDEX_ADDRESS;
    *((nxle_uint16_t*) &m_beaconFrame.header->mhr[offset]) = PAN_ID;
    offset += sizeof(ieee154_macPANId_t);
    if (isShortAddr) {
      *((nxle_uint16_t*) &m_beaconFrame.header->mhr[offset]) = shortAddress;
      offset += sizeof(ieee154_macShortAddress_t);
    } else {
      call FrameUtility.copyLocalExtendedAddressLE(&m_beaconFrame.header->mhr[offset]);
      offset += 8;
    }
    m_beaconFrame.headerLen = offset;

    // Superframe-spec
    m_payload[0] = 0xff; // beacon- and superframe order always 15 in non-beaconenabled mode
    m_payload[1] = 0x00; 
    if (call MLME_GET.macPanCoordinator() == TRUE) 
      m_payload[1] |= 0x40;
    if (call MLME_GET.macAssociationPermit() == TRUE) 
      m_payload[1] |= 0x80;
    if (call MLME_GET.macBattLifeExt() == TRUE) 
      m_payload[1] |= 0x10;
    // GTS-spec
    m_payload[2] = 0;
    // Pending-Address-spec
    m_payload[3] = 0;

    signal IEEE154TxBeaconPayload.aboutToTransmit(); 
    post sendBeaconTask();

    return frame;

  }
 
  event void BeaconRequestResponseTx.transmitDone(ieee154_txframe_t *txFrame, ieee154_status_t status){
    signal IEEE154TxBeaconPayload.beaconTransmitted();
  }

  /* ----------------------- Beacon Payload ----------------------- */

  command error_t IEEE154TxBeaconPayload.setBeaconPayload(void *beaconPayload, uint8_t length) {
    dbg_serial("BeaconRequestResponderP","IEEE154TxBeaconPayload.setBeaconPayload\n\n");
    if (length < IEEE154_aMaxBeaconPayloadLength){
      memcpy(&m_payload[4], beaconPayload, length);
      m_beaconFrame.payloadLen = 4 + length;
      signal IEEE154TxBeaconPayload.setBeaconPayloadDone(beaconPayload, length); 
      return SUCCESS;
    } else 
      return ESIZE;
  }

  command const void* IEEE154TxBeaconPayload.getBeaconPayload(){
    return &m_payload[4]; // the first four bytes are non-user bytes
  }

  command uint8_t IEEE154TxBeaconPayload.getBeaconPayloadLength(){
    return m_beaconFrame.payloadLen - 4; // Beacon-Payload in NonBeaconed mode at least 4 bytes (non-user payload) 
  }

  command error_t IEEE154TxBeaconPayload.modifyBeaconPayload(uint8_t offset, void *buffer, uint8_t bufferLength){
    uint16_t totalLen = offset + bufferLength;
    if (totalLen > IEEE154_aMaxBeaconPayloadLength ||
        call IEEE154TxBeaconPayload.getBeaconPayloadLength() < totalLen)
      return ESIZE;
    else {
      memcpy(&m_payload[4+offset], buffer, bufferLength);
      signal IEEE154TxBeaconPayload.modifyBeaconPayloadDone(offset, buffer , bufferLength); 
    }
    return SUCCESS;
  }

  default event void IEEE154TxBeaconPayload.setBeaconPayloadDone(void *beaconPayload, uint8_t length) {}
  default event void IEEE154TxBeaconPayload.modifyBeaconPayloadDone(uint8_t offset, void *buffer, uint8_t bufferLength) {}
  default event void IEEE154TxBeaconPayload.aboutToTransmit() {}
  default event void IEEE154TxBeaconPayload.beaconTransmitted() {}

}

