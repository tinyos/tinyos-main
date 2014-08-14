/*
 * Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * The TOSSIM implementation of the Atm128 Timer2. It is built from a
 * timer-specific counter component and a generic compare
 * component. The counter component has an additional simulation-only
 * interface to let the compare component know when its state has
 * changed (e.g., TCNTX was set).
 *
 * @date November 22 2005
 *
 * @author Philip Levis <pal@cs.stanford.edu>
 * @author Martin Turon <mturon@xbow.com>
 * @author David Gay <dgay@intel-research.net>
 */

// $Id: HplAtm128Timer2C.nc,v 1.2 2010-06-29 22:07:51 scipio Exp $/// $Id: HplAtm128Timer2C.nc,


#include <Atm128Timer.h>

configuration HplAtm128Timer2C
{
  provides {
    // 8-bit Timers
    interface HplAtm128Timer<uint8_t>   as Timer2;
    interface HplAtm128TimerCtrl8       as Timer2Ctrl;
    interface HplAtm128Compare<uint8_t> as Compare2;
  }
  uses interface ThreadScheduler;
}
implementation {
  components HplAtm128Counter0C, new HplAtm128CompareC(uint8_t,
						 ATM128_OCR2,
						 ATM128_TIMSK,
						 OCIE2,
						 ATM128_TIFR,
						 OCF2);

  Timer2 = HplAtm128Counter2C;
  Timer2Ctrl = HplAtm128Counter2C;
  Compare2 = HplAtm128CompareC;

  HplAtm128CompareC.Timer -> HplAtm128Counter2C;
  HplAtm128CompareC.TimerCtrl -> HplAtm128Counter2C;
  HplAtm128CompareC.Notify -> HplAtm128Counter2C;
  
  components TinyThreadSchedulerC;
  HplAtm128Counter0C.ThreadScheduler -> TinyThreadSchedulerC;
  HplAtm128CompareC.ThreadScheduler -> TinyThreadSchedulerC;
}
