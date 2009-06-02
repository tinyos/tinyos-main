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
 * $Revision: 1.3 $
 * $Date: 2009-06-02 08:40:12 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/* "The coordinator realignment command is sent by the PAN coordinator or a
 * coordinator either following the reception of an orphan notification command
 * from a device that is recognized to be on its PAN or when any of its PAN
 * configuration attributes change due to the receipt of an MLME-START.request
 * primitive." IEEE 802.15.4-2006, Sec. 7.3.8 **/ 

#include "TKN154_MAC.h"
module CoordRealignmentP
{
  provides
  {
    interface Init;
    interface MLME_ORPHAN;
    interface MLME_COMM_STATUS;
    interface GetSet<ieee154_txframe_t*> as GetSetRealignmentFrame;
  }
  uses
  {
    interface FrameTx as CoordRealignmentTx;
    interface FrameRx as OrphanNotificationRx;
    interface FrameUtility;
    interface MLME_GET;
    interface IEEE154Frame as Frame;
    interface Pool<ieee154_txframe_t> as TxFramePool;
    interface Pool<ieee154_txcontrol_t> as TxControlPool;
    interface Get<uint64_t> as LocalExtendedAddress;
  }
}
implementation
{
  enum {
    ORPHAN_RESPONSE,
    BEACON_REALIGNMENT,
  };

  uint8_t m_payload[9];
  bool m_busy = FALSE;
  void destroyRealignmentFrame(ieee154_txframe_t *frame);
  ieee154_txframe_t *newRealignmentFrame(uint8_t type, ieee154_address_t *dstAddress);

  command error_t Init.init()
  {
    return SUCCESS;
  }

  command ieee154_txframe_t* GetSetRealignmentFrame.get()
  {
    ieee154_address_t bcastAddr;
    bcastAddr.shortAddress = 0xFFFF;
    return newRealignmentFrame(BEACON_REALIGNMENT, &bcastAddr);
  }

  command void GetSetRealignmentFrame.set(ieee154_txframe_t*  frame)
  {
    destroyRealignmentFrame(frame);
  }

  event message_t* OrphanNotificationRx.received(message_t* frame)
  {
    ieee154_address_t srcAddress;
    if (call Frame.getSrcAddrMode(frame) == ADDR_MODE_EXTENDED_ADDRESS &&
        call Frame.getSrcAddr(frame, &srcAddress) == SUCCESS)    
      signal MLME_ORPHAN.indication (
                          srcAddress.extendedAddress,
                          NULL);
    return frame;
  }

  command ieee154_status_t MLME_ORPHAN.response (
                          uint64_t OrphanAddress,
                          uint16_t ShortAddress,
                          bool AssociatedMember,
                          ieee154_security_t *security)
  {
    ieee154_txframe_t *txFrame;
    ieee154_status_t txStatus;
    ieee154_address_t dstAddress;

    dstAddress.extendedAddress = OrphanAddress;
    if (!AssociatedMember)
      txStatus = IEEE154_SUCCESS;
    else if (m_busy || (txFrame = newRealignmentFrame(ORPHAN_RESPONSE, &dstAddress)) == NULL)
      txStatus = IEEE154_TRANSACTION_OVERFLOW;
    else {
      m_busy = TRUE;
      txFrame->payload[0] = CMD_FRAME_COORDINATOR_REALIGNMENT;
      *((nxle_uint16_t*) &txFrame->payload[1]) = call MLME_GET.macPANId();
      *((nxle_uint16_t*) &txFrame->payload[3]) = call MLME_GET.macShortAddress();
      txFrame->payload[5] = call MLME_GET.phyCurrentChannel();
      *((nxle_uint16_t*) &txFrame->payload[6]) = ShortAddress;
      txFrame->payloadLen = 8;
      if ((txStatus = call CoordRealignmentTx.transmit(txFrame)) != IEEE154_SUCCESS) {
        m_busy = FALSE;
        destroyRealignmentFrame(txFrame);
      }
    }
    return txStatus;
  }

  ieee154_txframe_t *newRealignmentFrame(uint8_t type, ieee154_address_t *dstAddress)
  {
    ieee154_txframe_t *txFrame = NULL;
    ieee154_txcontrol_t *txControl;
    uint8_t dstAddrMode;
    ieee154_address_t srcAddress;

    if ((txFrame = call TxFramePool.get()) != NULL) {
      if ((txControl = call TxControlPool.get()) == NULL) {
        call TxFramePool.put(txFrame);
        txFrame = NULL;
      } else {
        txFrame->header = &txControl->header;
        txFrame->metadata = &txControl->metadata;      
        txFrame->payload = m_payload;
        txFrame->header->mhr[MHR_INDEX_FC1] = FC1_FRAMETYPE_CMD;
        txFrame->header->mhr[MHR_INDEX_FC2] = FC2_SRC_MODE_EXTENDED;
        if (type == ORPHAN_RESPONSE) {
          txFrame->header->mhr[MHR_INDEX_FC2] |= FC2_DEST_MODE_EXTENDED;
          dstAddrMode = ADDR_MODE_EXTENDED_ADDRESS;
          txFrame->header->mhr[MHR_INDEX_FC1] |= FC1_ACK_REQUEST;
        } else {
          txFrame->header->mhr[MHR_INDEX_FC2] |= FC2_DEST_MODE_SHORT;
          dstAddrMode = ADDR_MODE_SHORT_ADDRESS;
        }
        srcAddress.extendedAddress = call LocalExtendedAddress.get();
        txFrame->headerLen = call FrameUtility.writeHeader(
              txFrame->header->mhr,
              dstAddrMode,
              0xFFFF,
              dstAddress,
              ADDR_MODE_EXTENDED_ADDRESS,
              call MLME_GET.macPANId(),
              &srcAddress,
              FALSE);
      }
    }
    return txFrame;
  }

  void destroyRealignmentFrame(ieee154_txframe_t *frame)
  {
    call TxControlPool.put((ieee154_txcontrol_t*) ((uint8_t*) frame->header - offsetof(ieee154_txcontrol_t, header)));
    call TxFramePool.put(frame);
  }

  
  event void CoordRealignmentTx.transmitDone(ieee154_txframe_t *txFrame, ieee154_status_t status)
  {
    uint8_t *mhr = MHR(txFrame);
    ieee154_address_t dstAddr;
    ieee154_address_t srcAddr;

    if (m_busy) {
      call FrameUtility.convertToNative(&dstAddr.extendedAddress, &mhr[MHR_INDEX_ADDRESS+2]);
      call FrameUtility.convertToNative(&srcAddr.extendedAddress, &mhr[MHR_INDEX_ADDRESS+2+8+2]);
      signal MLME_COMM_STATUS.indication (
          *((nxle_uint16_t*) &txFrame->payload[1]), // PANId
          ADDR_MODE_EXTENDED_ADDRESS, // SrcAddrMode
          srcAddr,
          ADDR_MODE_EXTENDED_ADDRESS, // DstAddrMode
          dstAddr,
          status,
          NULL);
      call TxControlPool.put((ieee154_txcontrol_t*) ((uint8_t*) txFrame->header - offsetof(ieee154_txcontrol_t, header)));
      call TxFramePool.put(txFrame);
      m_busy = FALSE;
    }
  }

  default event void MLME_COMM_STATUS.indication (
                          uint16_t PANId,
                          uint8_t SrcAddrMode,
                          ieee154_address_t SrcAddr,
                          uint8_t DstAddrMode,
                          ieee154_address_t DstAddr,
                          ieee154_status_t status,
                          ieee154_security_t *security) {}

  default event void MLME_ORPHAN.indication (
                          uint64_t OrphanAddress,
                          ieee154_security_t *security) {}
}
