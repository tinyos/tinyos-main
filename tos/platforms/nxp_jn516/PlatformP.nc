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
 * @author Sanjeet Raj Pandey <code@tkn.tu-berlin.de>
 * @author Moksha Birk <code@tkn.tu-berlin.de>
 * @author Jasper Buesch <code@tkn.tu-berlin.de>
 */

#include <jendefs.h>
#include <AppHardwareApi.h>
#include "jn516hardware.h"

module PlatformP
{
  provides interface Init;
  uses interface Init as LedsInit;
  uses interface Init as Jn516TimerInit;
  uses interface Init as Jn516WakeTimerInit;
  uses interface Scheduler;
  uses interface Init as Uart0Init;
  uses interface Init as CounterInit;
  uses interface StdControl as Uart0Control;
  uses interface Jn516Timer;
}
implementation {

enum {  // power status bit positions
  JN516X_COMPLETED_SLEEP_WAKE_CYCLE = 0,
  JN516X_RAM_CONTENTS_RETAINED_DURING_SLEEP = 1,
  JN516X_ANALOGUE_POWER_DOMAIN_SWITCHED_ON = 2,
  JN516X_PROTOCOL_LOGIC_OPERATIONAL = 3,
  JN516X_WATCHDOG_CAUSED_RESTART = 7,
  JN516X_WAKE_CLK_READY = 10,
  JN516X_COMPLETED_DEEP_SLEEP = 11
};

  extern void TimerCallback(uint32 device, uint32 bitmap);

  // ------------------------------------------
  inline void warmStart() {
    // We are waking up from a sleep cycle!
    //__nesc_enable_interrupt();  // For some reason this line breaks everything

    // Now give the interrupt the chance to post a new task
    // The actual wake up is also triggered when the GIE is disabled

    call LedsInit.init();


    call Jn516TimerInit.init();


    call CounterInit.init();
    call Uart0Init.init();
    call Uart0Control.start();

    u32AHI_Init();
    MICRO_ENABLE_INTERRUPTS();
    call Scheduler.taskLoop();
  }
  // ------------------------------------------

  command error_t Init.init() {
    uint16_t powerStatus;

    /* Turn off debugger */
    *(uint32_t *)0x020000a0 = 0;

    #ifdef WATCHDOG_ENABLED
    /* Disable watchdog if enabled by default */
    vAHI_WatchdogStop();
    #endif

    powerStatus = u16AHI_PowerStatus();
    if (powerStatus & (1 << JN516X_COMPLETED_SLEEP_WAKE_CYCLE)) {
      if (powerStatus & (1 << JN516X_RAM_CONTENTS_RETAINED_DURING_SLEEP)) {
        warmStart();
        // this line will never be reached, because warmStart spins
      }
    }

    u32AHI_Init();                              /* initialise hardware API */

    // wait for JN516X to move onto 32MHz Crystal
    while (bAHI_GetClkSource() == TRUE);

    vAHI_DioSetPullup(0xffffffff, 0x00000000);  /* turn all pullups on      */

    // set the flash access timings to their optimum
    vAHI_OptimiseWaitStates();

    call Jn516WakeTimerInit.init();
    call Jn516TimerInit.init();
    call LedsInit.init();

    vAHI_DioSetPullup(0x00000000, 0xffffffff);

    return SUCCESS;
  }

  async event void Jn516Timer.fired(uint8_t timer_id) {}

  default command error_t LedsInit.init() { return SUCCESS; }

}
