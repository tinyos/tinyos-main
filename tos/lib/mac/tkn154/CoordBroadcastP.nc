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
 * $Date: 2009-03-04 18:31:18 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/* This component is responsible for sending broadcast frames from
 * a coordinator to devices.
 **/

#include "TKN154_MAC.h"
module CoordBroadcastP
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
    interface ResourceTransfer as TokenToCap;
    interface ResourceTransferred as TokenTransferred;
    interface SuperframeStructure as OutgoingSF;
    interface Leds;
  }
}
implementation
{
  norace bool m_lock;
  norace ieee154_txframe_t *m_realignmentFrame;
  norace ieee154_txframe_t *m_queueHead;
  norace ieee154_txframe_t *m_transmittedFrame;
  norace ieee154_status_t m_status;

  task void transmitNowDoneTask();

  command error_t Reset.init()
  {
    while (call Queue.size())
      signal BroadcastDataFrame.transmitDone(call Queue.dequeue(), IEEE154_TRANSACTION_OVERFLOW);
    if (m_realignmentFrame) 
      signal RealignmentTx.transmitDone(m_realignmentFrame, IEEE154_TRANSACTION_OVERFLOW);
    m_realignmentFrame = m_queueHead = m_transmittedFrame = NULL;
    m_lock = FALSE;
    return SUCCESS;
  }

  command ieee154_status_t BroadcastDataFrame.transmit(ieee154_txframe_t *txFrame)
  {
    if (call Queue.enqueue(txFrame) != SUCCESS)
      return IEEE154_TRANSACTION_OVERFLOW;
    atomic {
      if (m_queueHead == NULL)
        m_queueHead = call Queue.head();
    }
    return IEEE154_SUCCESS;
  }

  command ieee154_status_t RealignmentTx.transmit(ieee154_txframe_t *frame)
  {
    atomic {
      if (!m_realignmentFrame) {
        m_realignmentFrame = frame;
        return IEEE154_SUCCESS;
      } else
        return IEEE154_TRANSACTION_OVERFLOW;
    }
  }

  async command bool IsBroadcastReady.getNow()
  {
    if (m_lock)
      return FALSE;
    else
      return (m_realignmentFrame != NULL || m_queueHead != NULL);
  }

  async event void TokenTransferred.transferred()
  {
    // CAP has started - are there any broadcast frames to be transmitted?
    if (call OutgoingSF.isBroadcastPending()) {
      ieee154_txframe_t *broadcastFrame = m_realignmentFrame;
      if (broadcastFrame == NULL)
        broadcastFrame = m_queueHead;
      ASSERT(broadcastFrame != NULL);
      m_lock = TRUE;
      call CapTransmitNow.transmitNow(broadcastFrame);
    }
    call TokenToCap.transfer();
  }

  async event void CapTransmitNow.transmitNowDone(ieee154_txframe_t *txFrame, ieee154_status_t status)
  {
    m_transmittedFrame = txFrame;
    m_status = status;
    post transmitNowDoneTask();
  }

  task void transmitNowDoneTask()
  {
    if (!m_lock)
      return;
    if (m_transmittedFrame == m_realignmentFrame) {
      m_realignmentFrame = NULL;
      signal RealignmentTx.transmitDone(m_transmittedFrame, m_status);
    } else if (m_transmittedFrame == m_queueHead) {
      call Queue.dequeue();
      m_queueHead = call Queue.head();
      signal BroadcastDataFrame.transmitDone(m_transmittedFrame, m_status);
    }
    m_lock = FALSE;
  }
}
