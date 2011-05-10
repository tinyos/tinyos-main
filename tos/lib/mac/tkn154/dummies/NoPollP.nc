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
 * $Date: 2010-01-05 16:41:16 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

 /** Empty placeholder component for PollP. */

#include "TKN154_MAC.h"

module NoPollP
{
  provides
  {
    interface Init;
    interface MLME_POLL;
    interface FrameRx as DataRx;
    interface DataRequest as DataRequest[uint8_t client];
  }
  uses
  {
    interface FrameTx as PollTx;
    interface FrameExtracted as DataExtracted;
    interface FrameUtility;
    interface Pool<ieee154_txframe_t> as TxFramePool;
    interface Pool<ieee154_txcontrol_t> as TxControlPool;
    interface MLME_GET;
    interface Get<uint64_t> as LocalExtendedAddress;
  }
}
implementation
{
  command error_t Init.init() { return SUCCESS; }

  command ieee154_status_t MLME_POLL.request  (
                          uint8_t coordAddrMode,
                          uint16_t coordPANID,
                          ieee154_address_t coordAddress,
                          ieee154_security_t *security)
  {
    return IEEE154_TRANSACTION_OVERFLOW;
  }

  command ieee154_status_t DataRequest.poll[uint8_t client](uint8_t CoordAddrMode, 
      uint16_t CoordPANId, uint8_t *CoordAddressLE, uint8_t srcAddrMode)
  {
    return IEEE154_TRANSACTION_OVERFLOW;
  }

  event message_t* DataExtracted.received(message_t* frame, ieee154_txframe_t *txFrame)
  {
    return frame;
  }

  event void PollTx.transmitDone(ieee154_txframe_t *txFrame, ieee154_status_t status)
  {
  }
}
