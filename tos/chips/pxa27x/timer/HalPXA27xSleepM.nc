/*
 * Copyright (c) 2005 Arch Rock Corporation 
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
 *   Neither the name of the Arch Rock Corporation nor the names of its
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
 * @author Kaisen Lin
 * @author Phil Buonadonna
 *
 */

module HalPXA27xSleepM {
  provides interface HalPXA27xSleep;
  uses interface HplPXA27xRTC;
  uses interface HplPXA27xPower;

  uses interface Leds;
}

implementation {

  void doSleep(uint32_t swRegVal, bool useDeepSleep) {
    int i;
    call HplPXA27xPower.setPWER(PWER_WERTC);
    // let it wrap around itself if necessary
    call HplPXA27xRTC.setSWCR(0);
    call HplPXA27xRTC.setSWAR1(swRegVal); // minutes
    call HplPXA27xRTC.setSWAR2(0x00FFFFFF);
    for(i = 0; i < 10; i++); // spin for a bit
    call HplPXA27xRTC.setRTSR(RTSR_SWCE);
    for(i = 0; i < 5000; i++); // spin for a bit

    if (useDeepSleep) {
      call HplPXA27xPower.setPWRMode(PWRMODE_M_DEEPSLEEP);
      // this call never returns
    }
    else {
      call HplPXA27xPower.setPWRMode(PWRMODE_M_SLEEP);
    // this call never returns
    }
  }

   
  async command void HalPXA27xSleep.sleepMillis(uint16_t time) {
    int i;
    call HplPXA27xPower.setPWER(PWER_WERTC);
    // let it wrap around itself if necessary
    call HplPXA27xRTC.setPIAR(time); // implicitly resets RTCPICR
    for(i = 0; i < 10; i++); // spin for a bit
    call HplPXA27xRTC.setRTSR(RTSR_PICE);
    for(i = 0; i < 5000; i++); // spin for a bit

    call HplPXA27xPower.setPWRMode(PWRMODE_M_SLEEP);
    // this call never returns
  }

  async command void HalPXA27xSleep.sleepSeconds(uint32_t time) {
    uint32_t hrs = time / 3600;
    uint32_t mins = (time / 60) % 60;
    uint32_t secs = time % 60;
    uint32_t swReg;

      if (hrs > 23) {
	hrs = 23;
	mins = 59;
	secs = 59;
      }

    swReg = ((hrs << 19) | (mins << 13) | (secs << 7));
    doSleep(swReg);
    return;
  }

  async command void HalPXA27xSleep.sleepMinutes(uint32_t time) {
    uint32_t hrs = time / 60;
    uint32_t mins = time % 60;
    uint32_t swReg;

    if (hrs > 23) {
      hrs = 23;
      mins = 59;
    }
    swReg = ((hrs << 19) | (mins << 13));

    doSleep(swReg);
    return;
  }

  async command void HalPXA27xSleep.sleepHours(uint16_t time) {
    uint32_t hrs = time;
    uint32_t swReg;

    if (hrs > 23) {
      hrs = 23;
    }
    swReg = (hrs << 19);

    doSleep(swReg);
    return;
  }
}
