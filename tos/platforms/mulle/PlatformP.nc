/*
 * Copyright (c) 2009 Communication Group and Eislab at
 * Lulea University of Technology
 *
 * Contact: Laurynas Riliskis, LTU
 * Mail: laurynas.riliskis@ltu.se
 * All rights reserved.
 *
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of Communication Group at Lulea University of Technology
 *   nor the names of its contributors may be used to endorse or promote
 *    products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Mulle platform initialization code.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

#include "hardware.h"
#include "rv8564.h"

module PlatformP
{
  provides interface Init;
  uses interface Init as SubInit;
  uses interface M16c62pControl;
  uses interface StopModeControl;
#ifdef ENABLE_STOP_MODE
  uses interface RV8564 as RTC;
#endif
}

implementation
{
  command error_t Init.init()
  {
    error_t ok = SUCCESS;
    
    ok = call M16c62pControl.init();
#ifdef ENABLE_STOP_MODE
    call StopModeControl.allowStopMode(true);
    // Activate the RTC and set it to output 1024 tics on the CLKOUT pin.
    call RTC.on();
    call RTC.enableCLKOUT();
    call RTC.writeRegister(RV8564_CLKF, 0x81);
#else
    call StopModeControl.allowStopMode(false);
#endif
    // Init the M16c/62p to run at 10MHz.
    ok = ecombine (ok, call M16c62pControl.defaultSystemClock(MCU_SPEED_10MHz));

    // Sub components initialization.
    ok = ecombine(ok, call SubInit.init());

    return SUCCESS;
  }
#ifdef ENABLE_STOP_MODE
  async event void RTC.fired() {}
  async event void RTC.readRegisterDone(uint8_t val, uint8_t reg) {}
  async event void RTC.writeRegisterDone(uint8_t reg) {}
#endif
}
