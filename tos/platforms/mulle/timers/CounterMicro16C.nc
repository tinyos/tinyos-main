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
 * CounterMicro16C provides a 16-bit TMicro counter.
 * It uses 2 hw timers, one generates a micro tick and the other
 * counts the micro ticks.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 * @see  Please refer to TEP 102 for more information about this component.
 */

#include "TimerConfig.h"

configuration CounterMicro16C
{
  provides interface Counter<TMicro,uint16_t>;
}
implementation
{
  // Counter
  components new M16c60Counter16C(TMicro) as CounterFrom;
  components new M16c60TimerAInitC(TMR_COUNTER_MODE, M16C_TMRA_TES_TA_NEXT, 0xFFFF, true, true, true) as CounterInit;
  
  // Source
  components new M16c60TimerAInitC(TMR_TIMER_MODE, M16C_TMR_CS_F1_2, (MAIN_CRYSTAL_SPEED - 1), false, true, true) as TimerSourceInit;
  
  components HplM16c60TimerC as Timers,
      RealMainP, McuSleepC;

  // Counter
  CounterFrom.Timer -> Timers.COUNTER_MICRO16;
  CounterInit -> Timers.COUNTER_MICRO16;
  CounterInit -> Timers.COUNTER_MICRO16_CTRL;
  RealMainP.PlatformInit -> CounterInit;
  Counter = CounterFrom;

  // Timer source
  TimerSourceInit -> Timers.MICRO16_SOURCE;
  TimerSourceInit -> Timers.MICRO16_SOURCE_CTRL;
  RealMainP.PlatformInit -> TimerSourceInit;
  
}
