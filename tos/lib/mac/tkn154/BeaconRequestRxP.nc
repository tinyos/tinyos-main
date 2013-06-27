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
 * $Revision: 1.3 $
 * $Date: 2009-05-28 09:52:54 $
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
    interface MLME_START;
  }
  uses
  {
    interface FrameRx as BeaconRequestRx;
    interface FrameTx as BeaconRequestResponseTx;
    interface MLME_GET;
    interface MLME_SET;
    interface FrameUtility;
    interface IEEE154Frame as Frame;
    interface Set<ieee154_macPanCoordinator_t> as SetMacPanCoordinator;     

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
  bool                      m_started;

  task void signalStartConfirmTask();

  /* ------------------- Init ------------------- */

  command error_t Reset.init()
  {
    m_beaconPayloadLen = 0;
    m_beaconFrame.header = &m_header;
    m_beaconFrame.headerLen = 0;
    m_beaconFrame.payload = m_payload;
    m_beaconFrame.payloadLen = 4;  // first 4 bytes belong to superframe- & gts-fields
    m_beaconFrame.metadata = &m_metadata;
    m_started = FALSE;

    dbg_serial("BeaconRequestRxP","Init()\n");
    return SUCCESS;
  }

  command ieee154_status_t MLME_START.request  (
                          uint16_t panID,
                          uint8_t logicalChannel,
                          uint8_t channelPage,
                          uint32_t startTime,
                          uint8_t beaconOrder,
                          uint8_t superframeOrder,
                          bool panCoordinator,
                          bool batteryLifeExtension,
                          bool coordRealignment,
                          ieee154_security_t *coordRealignSecurity,
                          ieee154_security_t *beaconSecurity)
  {
    ieee154_status_t status;
    ieee154_macShortAddress_t shortAddress = call MLME_GET.macShortAddress();

    // check parameters
    if ((coordRealignSecurity && coordRealignSecurity->SecurityLevel) ||
        (beaconSecurity && beaconSecurity->SecurityLevel))
      status = IEEE154_UNSUPPORTED_SECURITY;
    else if (shortAddress == 0xFFFF) 
      status = IEEE154_NO_SHORT_ADDRESS;
    else if (logicalChannel > 26 ||
        (channelPage != IEEE154_SUPPORTED_CHANNELPAGE) ||
        !(IEEE154_SUPPORTED_CHANNELS & ((uint32_t) 1 << logicalChannel)))
      status =  IEEE154_INVALID_PARAMETER;
    else if (beaconOrder != 15) 
      status = IEEE154_INVALID_PARAMETER;
    else {
      call MLME_SET.macPANId(panID);
      call MLME_SET.phyCurrentChannel(logicalChannel);
      call MLME_SET.macBeaconOrder(beaconOrder);
      call SetMacPanCoordinator.set(panCoordinator);
      //TODO: check realignment
      post signalStartConfirmTask();
      status = IEEE154_SUCCESS;
      m_started = TRUE;
    }
    dbg_serial("DispatchUnslottedCsmaP", "MLME_START.request -> result: %lu\n", (uint32_t) status);
    dbg_serial_flush();
    return status;
  }

  task void signalStartConfirmTask()
  {
    signal MLME_START.confirm(IEEE154_SUCCESS);
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

    if (!m_started) {
      dbg_serial("BeaconRequestRxP","received beacon request, but I'm not a coordinator -> dropping frame\n");
      dbg_serial_flush();
      return frame;
    }
    dbg_serial("BeaconRequestRxP","received beacon request -> sending beacon...\n");
    shortAddress = call MLME_GET.macShortAddress();
    isShortAddr = (shortAddress != 0xFFFE);
    m_beaconFrame.header->mhr[MHR_INDEX_FC1] = FC1_FRAMETYPE_BEACON;
    m_beaconFrame.header->mhr[MHR_INDEX_FC2] = isShortAddr ? FC2_SRC_MODE_SHORT : FC2_SRC_MODE_EXTENDED;
    offset = MHR_INDEX_ADDRESS;
    *((nxle_uint16_t*) &m_beaconFrame.header->mhr[offset]) = call MLME_GET.macPANId();
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
    m_payload[BEACON_INDEX_SF_SPEC1] = 0xff; // beacon- and superframe order always 15 in nonbeacon-enabled mode
    m_payload[BEACON_INDEX_SF_SPEC2] = 0x00; 
    if (call MLME_GET.macPanCoordinator() == TRUE) 
      m_payload[BEACON_INDEX_SF_SPEC2] |= SF_SPEC2_PAN_COORD;
    if (call MLME_GET.macAssociationPermit() == TRUE) 
      m_payload[BEACON_INDEX_SF_SPEC2] |= SF_SPEC2_ASSOCIATION_PERMIT;
    if (call MLME_GET.macBattLifeExt() == TRUE) 
      m_payload[BEACON_INDEX_SF_SPEC2] |= SF_SPEC2_BATT_LIFE_EXT;
    // GTS-spec
    m_payload[BEACON_INDEX_GTS_SPEC] = 0;
    // Pending-Address-spec (behind empty single-byte GTS field)
    m_payload[BEACON_INDEX_GTS_SPEC + 1] = 0;

    signal IEEE154TxBeaconPayload.aboutToTransmit(); 
    post sendBeaconTask();

    return frame;
  }

  event void BeaconRequestResponseTx.transmitDone(ieee154_txframe_t *txFrame, ieee154_status_t status){
    signal IEEE154TxBeaconPayload.beaconTransmitted();
  }

  /* ----------------------- Beacon Payload ----------------------- */

  command error_t IEEE154TxBeaconPayload.setBeaconPayload(void *beaconPayload, uint8_t length) {
    dbg_serial("BeaconRequestRxP","IEEE154TxBeaconPayload.setBeaconPayload\n\n");
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
  default event void MLME_START.confirm(ieee154_status_t status) {}

}

