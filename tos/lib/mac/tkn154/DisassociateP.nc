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
 * $Date: 2009-10-16 12:25:45 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */


#include "TKN154_MAC.h"

module DisassociateP
{
  provides
  {
    interface Init;
    interface MLME_DISASSOCIATE;
  } uses {

    interface FrameTx as DisassociationIndirectTx;
    interface FrameTx as DisassociationDirectTx;
    interface FrameTx as DisassociationToCoord;

    interface FrameRx as DisassociationDirectRxFromCoord;
    interface FrameExtracted as DisassociationExtractedFromCoord;
    interface FrameRx as DisassociationRxFromDevice;

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
  uint8_t m_payloadDisassocRequest[2];
  uint8_t m_coordAddrMode;
  bool m_disAssociationOngoing;
  void resetPanValuesInPib();

  command error_t Init.init()
  {
    m_payloadDisassocRequest[0] = S_IDLE;
    m_coordAddrMode = 0;
    m_disAssociationOngoing = FALSE;
    return SUCCESS;
  }

  /* ------------------- MLME_DISASSOCIATE (initiating) ------------------- */

  command ieee154_status_t MLME_DISASSOCIATE.request  (
                          uint8_t DeviceAddrMode,
                          uint16_t DevicePANID,
                          ieee154_address_t DeviceAddress,
                          ieee154_disassociation_reason_t DisassociateReason,
                          bool TxIndirect,
                          ieee154_security_t *security)
  {
    ieee154_status_t status = IEEE154_SUCCESS;
    ieee154_txframe_t *txFrame=0;
    ieee154_txcontrol_t *txControl=0;
    ieee154_address_t srcAddress;

    if (security && security->SecurityLevel)
      status = IEEE154_UNSUPPORTED_SECURITY;
    else if (call MLME_GET.macPANId() != DevicePANID || 
        (DeviceAddrMode != ADDR_MODE_SHORT_ADDRESS && DeviceAddrMode != ADDR_MODE_EXTENDED_ADDRESS))
      status = IEEE154_INVALID_PARAMETER;
    else if (m_disAssociationOngoing || !(txFrame = call TxFramePool.get()))
      status = IEEE154_TRANSACTION_OVERFLOW;
    else if (!(txControl = call TxControlPool.get())) {
      call TxFramePool.put(txFrame);
      status = IEEE154_TRANSACTION_OVERFLOW;
    } 
    if (status == IEEE154_SUCCESS) {
      txFrame->header = &txControl->header;
      txFrame->metadata = &txControl->metadata;
      srcAddress.extendedAddress = call LocalExtendedAddress.get();
      txFrame->headerLen = call FrameUtility.writeHeader(
          txFrame->header->mhr,
          DeviceAddrMode,
          call MLME_GET.macPANId(),
          &DeviceAddress,
          ADDR_MODE_EXTENDED_ADDRESS,
          call MLME_GET.macPANId(),
          &srcAddress,
          TRUE);
      txFrame->header->mhr[MHR_INDEX_FC1] = FC1_ACK_REQUEST | FC1_FRAMETYPE_CMD | FC1_PAN_ID_COMPRESSION;
      txFrame->header->mhr[MHR_INDEX_FC2] = FC2_SRC_MODE_EXTENDED |
        (DeviceAddrMode == ADDR_MODE_SHORT_ADDRESS ? FC2_DEST_MODE_SHORT : FC2_DEST_MODE_EXTENDED);
      m_payloadDisassocRequest[0] = CMD_FRAME_DISASSOCIATION_NOTIFICATION;
      m_payloadDisassocRequest[1] = DisassociateReason;
      txFrame->payload = m_payloadDisassocRequest;
      txFrame->payloadLen = 2;
      m_disAssociationOngoing = TRUE;
      if ((DeviceAddrMode == ADDR_MODE_SHORT_ADDRESS &&
            DeviceAddress.shortAddress == call MLME_GET.macCoordShortAddress()) ||
          (DeviceAddrMode == ADDR_MODE_EXTENDED_ADDRESS &&
           DeviceAddress.extendedAddress == call MLME_GET.macCoordExtendedAddress())) {
        status = call DisassociationToCoord.transmit(txFrame);
      } else if (TxIndirect) {
        status = call DisassociationIndirectTx.transmit(txFrame);
      } else {
        status = call DisassociationDirectTx.transmit(txFrame);
      }
      if (status != IEEE154_SUCCESS) {
        m_disAssociationOngoing = FALSE;
        call TxFramePool.put(txFrame);
        call TxControlPool.put(txControl);
      }
    }
    dbg_serial("DisassociateP", "MLME_DISASSOCIATE.request -> result: %lu\n", (uint32_t) status);
    return status;
  }

  event void DisassociationToCoord.transmitDone(ieee154_txframe_t *data, ieee154_status_t status) 
  { 
    // transmitted a disassociation notification to our coordinator
    uint8_t *mhr = MHR(data), srcAddrOffset = 7;
    uint8_t DeviceAddrMode = (mhr[MHR_INDEX_FC2] & FC2_SRC_MODE_MASK) >> FC2_SRC_MODE_OFFSET;
    uint16_t DevicePANID = *((nxle_uint16_t*) (&(mhr[MHR_INDEX_ADDRESS])));
    ieee154_address_t DeviceAddress;

    if ((mhr[MHR_INDEX_FC2] & FC2_DEST_MODE_MASK) == FC2_DEST_MODE_EXTENDED)
      srcAddrOffset += 6;
    call FrameUtility.convertToNative(&DeviceAddress.extendedAddress, &mhr[srcAddrOffset]);
    call TxControlPool.put((ieee154_txcontrol_t*) ((uint8_t*) data->header - offsetof(ieee154_txcontrol_t, header)));
    call TxFramePool.put(data);
    dbg_serial("DisassociateP", "transmitDone() -> result: %lu\n", (uint32_t) status);
    m_disAssociationOngoing = FALSE;

    // "[...] even if the acknowledgment is not received, 
    // the device should consider itself disassociated."  (Sect. 7.5.3.2)
    if (status == IEEE154_SUCCESS || status == IEEE154_NO_ACK)
      resetPanValuesInPib();  
    signal MLME_DISASSOCIATE.confirm(status, DeviceAddrMode, DevicePANID, DeviceAddress);
  }

  event void DisassociationIndirectTx.transmitDone(ieee154_txframe_t *data, ieee154_status_t status) 
  {
    signal DisassociationDirectTx.transmitDone(data, status);
  }

  event void DisassociationDirectTx.transmitDone(ieee154_txframe_t *data, ieee154_status_t status) 
  { 
    // transmitted a disassociation notification to a device
    uint8_t *mhr = MHR(data), dstAddrOffset = 5;
    uint8_t DeviceAddrMode = (mhr[1] & FC2_DEST_MODE_MASK) >> FC2_DEST_MODE_OFFSET;
    uint16_t DevicePANID = *((nxle_uint16_t*) (&(mhr[MHR_INDEX_ADDRESS])));
    ieee154_address_t DeviceAddress;

    call FrameUtility.convertToNative(&DeviceAddress.extendedAddress, &mhr[dstAddrOffset]);
    call TxControlPool.put((ieee154_txcontrol_t*) ((uint8_t*) data->header - offsetof(ieee154_txcontrol_t, header)));
    call TxFramePool.put(data);
    dbg_serial("DisassociateP", "transmitDone() -> result: %lu\n", (uint32_t) status);
    m_disAssociationOngoing = FALSE;

    // "[...] even if the acknowledgment is not received, 
    // the device should consider itself disassociated." (Sect. 7.5.3.2)
    if (status == IEEE154_SUCCESS || status == IEEE154_NO_ACK)
      resetPanValuesInPib();      
    signal MLME_DISASSOCIATE.confirm(status, DeviceAddrMode, DevicePANID, DeviceAddress);
  }

  /* ------------------- MLME_DISASSOCIATE (receiving) ------------------- */

  event message_t* DisassociationDirectRxFromCoord.received(message_t* frame)
  {
    // received a disassociation notification from the coordinator (direct tx)
    ieee154_address_t address;

    address.extendedAddress = call LocalExtendedAddress.get();
    signal MLME_DISASSOCIATE.indication(address.extendedAddress, frame->data[1], NULL);
    return frame;
  }

  event message_t* DisassociationExtractedFromCoord.received(message_t* frame, ieee154_txframe_t *txFrame)
  {
    // received a disassociation notification from the coordinator (indirect transmission)
    return signal DisassociationDirectRxFromCoord.received(frame);
  }

  event message_t* DisassociationRxFromDevice.received(message_t* frame)
  {
    // received a disassociation notification from the device
    ieee154_address_t address;

    if (call Frame.getSrcAddrMode(frame) == ADDR_MODE_EXTENDED_ADDRESS && 
        call Frame.getSrcAddr(frame, &address) == SUCCESS)
      signal MLME_DISASSOCIATE.indication(address.extendedAddress, frame->data[1], NULL);
    dbg_serial("DisassociateP", "Received disassociation request from %lx\n", (uint32_t) address.shortAddress);
    return frame;
  }

  void resetPanValuesInPib()
  {
    // "An associated device shall disassociate itself by removing 
    // all references to the PAN; the MLME shall set macPANId, 
    // macShortAddress, macAssociatedPANCoord, macCoordShortAddress 
    // and macCoordExtended- Address to the default values." (Sect. 7.5.3.2) 
    call MLME_SET.macPANId(IEEE154_DEFAULT_PANID);
    call MLME_SET.macShortAddress(IEEE154_DEFAULT_SHORTADDRESS);
    call MLME_SET.macAssociatedPANCoord(IEEE154_DEFAULT_ASSOCIATEDPANCOORD);
    call MLME_SET.macCoordShortAddress(IEEE154_DEFAULT_COORDSHORTADDRESS);
    call MLME_SET.macCoordExtendedAddress(0);
  }

  /* ------------------- Defaults ------------------- */

  default event void MLME_DISASSOCIATE.indication (
                          uint64_t DeviceAddress,
                          ieee154_disassociation_reason_t DisassociateReason,
                          ieee154_security_t *security) {}

  default event void MLME_DISASSOCIATE.confirm    (
                          ieee154_status_t status,
                          uint8_t DeviceAddrMode,
                          uint16_t DevicePANID,
                          ieee154_address_t DeviceAddress) {}

}
