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
 * $Revision: 1.1 $
 * $Date: 2008-06-16 18:05:14 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

/** 
 * NOTE:
 * In slotted CSMA-CA frames must be sent on backoff boundaries (slot width:
 * 320 us). On TelosB the only clock source with sufficient accuracy is the
 * external quartz, unfortunately it is not precise enough (32.768 Hz).
 * Therefore, currently the following code is not even trying to achieve
 * accurate timing. 
 */

#include "TKN154_platform.h"
module TKN154TimingP
{
  provides interface CaptureTime;
  provides interface ReliableWait;
  provides interface ReferenceTime;
  uses interface TimeCalc;
  uses interface LocalTime<T62500hz>;
}
implementation
{

#define UWAIT1 nop();nop();nop();nop()
#define UWAIT2 UWAIT1;UWAIT1
#define UWAIT4 UWAIT2;UWAIT2
#define UWAIT8 UWAIT4;UWAIT4

  async command void CaptureTime.convert(uint16_t time, ieee154_reftime_t *localTime, int16_t offset)
  {
    // TimerB is used for capturing, it is sourced by ACLK (32768Hz),
    // we now need to convert the capture "time" into ieee154_reftime_t.
    // With the 32768Hz quartz we don't have enough precision anyway,
    // so the code below generates a timestamp that is not accurate
    // (deviating about +-50 microseconds; this could probably
    // improved if we don't go through LocalTime)
    uint16_t tbr1, tbr2, delta;
    uint32_t now;
    atomic {
      do {
        tbr1 = TBR;
        tbr2 = TBR;
      } while (tbr1 != tbr2); // majority vote required (see msp430 manual)
      now = call LocalTime.get(); 
    }
    if (time < tbr1)
      delta = tbr1 - time;
    else
      delta = ~(time - tbr1) + 1;
    *localTime = now - delta*2 + offset;
  }

  async command void ReliableWait.busyWait(uint16_t dt)
  {
    uint32_t start = call LocalTime.get();
    while (!call TimeCalc.hasExpired(start, dt))
      ;
  }

  async command void ReliableWait.waitCCA(ieee154_reftime_t *t0, uint16_t dt)
  {
    while (!call TimeCalc.hasExpired(*t0, dt))
      ;
    signal ReliableWait.waitCCADone();
  }

  async command void ReliableWait.waitTx(ieee154_reftime_t *t0, uint16_t dt)
  {
    while (!call TimeCalc.hasExpired(*t0, dt))
      ;
    signal ReliableWait.waitTxDone();
  }

  async command void ReliableWait.waitRx(ieee154_reftime_t *t0, uint16_t dt)
  {
    while (!call TimeCalc.hasExpired(*t0, dt))
      ;
    signal ReliableWait.waitRxDone();
  }
 
  async command void ReferenceTime.getNow(ieee154_reftime_t* reftime, uint16_t dt)
  {
    *reftime = call LocalTime.get();
  }

  async command uint32_t ReferenceTime.toLocalTime(ieee154_reftime_t* refTime)
  {
    return *refTime;
  } 

}
