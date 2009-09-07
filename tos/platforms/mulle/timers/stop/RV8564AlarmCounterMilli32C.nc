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
 * RV8564AlarmCounterMilli32C provides a 32-bit TMilli alarm and counter.
 * The counter and alarm is driven by the RV8564 chip on Mulle. This
 * allows the M16c/62p mcu to be put into stop mode even when the timers
 * are running.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 * @see  Please refer to TEP 102 for more information about this component.
 */

#include "TimerConfig.h"

configuration RV8564AlarmCounterMilli32C
{
  provides interface Counter<TMilli,uint32_t>;
  provides interface Alarm<TMilli,uint32_t>;
  provides interface Init;
}
implementation
{
  components new M16c62pCounter32C(TMilli) as CounterFrom;
  components new M16c62pTimerAInitC(TMR_COUNTER_MODE, M16C_TMRA_TES_TB2, 0xFFFF, false, true, true) as CounterInit1;
  components new M16c62pTimerAInitC(TMR_COUNTER_MODE, M16C_TMRA_TES_TA_PREV, 0xFFFF, true, true, true) as CounterInit2;
  
  components new M16c62pAlarm32C(TMilli) as AlarmFrom;
  components new M16c62pTimerBInitC(TMR_COUNTER_MODE, M16C_TMRB_CTR_ES_TBj, 0, false, false, true) as AlarmInit1;
  components new M16c62pTimerBInitC(TMR_COUNTER_MODE, M16C_TMRB_CTR_ES_TBj, 0, false, false, true) as AlarmInit2;
  
  components new M16c62pTimerBInitC(TMR_COUNTER_MODE, M16C_TMRB_CTR_ES_TBiIN, 0, false, true, true) as TimerSourceInit;

  components HplM16c62pTimerC as Timers,
      RV8564AlarmCounterMilli32P,
      HplM16c62pInterruptC as Irqs,
      HplM16c62pGeneralIOC as IOs;

  // Setup the IO pin that RV8564 generates the clock to.
  RV8564AlarmCounterMilli32P -> IOs.PortP92;
  Init = RV8564AlarmCounterMilli32P;
  
  // Counter
  CounterFrom.TimerLow -> Timers.COUNTER_MILLI32_LOW;
  CounterFrom.TimerHigh -> Timers.COUNTER_MILLI32_HIGH;
  CounterInit1 -> Timers.COUNTER_MILLI32_LOW;
  CounterInit1 -> Timers.COUNTER_MILLI32_LOW_CTRL;
  CounterInit2 -> Timers.COUNTER_MILLI32_HIGH;
  CounterInit2 -> Timers.COUNTER_MILLI32_HIGH_CTRL;
  Init = CounterInit1;
  Init = CounterInit2;
  Counter = CounterFrom;

  // Alarm
  AlarmFrom.ATimerLow -> Timers.ALARM_MILLI32_LOW;
  AlarmFrom.ATimerHigh -> Timers.ALARM_MILLI32_HIGH;
  AlarmFrom.Counter -> CounterFrom;
  AlarmInit1 -> Timers.ALARM_MILLI32_LOW;
  AlarmInit1 -> Timers.ALARM_MILLI32_LOW_CTRL;
  AlarmInit2 -> Timers.ALARM_MILLI32_HIGH;
  AlarmInit2 -> Timers.ALARM_MILLI32_HIGH_CTRL;
  Init = AlarmInit1;
  Init = AlarmInit2;
  Alarm = AlarmFrom;

  // Timer source
  TimerSourceInit -> Timers.MILLI32_SOURCE_RV8564;
  TimerSourceInit -> Timers.MILLI32_SOURCE_RV8564_CTRL;
  Init = TimerSourceInit;
}

