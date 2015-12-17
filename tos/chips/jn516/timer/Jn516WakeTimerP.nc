/**
 * Copyright (c) 2015, Technische Universitaet Berlin
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
 * @author Tim Bormann <code@tkn.tu-berlin.de>
 * @author Moksha Birk <code@tkn.tu-berlin.de>
 * @author Jasper Buesch <code@tkn.tu-berlin.de>
 */

#include <AppHardwareApi.h>

module Jn516WakeTimerP
{
  provides interface Jn516WakeTimer;
}
implementation {

  bool running0;
  bool running1;

  void TimerCallback(uint32 device, uint32 bitmap) {
    atomic {
      if(bitmap & E_AHI_SYSCTRL_WK0_MASK) {
        running0 = FALSE;
        signal Jn516WakeTimer.fired(E_AHI_WAKE_TIMER_0);
      } else
      if(bitmap & E_AHI_SYSCTRL_WK1_MASK) {
        running1 = FALSE;
        signal Jn516WakeTimer.fired(E_AHI_WAKE_TIMER_1);
      }
    }
  }

  async command error_t Jn516WakeTimer.init(uint8_t waketimer_id) {
    atomic {
      bAHI_Set32KhzClockMode(E_AHI_XTAL);
      vAHI_WakeTimerEnable(waketimer_id,TRUE);
      vAHI_SysCtrlRegisterCallback(TimerCallback);
      switch (waketimer_id) {
        case E_AHI_WAKE_TIMER_0: running0 = FALSE; break;
        case E_AHI_WAKE_TIMER_1: running1 = FALSE; break;
      }
    }
    return SUCCESS;
  }

  async command error_t Jn516WakeTimer.start(uint8_t waketimer_id,uint32_t duration) {
    atomic {
      switch (waketimer_id) {
        case E_AHI_WAKE_TIMER_0: running0 = TRUE; break;
        case E_AHI_WAKE_TIMER_1: running1 = TRUE; break;
      }
      vAHI_WakeTimerStartLarge(waketimer_id,duration);
    }
    return SUCCESS;
  }

  async command bool Jn516WakeTimer.isRunning(uint8_t waketimer_id) {
      switch (waketimer_id) {
        case E_AHI_WAKE_TIMER_0: return running0;
        case E_AHI_WAKE_TIMER_1: return running1;
        default: return FALSE;
      }
  }

  async command uint64_t Jn516WakeTimer.read(uint8_t waketimer_id) {
    return u64AHI_WakeTimerReadLarge(waketimer_id);
  }

  async command void Jn516WakeTimer.stop(uint8_t waketimer_id) {
    vAHI_WakeTimerStop(waketimer_id);
  }

  async command void Jn516WakeTimer.clearFiredStatus(uint8_t waketimer_id) {
    u8AHI_WakeTimerFiredStatus();
  }

}
