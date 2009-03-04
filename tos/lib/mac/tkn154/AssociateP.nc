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
 * $Revision: 1.5 $
 * $Date: 2009-03-04 18:31:12 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */


#include "TKN154_MAC.h"

module AssociateP
{
  provides
  {
    interface Init;
    interface MLME_ASSOCIATE;
    interface MLME_COMM_STATUS;
  }
  uses
  {
    interface FrameRx as AssociationRequestRx;
    interface FrameTx as AssociationRequestTx;
    interface FrameExtracted as AssociationResponseExtracted;
    interface FrameTx as AssociationResponseTx;

    interface DataRequest;
    interface Timer<TSymbolIEEE802154> as ResponseTimeout;
    interface Pool<ieee154_txframe_t> as TxFramePool;
    interface Pool<ieee154_txcontrol_t> as TxControlPool;
    interface MLME_GET;
    interface MLME_SET;
    interface FrameUtility;
    interface IEEE154Frame as Frame;
    interface Get<uint64_t> as LocalExtendedAddress;
  }
}
implementation
{
  enum {
    S_IDLE = 0xFF,
  };
  uint8_t m_payloadAssocRequest[2];
  uint8_t m_payloadAssocResponse[MAX_PENDING_ASSOC_RESPONSES][4];
  uint8_t m_coordAddrMode;
  uint8_t m_assocRespStatus;
  uint16_t m_shortAddress;
  bool m_associationOngoing;

  command error_t Init.init()
  {
    uint8_t i;
    call ResponseTimeout.stop();
    m_payloadAssocRequest[0] = S_IDLE;
    m_coordAddrMode = 0;
    m_associationOngoing = FALSE;
    for (i=0; i<MAX_PENDING_ASSOC_RESPONSES; i++)
      m_payloadAssocResponse[i][0] = S_IDLE;
    return SUCCESS;
  }

  /* ------------------- MLME_ASSOCIATE Request ------------------- */

  command ieee154_status_t MLME_ASSOCIATE.request  (
                          uint8_t LogicalChannel,
                          uint8_t ChannelPage,
                          uint8_t CoordAddrMode,
                          uint16_t CoordPANID,
                          ieee154_address_t CoordAddress,
                          ieee154_CapabilityInformation_t CapabilityInformation,
                          ieee154_security_t *security)
  {
    ieee154_status_t status = IEEE154_SUCCESS;
    ieee154_txframe_t *txFrame=0;
    ieee154_txcontrol_t *txControl=0;
    ieee154_address_t srcAddress;

    if (security && security->SecurityLevel)
      status = IEEE154_UNSUPPORTED_SECURITY;
    else if (ChannelPage != IEEE154_SUPPORTED_CHANNELPAGE || LogicalChannel > 26 ||
         !(IEEE154_SUPPORTED_CHANNELS & ((uint32_t) 1 << LogicalChannel)) ||
        (CoordAddrMode != ADDR_MODE_SHORT_ADDRESS && CoordAddrMode != ADDR_MODE_EXTENDED_ADDRESS))
      status = IEEE154_INVALID_PARAMETER;
    else if (m_associationOngoing || !(txFrame = call TxFramePool.get()))
      status = IEEE154_TRANSACTION_OVERFLOW;
    else if (!(txControl = call TxControlPool.get())) {
      call TxFramePool.put(txFrame);
      status = IEEE154_TRANSACTION_OVERFLOW;
    }
    if (status == IEEE154_SUCCESS) {
      m_assocRespStatus = IEEE154_NO_DATA;
      m_shortAddress = 0xFFFF;
      call MLME_SET.phyCurrentChannel(LogicalChannel);
      call MLME_SET.macPANId(CoordPANID);
      m_coordAddrMode = CoordAddrMode;
      if (CoordAddrMode == ADDR_MODE_SHORT_ADDRESS)
        call MLME_SET.macCoordShortAddress(CoordAddress.shortAddress);
      else
        call MLME_SET.macCoordExtendedAddress(CoordAddress.extendedAddress);
      txFrame->header = &txControl->header;
      txFrame->metadata = &txControl->metadata;
      srcAddress.extendedAddress = call LocalExtendedAddress.get();
      txFrame->headerLen = call FrameUtility.writeHeader(
          txFrame->header->mhr,
          CoordAddrMode,
          CoordPANID,
          &CoordAddress,
          ADDR_MODE_EXTENDED_ADDRESS,
          0xFFFF,
          &srcAddress,
          0);
      txFrame->header->mhr[MHR_INDEX_FC1] = FC1_ACK_REQUEST | FC1_FRAMETYPE_CMD;
      txFrame->header->mhr[MHR_INDEX_FC2] = FC2_SRC_MODE_EXTENDED |
        (CoordAddrMode == ADDR_MODE_SHORT_ADDRESS ? FC2_DEST_MODE_SHORT : FC2_DEST_MODE_EXTENDED);
      m_payloadAssocRequest[0] = CMD_FRAME_ASSOCIATION_REQUEST;
      m_payloadAssocRequest[1] = *((uint8_t*) &CapabilityInformation);
      txFrame->payload = m_payloadAssocRequest;
      txFrame->payloadLen = 2;
      m_associationOngoing = TRUE;
      if ((status = call AssociationRequestTx.transmit(txFrame)) != IEEE154_SUCCESS) {
        m_associationOngoing = FALSE;
        call TxFramePool.put(txFrame);
        call TxControlPool.put(txControl);
      }
    }
    dbg_serial("AssociationP", "MLME_ASSOCIATE.request -> result: %lu\n", (uint32_t) status);
    return status;
  }

  event void AssociationRequestTx.transmitDone(ieee154_txframe_t *txFrame, ieee154_status_t status)
  {
    call TxControlPool.put((ieee154_txcontrol_t*) ((uint8_t*) txFrame->header - offsetof(ieee154_txcontrol_t, header)));
    call TxFramePool.put(txFrame);
    if (status != IEEE154_SUCCESS) {
      dbg_serial("AssociationP", "transmitDone() failed!\n");
      m_associationOngoing = FALSE;
      signal MLME_ASSOCIATE.confirm(0xFFFF, status, 0);
    } else {
      call ResponseTimeout.startOneShot(call MLME_GET.macResponseWaitTime()*IEEE154_aBaseSuperframeDuration);
      dbg_serial("AssociationP", "transmitDone() ok, waiting for %lu\n", 
          (uint32_t) (call MLME_GET.macResponseWaitTime() * IEEE154_aBaseSuperframeDuration));
    }
  }
  
  event void ResponseTimeout.fired()
  {
    uint8_t coordAddress[8];
    if (!m_associationOngoing)
      return;
    // have not received an AssociationResponse yet, poll the coordinator now
    if (m_coordAddrMode == ADDR_MODE_SHORT_ADDRESS)
      *((nxle_uint16_t*) &coordAddress) = call MLME_GET.macCoordShortAddress();
    else
      call FrameUtility.copyCoordExtendedAddressLE(coordAddress);
    if (call DataRequest.poll(m_coordAddrMode, call MLME_GET.macPANId(), 
          coordAddress, ADDR_MODE_EXTENDED_ADDRESS) != IEEE154_SUCCESS) {
      m_shortAddress = 0xFFFF;
      m_assocRespStatus = IEEE154_TRANSACTION_OVERFLOW;
      signal DataRequest.pollDone();
    }
  }

  event message_t* AssociationResponseExtracted.received(message_t* frame, ieee154_txframe_t *txFrame)
  {
    uint8_t *payload = (uint8_t *) &frame->data;
    if (m_associationOngoing) {
      m_shortAddress =  *((nxle_uint16_t*) (payload + 1));
      m_assocRespStatus = *(payload + 3);
    }
    return frame;
  }

  event void DataRequest.pollDone()
  {
    if (m_associationOngoing) {
      call ResponseTimeout.stop();
      m_associationOngoing = FALSE;
      signal MLME_ASSOCIATE.confirm(m_shortAddress, m_assocRespStatus, 0);
      dbg_serial("AssociationP", "confirm: %lx, %lu\n", 
          (uint32_t) m_shortAddress, (uint32_t) m_assocRespStatus);
    }
  }

  /* ------------------- MLME_ASSOCIATE Response ------------------- */

  event message_t* AssociationRequestRx.received(message_t* frame)
  {
    uint8_t *payload = (uint8_t *) &frame->data;
    ieee154_address_t srcAddress;
    if (call Frame.getSrcAddrMode(frame) == ADDR_MODE_EXTENDED_ADDRESS &&
        call Frame.getSrcAddr(frame, &srcAddress) == SUCCESS)
      signal MLME_ASSOCIATE.indication(srcAddress.extendedAddress,
          *((ieee154_CapabilityInformation_t*) (payload + 1)), 0);
    return frame;
  }

  command ieee154_status_t MLME_ASSOCIATE.response (
                          uint64_t deviceAddress,
                          uint16_t assocShortAddress,
                          ieee154_association_status_t status,
                          ieee154_security_t *security)
  {
    uint8_t i;
    ieee154_status_t txStatus = IEEE154_SUCCESS;
    ieee154_txframe_t *txFrame;
    ieee154_txcontrol_t *txControl;
    ieee154_address_t srcAddress;

    for (i=0; i<MAX_PENDING_ASSOC_RESPONSES;i++)
      if (m_payloadAssocResponse[i][0] == S_IDLE)
        break;    
    if (i == MAX_PENDING_ASSOC_RESPONSES || !(txFrame = call TxFramePool.get()))
      txStatus = IEEE154_TRANSACTION_OVERFLOW;
    else if (!(txControl = call TxControlPool.get())) {
      call TxFramePool.put(txFrame);
      txStatus = IEEE154_TRANSACTION_OVERFLOW;
    } else {
      txFrame->header = &txControl->header;
      txFrame->metadata = &txControl->metadata;      
      txFrame->payload = m_payloadAssocResponse[i];
      srcAddress.extendedAddress = call LocalExtendedAddress.get();
      txFrame->headerLen = call FrameUtility.writeHeader(
          txFrame->header->mhr,
          ADDR_MODE_EXTENDED_ADDRESS,
          call MLME_GET.macPANId(),
          (ieee154_address_t*) &deviceAddress,
          ADDR_MODE_EXTENDED_ADDRESS,
          call MLME_GET.macPANId(),
          &srcAddress,
          1);
      txFrame->header->mhr[MHR_INDEX_FC1] = FC1_ACK_REQUEST | FC1_FRAMETYPE_CMD | FC1_PAN_ID_COMPRESSION;
      txFrame->header->mhr[MHR_INDEX_FC2] = FC2_SRC_MODE_EXTENDED | FC2_DEST_MODE_EXTENDED;
      txFrame->payload[0] = CMD_FRAME_ASSOCIATION_RESPONSE;
      *((nxle_uint16_t*) &txFrame->payload[1]) = assocShortAddress;
      txFrame->payload[3] = status;
      txFrame->payloadLen = 4;
      if ((txStatus = call AssociationResponseTx.transmit(txFrame)) != IEEE154_SUCCESS) {
        txFrame->payload[0] = S_IDLE;
        call TxFramePool.put(txFrame);
        call TxControlPool.put(txControl);
      }
    }
    return txStatus;
  }

  event void AssociationResponseTx.transmitDone(ieee154_txframe_t *txFrame, ieee154_status_t status)
  {
    ieee154_address_t srcAddress, deviceAddress;
    srcAddress.extendedAddress = call LocalExtendedAddress.get();
    if ((txFrame->header->mhr[MHR_INDEX_FC2] & FC2_DEST_MODE_MASK) == FC2_DEST_MODE_SHORT)
      deviceAddress.shortAddress = *((nxle_uint16_t*) (&(txFrame->header->mhr[MHR_INDEX_ADDRESS]) + 2));
    else
      call FrameUtility.convertToNative(&deviceAddress.extendedAddress,  (&(txFrame->header->mhr[MHR_INDEX_ADDRESS]) + 2));
    txFrame->payload[0] = S_IDLE;
    call TxControlPool.put((ieee154_txcontrol_t*) ((uint8_t*) txFrame->header - offsetof(ieee154_txcontrol_t, header)));
    call TxFramePool.put(txFrame);
    signal MLME_COMM_STATUS.indication(call MLME_GET.macPANId(), ADDR_MODE_EXTENDED_ADDRESS,
                          srcAddress, ADDR_MODE_EXTENDED_ADDRESS, deviceAddress,
                          status, 0);
  }

  /* ------------------- Defaults ------------------- */

  default event void MLME_ASSOCIATE.indication (
                          uint64_t DeviceAddress,
                          ieee154_CapabilityInformation_t CapabilityInformation,
                          ieee154_security_t *security) {}
  default event void MLME_ASSOCIATE.confirm    (
                          uint16_t AssocShortAddress,
                          uint8_t status,
                          ieee154_security_t *security) {}
  default event void MLME_COMM_STATUS.indication (
                          uint16_t PANId,
                          uint8_t SrcAddrMode,
                          ieee154_address_t SrcAddr,
                          uint8_t DstAddrMode,
                          ieee154_address_t DstAddr,
                          ieee154_status_t status,
                          ieee154_security_t *security) {}
}
