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
 *
 *
 * @author Kaisen Lin
 * @author Phil Buonadonna
 */

module HalPXA27xWatchdogM {
  provides interface HalPXA27xWatchdog;
  uses interface HplPXA27xOSTimerWatchdog;
  uses interface HplPXA27xOSTimer;
}

implementation {
  uint32_t gResetInterval;

  async command void HalPXA27xWatchdog.enable(uint32_t interval) {
    uint32_t curMatch;
    atomic {
      gResetInterval = interval;
      curMatch = call HplPXA27xOSTimer.getOSCR();
      curMatch = (curMatch + gResetInterval) % 0xFFFFFFFF;
      call HplPXA27xOSTimer.setOSMR(curMatch);
      call HplPXA27xOSTimerWatchdog.enableWatchdog();
    }
  }

  async command void HalPXA27xWatchdog.tickle() {
    uint32_t curMatch;
    atomic {
      curMatch = call HplPXA27xOSTimer.getOSCR();
      curMatch = (curMatch + gResetInterval) % 0xFFFFFFFF;
      call HplPXA27xOSTimer.setOSMR(curMatch);
    }
  }

  // This won't ever get called. Rather, the system will reset.
  async event void HplPXA27xOSTimer.fired() {}

}
