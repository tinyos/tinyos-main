/*
 * Copyright (c) 2005 Arched Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arched Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/** 
 * @author Phil Buonadonna
 *
 */

// @author Phil Buonadonna

#include "Timer.h"

generic module HalPXA27xAlarmM(typedef frequency_tag, uint8_t resolution) 
{
  provides {
    interface Init;
    interface Alarm<frequency_tag,uint32_t> as Alarm;
  }
  uses {
    interface Init as OSTInit;
    interface HplPXA27xOSTimer as OSTChnl;
  }
}

implementation
{
  bool mfRunning;
  uint32_t mMinDeltaT;

  task void lateAlarm() {
    atomic {
      mfRunning = FALSE;
      signal Alarm.fired();
    }
  }
  
  command error_t Init.init() {

    call OSTInit.init(); 
    // Continue on match, Non-periodic, w/ given resolution
    atomic {
      mfRunning = FALSE;
      switch (resolution) {
      case 1: // 1/32768 second
	mMinDeltaT = 10;
	break;
      case 2: // 1 ms
	mMinDeltaT = 1;
	break;
      case 3: // 1 s
	mMinDeltaT = 1;
	break;
      case 4: // 1 us
	mMinDeltaT = 300;
	break;
      default:  // External
	mMinDeltaT = 0;
	break;
      }
      call OSTChnl.setOMCR(OMCR_C | OMCR_P | OMCR_CRES(resolution));
      call OSTChnl.setOSCR(0);
    }
    return SUCCESS;

  }

  async command void Alarm.start( uint32_t dt ) {
    uint32_t t0,t1,tf;
    //uint32_t cycles;
    bool bPending;
    if (dt < mMinDeltaT) dt = mMinDeltaT;

    atomic {
      //_pxa27x_perf_clear();
      t0 = call OSTChnl.getOSCR();
      tf = t0 + dt;
      call OSTChnl.setOIERbit(TRUE);
      call OSTChnl.setOSMR(tf);
      //_pxa27x_perf_get(cycles);
      mfRunning = TRUE;
      t1 = call OSTChnl.getOSCR();
      bPending = call OSTChnl.getOSSRbit();
      if ((dt <= (t1 - t0)) && !(bPending)) {
	call OSTChnl.setOIERbit(FALSE);
	post lateAlarm();
      }
    }
    return;
  }

  async command void Alarm.stop() {
    atomic {
      call OSTChnl.setOIERbit(FALSE);
      mfRunning = FALSE;
    }
    return;
  }

  async command bool Alarm.isRunning() {
    bool flag;

    atomic flag = mfRunning;
    return flag;
  }

  async command void Alarm.startAt( uint32_t t0, uint32_t dt ) {
    uint32_t tf,t1;
    bool bPending;
    tf = t0 + dt;

    atomic {
      call OSTChnl.setOIERbit(TRUE);
      call OSTChnl.setOSMR(tf);
      mfRunning = TRUE;
      t1 = call OSTChnl.getOSCR();
      bPending = call OSTChnl.getOSSRbit();
      if ((dt <= (t1 - t0)) && !(bPending)) {
	call OSTChnl.setOIERbit(FALSE);
	post lateAlarm();
      }
    }

    return;
  } 

  async command uint32_t Alarm.getNow() {
    return call OSTChnl.getOSCR();
  }

  async command uint32_t Alarm.getAlarm() {
    return call OSTChnl.getOSMR();
  }

  async event void OSTChnl.fired() {
    call OSTChnl.clearOSSRbit();
    call OSTChnl.setOIERbit(FALSE);
    mfRunning = FALSE;
    signal Alarm.fired();
    return;
  }

  default async event void Alarm.fired() {
    return;
  }


}

