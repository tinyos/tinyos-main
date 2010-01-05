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
 * $Date: 2010-01-05 16:41:16 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

#include "TKN154_MAC.h"

module RadioControlImplP 
{
  provides
  {
    interface RadioRx as MacRx[uint8_t client];
    interface RadioTx as MacTx[uint8_t client];
    interface SlottedCsmaCa as SlottedCsmaCa[uint8_t client];
    interface UnslottedCsmaCa as UnslottedCsmaCa[uint8_t client];
    interface RadioOff as MacRadioOff[uint8_t client];
  } uses {
    interface ArbiterInfo;
    interface RadioRx as PhyRx;
    interface RadioTx as PhyTx;
    interface SlottedCsmaCa as PhySlottedCsmaCa;
    interface UnslottedCsmaCa as PhyUnslottedCsmaCa;
    interface RadioOff as PhyRadioOff;
    interface Get<bool> as RadioPromiscuousMode;
    interface Leds;
  }
}
implementation
{

  /* ----------------------- RadioRx ----------------------- */

  async command error_t MacRx.enableRx[uint8_t client](uint32_t t0, uint32_t dt)
  {
    if (client == call ArbiterInfo.userId()) 
      return call PhyRx.enableRx(t0, dt);
    else {
      ASSERT(0);
      return IEEE154_TRANSACTION_OVERFLOW;
    }
  }

  async event void PhyRx.enableRxDone()
  {
    signal MacRx.enableRxDone[call ArbiterInfo.userId()]();
  }

  event message_t* PhyRx.received(message_t *msg, const ieee154_timestamp_t *timestamp)
  {
    uint8_t *mhr = MHR(msg);

    dbg("RadioControlImplP", "Received frame, DSN: %lu, type: 0x%lu\n", 
        (uint32_t) mhr[MHR_INDEX_SEQNO], (uint32_t) mhr[MHR_INDEX_FC1] & FC1_FRAMETYPE_MASK);

    if (((mhr[1] & FC2_FRAME_VERSION_MASK) > FC2_FRAME_VERSION_1)
        && (!call RadioPromiscuousMode.get()))
      return msg;

#ifndef IEEE154_SECURITY_ENABLED
    if ((mhr[0] & FC1_SECURITY_ENABLED)
        && (!call RadioPromiscuousMode.get()))
      return msg;
#endif
    return signal MacRx.received[call ArbiterInfo.userId()](msg, timestamp);
  }

  async command bool MacRx.isReceiving[uint8_t client]()
  {
    if (client == call ArbiterInfo.userId())
      return call PhyRx.isReceiving();
    else {
      ASSERT(0);
      return FAIL;
    } 
  }

  default async event void MacRx.enableRxDone[uint8_t client]() { ASSERT(0); }

  default event message_t* MacRx.received[uint8_t client](message_t *frame, const ieee154_timestamp_t *timestamp)
  {
    ASSERT(0);
    return frame;
  }

  /* ----------------------- RadioTx ----------------------- */

  async command error_t MacTx.transmit[uint8_t client](ieee154_txframe_t *frame, 
      const ieee154_timestamp_t *t0, uint32_t dt)
  {
    if (client == call ArbiterInfo.userId())
      return call PhyTx.transmit(frame, t0, dt);
    else {
      ASSERT(0);
      return IEEE154_TRANSACTION_OVERFLOW;
    }
  }
  
  async event void PhyTx.transmitDone(ieee154_txframe_t *frame, 
      const ieee154_timestamp_t *timestamp, error_t result)
  {
    signal MacTx.transmitDone[call ArbiterInfo.userId()](frame, timestamp, result);
  }

  default async event void MacTx.transmitDone[uint8_t client](ieee154_txframe_t *frame, 
      const ieee154_timestamp_t *timestamp, error_t result) 
  {
    ASSERT(0);
  }

  /* ----------------------- Unslotted CSMA ----------------------- */

  async command error_t UnslottedCsmaCa.transmit[uint8_t client](ieee154_txframe_t *frame, ieee154_csma_t *csma)
  {
    if (client == call ArbiterInfo.userId()) 
      return call PhyUnslottedCsmaCa.transmit(frame, csma);
    else {
      ASSERT(0);
      return IEEE154_TRANSACTION_OVERFLOW;
    }
  }

  async event void PhyUnslottedCsmaCa.transmitDone(ieee154_txframe_t *frame, ieee154_csma_t *csma, bool ackPendingFlag, error_t result)
  {
    signal UnslottedCsmaCa.transmitDone[call ArbiterInfo.userId()](
        frame, csma, ackPendingFlag, result);
  }

  default async event void UnslottedCsmaCa.transmitDone[uint8_t client](
      ieee154_txframe_t *frame, ieee154_csma_t *csma, bool ackPendingFlag, error_t result)
  {
    ASSERT(0);
  }

  /* ----------------------- Slotted CSMA ----------------------- */

  async command error_t SlottedCsmaCa.transmit[uint8_t client](ieee154_txframe_t *frame, ieee154_csma_t *csma,
      const ieee154_timestamp_t *slot0Time, uint32_t dtMax, bool resume, uint16_t remainingBackoff)
  {
    if (client == call ArbiterInfo.userId()) 
      return call PhySlottedCsmaCa.transmit(frame, csma, slot0Time, dtMax, resume, remainingBackoff);
    else {
      ASSERT(0);
      return IEEE154_TRANSACTION_OVERFLOW;
    }
  }

  async event void PhySlottedCsmaCa.transmitDone(ieee154_txframe_t *frame, ieee154_csma_t *csma, 
      bool ackPendingFlag,  uint16_t remainingBackoff, error_t result)
  {
    signal SlottedCsmaCa.transmitDone[call ArbiterInfo.userId()](
        frame, csma, ackPendingFlag, remainingBackoff, result);
  }

  default async event void SlottedCsmaCa.transmitDone[uint8_t client](
      ieee154_txframe_t *frame, ieee154_csma_t *csma, 
      bool ackPendingFlag,  uint16_t remainingBackoff, error_t result)
  {
    ASSERT(0);
  }

  /* ----------------------- RadioOff ----------------------- */

  async command error_t MacRadioOff.off[uint8_t client]()
  {
    if (client == call ArbiterInfo.userId())
      return call PhyRadioOff.off();
    else {
      ASSERT(0);
      return EBUSY;
    }
  }

  async event void PhyRadioOff.offDone()
  {
    signal MacRadioOff.offDone[call ArbiterInfo.userId()]();
  }

  
  async command bool MacRadioOff.isOff[uint8_t client]()
  {
    if (client == call ArbiterInfo.userId())
      return call PhyRadioOff.isOff();
    else
      return EBUSY;
  }

  default async event void MacRadioOff.offDone[uint8_t client]()
  {
    ASSERT(0);
  }
}
