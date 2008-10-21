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
 * $Revision: 1.1 $
 * $Date: 2008-10-21 17:29:00 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */


#include "TKN154_MAC.h"

module NoAssociateP
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
    interface Ieee802154Debug as Debug;
  }
}
implementation
{

  command error_t Init.init() { return SUCCESS; }

/* ------------------- MLME_ASSOCIATE Request ------------------- */

  command ieee154_status_t MLME_ASSOCIATE.request  (
                          uint8_t LogicalChannel,
                          uint8_t ChannelPage,
                          uint8_t CoordAddrMode,
                          uint16_t CoordPANID,
                          ieee154_address_t CoordAddress,
                          ieee154_CapabilityInformation_t CapabilityInformation,
                          ieee154_security_t *security
                        )
  {
    return IEEE154_TRANSACTION_OVERFLOW;
  }

  event void AssociationRequestTx.transmitDone(ieee154_txframe_t *txFrame, ieee154_status_t status) { }
  
  event void ResponseTimeout.fired() { }

  event message_t* AssociationResponseExtracted.received(message_t* frame, ieee154_txframe_t *txFrame) { return frame; }

  event void DataRequest.pollDone() { }

/* ------------------- MLME_ASSOCIATE Response ------------------- */

  event message_t* AssociationRequestRx.received(message_t* frame) { return frame; }

  command ieee154_status_t MLME_ASSOCIATE.response (
                          uint64_t deviceAddress,
                          uint16_t assocShortAddress,
                          ieee154_association_status_t status,
                          ieee154_security_t *security
                        )
  {
    return IEEE154_TRANSACTION_OVERFLOW;
  }

  event void AssociationResponseTx.transmitDone(ieee154_txframe_t *txFrame, ieee154_status_t status) { }

/* ------------------- Defaults ------------------- */

  default event void MLME_ASSOCIATE.indication (
                          uint64_t DeviceAddress,
                          ieee154_CapabilityInformation_t CapabilityInformation,
                          ieee154_security_t *security
                        ){}
  default event void MLME_ASSOCIATE.confirm    (
                          uint16_t AssocShortAddress,
                          uint8_t status,
                          ieee154_security_t *security
                        ){}
  default event void MLME_COMM_STATUS.indication (
                          uint16_t PANId,
                          uint8_t SrcAddrMode,
                          ieee154_address_t SrcAddr,
                          uint8_t DstAddrMode,
                          ieee154_address_t DstAddr,
                          ieee154_status_t status,
                          ieee154_security_t *security
                        ){}
}
