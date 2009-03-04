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
 * $Date: 2009-03-04 18:31:40 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

 /** Empty placeholder component for DisassociateP. */

#include "TKN154_MAC.h"

module NoDisassociateP
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
    interface FrameUtility;
    interface IEEE154Frame as Frame;
    interface Get<uint64_t> as LocalExtendedAddress;
  }
}
implementation
{

  command error_t Init.init() { return SUCCESS; }

  /* ------------------- MLME_DISASSOCIATE (initiating) ------------------- */

  command ieee154_status_t MLME_DISASSOCIATE.request  (
                          uint8_t DeviceAddrMode,
                          uint16_t DevicePANID,
                          ieee154_address_t DeviceAddress,
                          ieee154_disassociation_reason_t DisassociateReason,
                          bool TxIndirect,
                          ieee154_security_t *security
                        )
  {
    return IEEE154_TRANSACTION_OVERFLOW;
  }

  event void DisassociationToCoord.transmitDone(ieee154_txframe_t *data, ieee154_status_t status) { }

  event void DisassociationIndirectTx.transmitDone(ieee154_txframe_t *data, ieee154_status_t status) { }

  event void DisassociationDirectTx.transmitDone(ieee154_txframe_t *data, ieee154_status_t status) { }

  /* ------------------- MLME_DISASSOCIATE (receiving) ------------------- */

  event message_t* DisassociationDirectRxFromCoord.received(message_t* frame) { return frame; }

  event message_t* DisassociationExtractedFromCoord.received(message_t* frame, ieee154_txframe_t *txFrame) { return frame;
  }

  event message_t* DisassociationRxFromDevice.received(message_t* frame) { return frame; }

  /* ------------------- Defaults ------------------- */

  default event void MLME_DISASSOCIATE.indication (
                          uint64_t DeviceAddress,
                          ieee154_disassociation_reason_t DisassociateReason,
                          ieee154_security_t *security
                        ){}
  default event void MLME_DISASSOCIATE.confirm    (
                          ieee154_status_t status,
                          uint8_t DeviceAddrMode,
                          uint16_t DevicePANID,
                          ieee154_address_t DeviceAddress
                        ){}

}
