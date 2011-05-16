/*
 * Copyright (c) 2008, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * extraification, are permitted provided that the following conditions 
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
 * $Date: 2009-03-04 18:31:56 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 * In slotted CSMA-CA frames must be sent on backoff boundaries (slot width:
 * 320 us). The TelosB platform lacks a clock with sufficient precision and
 * accuracy, i.e. for slotted CSMA-CA the timing is *not* standard compliant
 * (this code is experimental)
 */

#include "TKN154_platform.h"
module TKN154TimingP
{
  provides {
    interface ReliableWait;
    interface CaptureTime;
  } uses {
    interface TimeCalc;
    interface GetNow<bool> as CCA;
    interface Alarm<T62500hz,uint32_t> as SymbolAlarm;
    interface Leds;
  }
}
implementation
{
  enum {
    S_WAIT_OFF,
    S_WAIT_RX,
    S_WAIT_TX,
    S_WAIT_BACKOFF,
  };
  uint8_t m_state = S_WAIT_OFF;


  async command uint32_t CaptureTime.getTimestamp(uint16_t captured_time)
  {
    uint32_t now = call SymbolAlarm.getNow();

    // On telos the capture_time is from the 32 KHz quartz, in
    // order to transform it to symbols we multiply by 2
    // We also subtract 10 because the returned value should represent
    // the time of the first bit of the frame, not the SFD byte.
    return now - (uint16_t)(now - captured_time * 2) - 10;
  }

  async command uint16_t CaptureTime.getSFDUptime(uint16_t SFDCaptureTime, uint16_t EFDCaptureTime)
  {
    // Return the time between two 32khz timestamps converted to symbols. 
    return (EFDCaptureTime - SFDCaptureTime) * 2;
  }

  async command bool ReliableWait.ccaOnBackoffBoundary(uint32_t slot0)
  {
    // There is no point in trying
    return (call CCA.getNow() ? 20: 0);
  }

  async command void ReliableWait.waitRx(uint32_t t0, uint32_t dt)
  {
    if (m_state != S_WAIT_OFF){
      ASSERT(0);
      return;
    }
    m_state = S_WAIT_RX;
    call SymbolAlarm.startAt(t0 - 16, dt); // subtract 12 symbols required for Rx calibration
  }

  async command void ReliableWait.waitTx(uint32_t t0, uint32_t dt)
  {
    if (m_state != S_WAIT_OFF){
      ASSERT(0);
      return;
    }
    m_state = S_WAIT_TX;
    call SymbolAlarm.startAt(t0 - 16, dt); // subtract 12 symbols required for Tx calibration
  }
    
  async command void ReliableWait.waitBackoff(uint32_t dt)
  {
    if (m_state != S_WAIT_OFF){
      ASSERT(0);
      return;
    }
    m_state = S_WAIT_BACKOFF;
    call SymbolAlarm.start(dt);
  }

  async event void SymbolAlarm.fired() 
  {
    switch (m_state)
    {
      case S_WAIT_RX: m_state = S_WAIT_OFF; signal ReliableWait.waitRxDone(); break;
      case S_WAIT_TX: m_state = S_WAIT_OFF; signal ReliableWait.waitTxDone(); break;
      case S_WAIT_BACKOFF: m_state = S_WAIT_OFF; signal ReliableWait.waitBackoffDone(); break;
      default: ASSERT(0); break;
    }
  }

}
