/* 
 * Copyright (c) 2011, Technische Universitaet Berlin
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
 * ========================================================================
 * Author(s): Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

 /** Empty placeholder component for IndirectTxP. */

module NoIndirectTxP
{
  provides
  {
    interface Init as Reset;
    interface FrameTx[uint8_t client];
    interface WriteBeaconField as PendingAddrWrite;
    interface Notify<bool> as PendingAddrSpecUpdated;
    interface Get<ieee154_txframe_t*> as GetIndirectTxFrame; 
    interface Purge;
  }
  uses
  {
    interface FrameTx as CoordCapTx;
    interface FrameRx as DataRequestRx;
    interface MLME_GET;
    interface IEEE154Frame;
    interface Timer<TSymbolIEEE802154> as IndirectTxTimeout;
    interface TimeCalc;
    interface Leds;
  }
}
implementation
{
  command error_t Reset.init() { return SUCCESS; }

  command ieee154_status_t Purge.purge(uint8_t msduHandle) { return IEEE154_INVALID_HANDLE; }

  command uint8_t PendingAddrWrite.write(uint8_t *lastBytePtr, uint8_t maxlen)
  {
    *lastBytePtr = 0;
    return 1;
  }

  command ieee154_status_t FrameTx.transmit[uint8_t client](ieee154_txframe_t *txFrame) { return IEEE154_TRANSACTION_OVERFLOW; }

  event message_t* DataRequestRx.received(message_t* frame) { return frame; }

  event void IndirectTxTimeout.fired() { }

  event void CoordCapTx.transmitDone(ieee154_txframe_t *txFrame, ieee154_status_t status) { }

  command ieee154_txframe_t* GetIndirectTxFrame.get() { return NULL;}
  command error_t PendingAddrSpecUpdated.enable() {return FAIL;}
  command error_t PendingAddrSpecUpdated.disable() {return FAIL;}
}
