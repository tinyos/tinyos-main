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
 * @author Jasper Buesch <code@tkn.tu-berlin.de>
 * @author Moksha Birk <code@tkn.tu-berlin.de>
 */

#include <AppHardwareApi.h>

module Jn516TimerP
{
  provides interface Jn516Timer;
  provides interface McuPowerOverride;
  uses interface McuPowerState;
}
implementation {

  #define PRESCALE 14

  uint16_t timer0LastValue = 0;
  bool running0 = FALSE;
  bool running1 = FALSE;
  bool running2 = FALSE;
  bool running3 = FALSE;
  bool running4 = FALSE;
  bool repeating0 = FALSE;
  bool repeating1 = FALSE;
  bool repeating2 = FALSE;
  bool repeating3 = FALSE;
  bool repeating4 = FALSE;
  bool initialized0 = FALSE;
  bool initialized1 = FALSE;
  bool initialized2 = FALSE;
  bool initialized3 = FALSE;
  bool initialized4 = FALSE;


  inline void updatePowerState() {
    atomic {
      call McuPowerState.update();
    }
  }

  void task updatePowerStateTask() {
    updatePowerState();
  }

  async command mcu_power_t McuPowerOverride.lowestState() {
    atomic {
      // TODO: Here we neglect running0 and assume this is the counter
      // source for the overlaying timer system, which could be switched
      // off for sleeping.
      // This should be outsourced into a seperate commponents to
      // distinguish its different purpose

      //timer0LastValue = u16AHI_TimerReadCount(E_AHI_TIMER_0);

      if (running1 || running2 || running3 || running4) {
        return JN516_POWER_DOZE;
      } else {
        return JN516_POWER_DEEP_SLEEP;
      }
    }
  }

  void Timer0Callback(uint32 device, uint32 bitmap) {
    atomic {
      if (!repeating0) {
        running0 = FALSE;
        updatePowerState();
      }
      signal Jn516Timer.fired(E_AHI_TIMER_0);
    }
  }

  void Timer1Callback(uint32 device, uint32 bitmap) {
    atomic {
      if (!repeating1) {
        running1 = FALSE;
        updatePowerState();
      }
      signal Jn516Timer.fired(E_AHI_TIMER_1);
    }
  }

  void Timer2Callback(uint32 device, uint32 bitmap) {
    atomic {
      if (!repeating2) {
        running2 = FALSE;
        updatePowerState();
      }
      signal Jn516Timer.fired(E_AHI_TIMER_2);
    }
  }

  void Timer3Callback(uint32 device, uint32 bitmap) {
    atomic {
      if (!repeating3) {
        running3 = FALSE;
        updatePowerState();
      }
      signal Jn516Timer.fired(E_AHI_TIMER_3);
    }
  }

  void Timer4Callback(uint32 device, uint32 bitmap) {
    atomic {
      if (!repeating4) {
        running4 = FALSE;
        updatePowerState();
      }
      signal Jn516Timer.fired(E_AHI_TIMER_4);
    }
  }

  async command error_t Jn516Timer.init(uint8_t timer_id) {
    atomic {
      vAHI_TimerEnable(timer_id,PRESCALE,FALSE,TRUE,FALSE);
      switch(timer_id) {
        case E_AHI_TIMER_0:
          vAHI_Timer0RegisterCallback(Timer0Callback);
          /*if (timer0LastValue != 0) {
            call Jn516Timer.startRepeat(E_AHI_TIMER_0, timer0LastValue);
            timer0LastValue = 0;
            running0 = TRUE;
            repeating0 = TRUE;
          } else {
          */
            running0 = FALSE;
            repeating0 = FALSE;
          //  }
          break;
        case E_AHI_TIMER_1:
          vAHI_Timer1RegisterCallback(Timer1Callback);
          running1 = FALSE;
          repeating1 = FALSE;
          break;
        case E_AHI_TIMER_2:
          vAHI_Timer2RegisterCallback(Timer2Callback);
          running2 = FALSE;
          repeating2 = FALSE;
          break;
        case E_AHI_TIMER_3:
          vAHI_Timer3RegisterCallback(Timer3Callback);
          running3 = FALSE;
          repeating3 = FALSE;
          break;
        case E_AHI_TIMER_4:
          vAHI_Timer4RegisterCallback(Timer4Callback);
          running4 = FALSE;
          repeating4 = FALSE;
          break;
        default:
          return FAIL;
      }
    }
    return SUCCESS;
  }

  async command error_t Jn516Timer.startSingle(uint8_t timer_id,uint16_t duration) {
    atomic {
      switch(timer_id) {
        case E_AHI_TIMER_0:
          running0 = TRUE;
          repeating0 = FALSE;
          break;
        case E_AHI_TIMER_1:
          running1 = TRUE;
          repeating1 = FALSE;
          break;
        case E_AHI_TIMER_2:
          running2 = TRUE;
          repeating2 = FALSE;
          break;
        case E_AHI_TIMER_3:
          running3 = TRUE;
          repeating3 = FALSE;
          break;
        case E_AHI_TIMER_4:
          running4 = TRUE;
          repeating4 = FALSE;
          break;
      }
      vAHI_TimerStartSingleShot(timer_id,0,duration);
      post updatePowerStateTask();
    }
    return SUCCESS;
  }

  async command error_t Jn516Timer.startRepeat(uint8_t timer_id,uint16_t duration) {
    atomic {
      switch(timer_id) {
        case E_AHI_TIMER_0:
          repeating0 = TRUE;
          running0 = TRUE;
          break;
        case E_AHI_TIMER_1:
          repeating1 = TRUE;
          running1 = TRUE;
          break;
        case E_AHI_TIMER_2:
          repeating2 = TRUE;
          running2 = TRUE;
          break;
        case E_AHI_TIMER_3:
          repeating3 = TRUE;
          running3 = TRUE;
          break;
        case E_AHI_TIMER_4:
          repeating4 = TRUE;
          running4 = TRUE;
          break;
      }
      vAHI_TimerStartRepeat(timer_id,0,duration);
      post updatePowerStateTask();
    }
    return SUCCESS;
  }

  async command bool Jn516Timer.isRunning(uint8_t timer_id) {
    switch(timer_id) {
      case E_AHI_TIMER_0:
        return running0;
      case E_AHI_TIMER_1:
        return running1;
      case E_AHI_TIMER_2:
        return running2;
      case E_AHI_TIMER_3:
        return running3;
      case E_AHI_TIMER_4:
        return running4;
      default: return FALSE;
    }
  }

  async command uint16_t Jn516Timer.read(uint8_t timer_id) {
    return u16AHI_TimerReadCount(timer_id);
  }

  async command void Jn516Timer.stop(uint8_t timer_id) {
    atomic {
      switch (timer_id) {
        case E_AHI_TIMER_0:
          running0 = FALSE;
          repeating0 = FALSE;
          break;
        case E_AHI_TIMER_1:
          running1 = FALSE;
          repeating1 = FALSE;
          break;
        case E_AHI_TIMER_2:
          running2 = FALSE;
          repeating2 = FALSE;
          break;
        case E_AHI_TIMER_3:
          running3 = FALSE;
          repeating3 = FALSE;
          break;
        case E_AHI_TIMER_4:
          running4 = FALSE;
          repeating4 = FALSE;
          break;
        default: return; // TODO should a return value be added?
      }
    }
    vAHI_TimerStop(timer_id);
    post updatePowerStateTask();
  }

  async command void Jn516Timer.clearFiredStatus(uint8_t timer_id) {
    u8AHI_TimerFired(timer_id);
  }

}
