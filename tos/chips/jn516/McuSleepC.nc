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
 * @author Jasper Buesch <code@tkn.tu-berlin.de>
 * @author Moksha Birk <code@tkn.tu-berlin.de>
 */

#include "AppHardwareApi_JN516x.h"

module McuSleepC @safe() {
  provides {
    interface McuSleep;
    interface McuPowerState;
  }
  uses {
    interface McuPowerOverride;
  }
}
implementation {

  //#define LOWEST_POWER_STATE_ALLOWED JN516_POWER_SLEEP
  /* Real sleep is not yet fully supported.
     Not all hardware states are covered and the platform
     sometimes goes to sleep and loses pending interrupts,
     which leads to corrupted system state */

  #define LOWEST_POWER_STATE_ALLOWED JN516_POWER_DOZE

  bool dirty = TRUE;
  mcu_power_t powerState = JN516_POWER_ACTIVE;

  mcu_power_t getPowerState() {
    // TODO: Check all the conditions and set correct state here
    mcu_power_t pState = JN516_POWER_SLEEP;

    // TODO: Sleeping doesn't work yet on the Jennic
    /* The node currently wakes up and the task loop is
    also restarted (see PlatformP.nc), but the interrupt
    is actually not handled, which leaves the node in a dangling state */
    pState = LOWEST_POWER_STATE_ALLOWED;
    return pState;
  }

  void computePowerState() {
    atomic powerState = mcombine(getPowerState(),
        call McuPowerOverride.lowestState());
  }

  async command void McuSleep.sleep() {
    teAHI_SleepMode sleepMode = E_AHI_SLEEP_OSCON_RAMON;
    mcu_power_t tmp_state;

    atomic {
      if (dirty) {
        computePowerState();
        dirty = 0;
      }
      tmp_state = powerState;
    }

    switch (tmp_state) {
      case JN516_POWER_ACTIVE:
        break;
      case JN516_POWER_DOZE:
        break;
      case JN516_POWER_SLEEP:
        sleepMode = E_AHI_SLEEP_OSCON_RAMON;
        break;
      case JN516_POWER_DEEP_SLEEP:
        sleepMode = E_AHI_SLEEP_DEEP;
        break;
    }
    if ((tmp_state == JN516_POWER_SLEEP) || (tmp_state == JN516_POWER_DEEP_SLEEP)) {
      vAHI_Sleep(sleepMode);
      // we will never reach this line, because sleep causes a reset
    } else if (tmp_state == JN516_POWER_DOZE) {
      vAHI_CpuDoze();
    }
    // This line is called after non-sleep or doze
    __nesc_enable_interrupt();
    // if there is an int waiting, it will hit right here!
    // going back into an atomic block we have to block irqs again
    __nesc_disable_interrupt();
  }

  async command void McuSleep.irq_preamble()  { }
  async command void McuSleep.irq_postamble() { }
  async command void McuPowerState.update() {
    atomic dirty = 1;
  }

  default async command mcu_power_t McuPowerOverride.lowestState() {
   return JN516_POWER_DEEP_SLEEP;
 }
}
