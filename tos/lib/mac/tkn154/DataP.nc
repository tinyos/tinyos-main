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
 * $Revision: 1.2 $
 * $Date: 2008-10-21 17:29:00 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
#include "TKN154_MAC.h"

module DataP
{
  provides
  {
    interface Init;
    interface MCPS_DATA; 
    interface MCPS_PURGE;
  } uses {
    interface GetNow<bool> as IsSendingBeacons;
    interface FrameRx as CoordCapRx;
    interface FrameTx as DeviceCapTx;
    interface FrameTx as CoordCapTx;
    interface FrameTx as BroadcastTx;
    interface FrameRx as DeviceCapRx;
    interface Pool<ieee154_txframe_t> as TxFramePool;
    interface FrameTx as DeviceCfpTx;
    interface FrameTx as CoordCfpTx;
    interface FrameTx as IndirectTx;
    interface FrameRx as CoordCfpRx;
    interface FrameRx as DeviceCfpRx;
    interface FrameUtility;
    interface Purge as PurgeDirect;
    interface Purge as PurgeIndirect;
    interface Purge as PurgeGtsDevice;
    interface Purge as PurgeGtsCoord;
    interface MLME_GET;
    interface Leds;
    interface Packet;
    interface IEEE154Frame as Frame;
    interface Get<uint64_t> as LocalExtendedAddress;
  }
}
implementation
{
  message_t* dataReceived(message_t* frame);
  void finishTxTransaction(ieee154_txframe_t *txFrame, ieee154_status_t status);

  command error_t Init.init()
  {
    return SUCCESS;
  }
  
  command ieee154_status_t MCPS_DATA.request  (
                          message_t *frame,
                          uint8_t payloadLen,
                          uint8_t msduHandle,
                          uint8_t txOptions
                        )
  {
    uint8_t srcAddrMode = call Frame.getSrcAddrMode(frame);
    uint8_t dstAddrMode = call Frame.getDstAddrMode(frame);
    ieee154_address_t dstAddr;
    ieee154_status_t txStatus;
    ieee154_txframe_t *txFrame;
    uint8_t sfType=0;
    uint8_t *mhr;

    if (payloadLen > call Packet.maxPayloadLength())
      txStatus = IEEE154_INVALID_PARAMETER;
    else if ((!srcAddrMode && !dstAddrMode) || 
        (srcAddrMode > ADDR_MODE_EXTENDED_ADDRESS || dstAddrMode > ADDR_MODE_EXTENDED_ADDRESS) ||
        (srcAddrMode == ADDR_MODE_RESERVED || dstAddrMode  == ADDR_MODE_RESERVED))
      txStatus = IEEE154_INVALID_ADDRESS; 
    else if (!(txFrame = call TxFramePool.get()))
      txStatus = IEEE154_TRANSACTION_OVERFLOW;
    else {
      // construct the DATA frame
      txFrame->header = &((message_header_t*) frame->header)->ieee154;
      txFrame->payload = (uint8_t*) frame->data;
      txFrame->metadata = &((message_metadata_t*) frame->metadata)->ieee154;
      txFrame->payloadLen = payloadLen;
      mhr = txFrame->header->mhr;
      txFrame->headerLen = call Frame.getHeaderLength(frame);
      mhr[MHR_INDEX_FC1] &= ~(FC1_FRAMETYPE_MASK | FC1_FRAME_PENDING | FC1_ACK_REQUEST);
      mhr[MHR_INDEX_FC1] |= FC1_FRAMETYPE_DATA;
      if (txOptions & TX_OPTIONS_ACK)
        mhr[MHR_INDEX_FC1] |= FC1_ACK_REQUEST;
      mhr[MHR_INDEX_FC2] &= ~FC2_FRAME_VERSION_MASK;
      if (payloadLen > IEEE154_aMaxMACSafePayloadSize)
        mhr[MHR_INDEX_FC2] |= FC2_FRAME_VERSION_1;
      txFrame->handle = msduHandle;
      
      // in case a node is both, coordinator and device (e.g. in a 
      // cluster-tree topology), it has to be decided whether the frame 
      // is to be sent in the incoming or outgoing superframe (sf); 
      // we do this by comparing the destination address to the
      // coordinator address in the PIB, if they match the frame is
      // sent in the incoming sf otherwise in the outgoing sf
      call Frame.getDstAddr(frame, &dstAddr);
      if (dstAddrMode == ADDR_MODE_SHORT_ADDRESS){
        if (dstAddr.shortAddress == call MLME_GET.macCoordShortAddress())
          sfType = INCOMING_SUPERFRAME;
        else
          sfType = OUTGOING_SUPERFRAME;
      } else if (dstAddrMode == ADDR_MODE_EXTENDED_ADDRESS){
        if (dstAddr.extendedAddress == call MLME_GET.macCoordExtendedAddress())
          sfType = INCOMING_SUPERFRAME;
        else
          sfType = OUTGOING_SUPERFRAME;
      } else if (dstAddrMode == ADDR_MODE_NOT_PRESENT) // to PAN Coord
        sfType = INCOMING_SUPERFRAME;

      // GTS?
      if (txOptions & TX_OPTIONS_GTS){
        if (sfType == INCOMING_SUPERFRAME)
          txStatus = call DeviceCfpTx.transmit(txFrame);
        else
          txStatus = call CoordCfpTx.transmit(txFrame);

      // indirect transmission?
      } else if ((txOptions & TX_OPTIONS_INDIRECT) && 
          call IsSendingBeacons.getNow() && 
          (dstAddrMode >= ADDR_MODE_SHORT_ADDRESS)){
        if (dstAddrMode == ADDR_MODE_SHORT_ADDRESS && dstAddr.shortAddress == 0xFFFF){
          mhr[MHR_INDEX_FC1] &= ~FC1_ACK_REQUEST;
          txStatus = call BroadcastTx.transmit(txFrame);
        } else
          txStatus = call IndirectTx.transmit(txFrame);

      // transmission in the CAP
      } else 
        if (sfType == INCOMING_SUPERFRAME)
          txStatus = call DeviceCapTx.transmit(txFrame);
        else
          txStatus = call CoordCapTx.transmit(txFrame);

      if (txStatus != IEEE154_SUCCESS){
        call TxFramePool.put(txFrame);
      }
    }
    return txStatus;
  }

  command ieee154_status_t MCPS_PURGE.request  (
                          uint8_t msduHandle
                        )
  {
    if (call PurgeDirect.purge(msduHandle) == IEEE154_SUCCESS ||
        call PurgeIndirect.purge(msduHandle) == IEEE154_SUCCESS ||
        call PurgeGtsDevice.purge(msduHandle) == IEEE154_SUCCESS ||
        call PurgeGtsCoord.purge(msduHandle) == IEEE154_SUCCESS)
      return IEEE154_SUCCESS;
    else
      return IEEE154_INVALID_HANDLE;
  }

  event void PurgeDirect.purgeDone(ieee154_txframe_t *data, ieee154_status_t status)
  {
    finishTxTransaction(data, status);
  }

  event void PurgeIndirect.purgeDone(ieee154_txframe_t *data, ieee154_status_t status)
  {
    finishTxTransaction(data, status);
  }

  event void PurgeGtsDevice.purgeDone(ieee154_txframe_t *data, ieee154_status_t status)
  {
    finishTxTransaction(data, status);
  }

  event void PurgeGtsCoord.purgeDone(ieee154_txframe_t *data, ieee154_status_t status)
  {
    finishTxTransaction(data, status);
  }

  event message_t* CoordCfpRx.received(message_t* frame)
  {
    return dataReceived(frame);
  }

  event message_t* DeviceCfpRx.received(message_t* frame)
  {
    return dataReceived(frame);
  }

  event message_t* CoordCapRx.received(message_t* frame)
  {
    return dataReceived(frame);
  }

  event message_t* DeviceCapRx.received(message_t* frame)
  {
    return dataReceived(frame);
  }

  message_t* dataReceived(message_t* frame)
  {
    return signal MCPS_DATA.indication( frame );
  }

  void finishTxTransaction(ieee154_txframe_t *txFrame, ieee154_status_t status)
  {
    uint8_t handle = txFrame->handle;
    uint32_t txTime = txFrame->metadata->timestamp;
    message_t *msg = (message_t*) ((uint8_t*) txFrame->header - offsetof(message_t, header));
    call TxFramePool.put(txFrame);
    signal MCPS_DATA.confirm(msg, handle, status, txTime);
  }

  event void BroadcastTx.transmitDone(ieee154_txframe_t *txFrame, ieee154_status_t status)
  {
    finishTxTransaction(txFrame, status);
  }

  event void DeviceCapTx.transmitDone(ieee154_txframe_t *txFrame, ieee154_status_t status)
  {
    finishTxTransaction(txFrame, status);
  }
  
  event void CoordCapTx.transmitDone(ieee154_txframe_t *txFrame, ieee154_status_t status)
  {
    finishTxTransaction(txFrame, status);
  }

  event void DeviceCfpTx.transmitDone(ieee154_txframe_t *txFrame, ieee154_status_t status)
  {
    finishTxTransaction(txFrame, status);
  }
  
  event void CoordCfpTx.transmitDone(ieee154_txframe_t *txFrame, ieee154_status_t status)
  {
    finishTxTransaction(txFrame, status);
  }


  event void IndirectTx.transmitDone(ieee154_txframe_t *txFrame, ieee154_status_t status)
  {
    finishTxTransaction(txFrame, status);
  }

  default event void MCPS_DATA.confirm(  
                          message_t *msg,
                          uint8_t msduHandle,
                          ieee154_status_t status,
                          uint32_t Timestamp
                        ){}

  default event message_t* MCPS_DATA.indication ( message_t* frame ){ return frame; }
  default command ieee154_status_t DeviceCfpTx.transmit(ieee154_txframe_t *data){return IEEE154_INVALID_GTS;}
  default command ieee154_status_t CoordCfpTx.transmit(ieee154_txframe_t *data){return IEEE154_INVALID_GTS;}
}
