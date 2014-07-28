/// $Id: HplAtm128Timer0AsyncC.nc,v 1.1 2008-06-12 14:02:14 klueska Exp $
/*
 * Copyright (c) 2006 Stanford University.
 * All rights reserved.
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
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
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
 * Simple wrapper around the actual timer implementation that automatically
 * wires it to McuSleepC for low-power calculations..
 *
 * @author Philip Levis
 * @author David Gay
 */

#include <Atm128Timer.h>

configuration HplAtm128Timer0AsyncC
{
  provides {
    // 8-bit Timers
    interface HplAtm128Timer<uint8_t>   as Timer;
    interface HplAtm128TimerCtrl8       as TimerCtrl;
    interface HplAtm128Compare<uint8_t> as Compare;
    interface HplAtm128TimerAsync       as TimerAsync;
  }
}
implementation
{
  components HplAtm128Timer0AsyncP;
  components McuSleepC;

  McuSleepC.McuPowerOverride -> HplAtm128Timer0AsyncP;

  Timer = HplAtm128Timer0AsyncP;
  TimerCtrl = HplAtm128Timer0AsyncP;
  Compare = HplAtm128Timer0AsyncP;
  TimerAsync = HplAtm128Timer0AsyncP;
  
  components PlatformInterruptC;
  HplAtm128Timer0AsyncP.PlatformInterrupt -> PlatformInterruptC;
}
