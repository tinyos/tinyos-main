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
 * CounterRF23016C provides a 16-bit TRF230 counter.
 * It uses 1 hw timer that counts in PLL_CLOCK_SPEED / 8.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

#include "TimerConfig.h"
#include <RadioConfig.h>

configuration CounterRF23016C
{
  provides interface Counter<TRadio,uint16_t>;
}
implementation
{
  components new M16c62pCounter16C(TRadio) as CounterFrom;
  components new M16c62pTimerBInitC(TMR_TIMER_MODE, M16C_TMR_CS_F8, 0xFFFF, false, true, true) as CounterInit;

  components HplM16c62pTimerC as Timers,
      RealMainP;
  
  CounterFrom.Timer -> Timers.COUNTER_RF23016;
  CounterInit -> Timers.COUNTER_RF23016;
  CounterInit -> Timers.COUNTER_RF23016_CTRL;
  RealMainP.PlatformInit -> CounterInit;
  Counter = CounterFrom;
}
