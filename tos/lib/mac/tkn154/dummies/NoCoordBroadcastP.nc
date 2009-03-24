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
 * $Date: 2009-03-24 12:56:47 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

 /** Empty placeholder component for CoordBroadcastP. */

#include "TKN154_MAC.h"
module NoCoordBroadcastP
{
  provides
  {
    interface Init as Reset;
    interface FrameTx as BroadcastDataFrame;
    interface FrameTx as RealignmentTx;
    interface GetNow<bool> as IsBroadcastReady; 
  } uses {
    interface Queue<ieee154_txframe_t*>; 
    interface FrameTxNow as CapTransmitNow;
    interface TransferableResource as RadioToken;
    interface GetNow<bool> as BeaconFramePendingBit;
    interface SuperframeStructure as OutgoingSF;
    interface Leds;
  }
}
implementation
{

  command error_t Reset.init() { return SUCCESS; }

  command ieee154_status_t BroadcastDataFrame.transmit(ieee154_txframe_t *txFrame)
  {
    return IEEE154_TRANSACTION_OVERFLOW;
  }

  command ieee154_status_t RealignmentTx.transmit(ieee154_txframe_t *frame)
  {
    return IEEE154_TRANSACTION_OVERFLOW;
  }

  async command bool IsBroadcastReady.getNow()
  {
    return FALSE;
  }

  async event void RadioToken.transferredFrom(uint8_t fromClient)
  {
    call RadioToken.transferTo(RADIO_CLIENT_COORDCAP);
  }

  async event void CapTransmitNow.transmitNowDone(ieee154_txframe_t *txFrame, ieee154_status_t status)
  {
  }
  event void RadioToken.granted(){ }
}
