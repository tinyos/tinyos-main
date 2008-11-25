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
 * $Revision: 1.2 $
 * $Date: 2008-11-25 09:35:09 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 * In slotted CSMA-CA frames must be sent on backoff boundaries (slot width:
 * 320 us). The TelosB platform lacks a clock with sufficient precision/
 * accuracy, i.e. for slotted CSMA-CA the timing is *not* standard compliant.
 */

#include "TKN154_platform.h"
module TKN154TimingP
{
  provides interface CaptureTime;
  provides interface ReliableWait;
  provides interface ReferenceTime;
  uses interface TimeCalc;
  uses interface Alarm<T62500hz,uint32_t> as SymbolAlarm;
  uses interface Leds;
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

  async command void CaptureTime.convert(uint16_t time, ieee154_reftime_t *localTime, int16_t offset)
  {
    // TimerB is used for capturing, it is sourced by ACLK (32768Hz),
    // we now need to convert the capture "time" into ieee154_reftime_t.
    // With the 32768Hz quartz we don't have enough precision anyway,
    // so the code below generates a timestamp that is not accurate
    // (deviating about +-50 microseconds, which could probably
    // improved if we don't go through LocalTime)
    uint16_t tbr1, tbr2, delta;
    uint32_t now;
    atomic {
      do {
        tbr1 = TBR;
        tbr2 = TBR;
      } while (tbr1 != tbr2); // majority vote required (see msp430 manual)
      now = call SymbolAlarm.getNow(); 
    }
    if (time < tbr1)
      delta = tbr1 - time;
    else
      delta = ~(time - tbr1) + 1;
    *localTime = now - delta*2 + offset;
  }

  async command void ReliableWait.busyWait(uint16_t dt)
  {
    uint16_t tbr1, tbr2, tbrVal;
    atomic {
      do {
        tbr1 = TBR;
        tbr2 = TBR;
      } while (tbr1 != tbr2); // majority vote required (see msp430 manual)
    }
    tbrVal = tbr1 + dt;
    atomic {
      do {
        tbr1 = TBR;
        tbr2 = TBR;
      } while (tbr1 != tbr2 || tbr1 != tbrVal); // majority vote required (see msp430 manual)
    }
  }

  async command void ReliableWait.waitRx(ieee154_reftime_t *t0, uint16_t dt)
  {
    if (m_state != S_WAIT_OFF){
      call Leds.led0On();
      return;
    }
    m_state = S_WAIT_RX;
    call SymbolAlarm.startAt(*t0 - 12, dt); // subtract 12 symbols required for Rx calibration
    //signal SymbolAlarm.fired();
  }

  async command void ReliableWait.waitTx(ieee154_reftime_t *t0, uint16_t dt)
  {
    if (m_state != S_WAIT_OFF){
      call Leds.led0On();
      return;
    }
    m_state = S_WAIT_TX;
    call SymbolAlarm.startAt(*t0 - 12, dt); // subtract 12 symbols required for Tx calibration
  }
    
  async command void ReliableWait.waitBackoff(ieee154_reftime_t *t0, uint16_t dt)
  {
    if (m_state != S_WAIT_OFF){
      call Leds.led0On();
      return;
    }
    m_state = S_WAIT_BACKOFF;
    call SymbolAlarm.startAt(*t0, dt);
    //signal SymbolAlarm.fired();
  }

  async event void SymbolAlarm.fired() 
  {
    switch (m_state)
    {
      case S_WAIT_RX: m_state = S_WAIT_OFF; signal ReliableWait.waitRxDone(); break;
      case S_WAIT_TX: m_state = S_WAIT_OFF; signal ReliableWait.waitTxDone(); break;
      case S_WAIT_BACKOFF: m_state = S_WAIT_OFF; signal ReliableWait.waitBackoffDone(); break;
      default: call Leds.led0On(); break;
    }
  }

  async command void ReliableWait.busyWaitSlotBoundaryCCA(ieee154_reftime_t *t0, uint16_t *dt) { }
  async command void ReliableWait.busyWaitSlotBoundaryTx(ieee154_reftime_t *t0, uint16_t dt) 
  { 
    // we cannot meet the timing constraints, but there should at least roughly
    // be 20 symbols between the first and the seconds CCA
    call ReliableWait.busyWait(20);
  }

  async command void ReferenceTime.getNow(ieee154_reftime_t* reftime, uint16_t dt)
  {
    *reftime = call SymbolAlarm.getNow() + dt;
  }

  async command uint32_t ReferenceTime.toLocalTime(ieee154_reftime_t* refTime)
  {
    return *refTime;
  } 

}
