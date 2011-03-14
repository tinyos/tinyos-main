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
 * AlarmCounterMilli32C provides a 32-bit TMilli alarm and counter.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 * @see  Please refer to TEP 102 for more information about this component.
 */

#include "TimerConfig.h"

configuration AlarmCounterMilli32C
{
  provides interface Counter<TMilli,uint32_t>;
  provides interface Alarm<TMilli,uint32_t>;
  provides interface Init;
}
implementation
{
  components new M16c60Counter16C(TMilli) as CounterFrom;
  components new M16c60TimerBInitC(TMR_COUNTER_MODE, M16C_TMRB_CTR_ES_TBj, 0xFFFF, true, true, false) as CounterInit;
  components new M16c60TimerBInitC(TMR_TIMER_MODE, M16C_TMR_CS_F1_2, (1000 * MAIN_CRYSTAL_SPEED) - 1, false, true, true) as CounterSourceInit;
  components new TransformCounterC(TMilli,uint32_t, TMilli,uint16_t, 0,uint16_t) as TCounter;
  
  components new M16c60Alarm16C(TMilli) as AlarmFrom;
  components new M16c60TimerAInitC(TMR_COUNTER_MODE, M16C_TMRA_TES_TA_PREV, 0, false, false, false) as AlarmInit;
  components new M16c60TimerAInitC(TMR_TIMER_MODE, M16C_TMR_CS_F1_2, (1000 * MAIN_CRYSTAL_SPEED) - 1, false, true, true) as AlarmSourceInit;
  components new TransformAlarmC(TMilli,uint32_t,TMilli,uint16_t,0) as TAlarm;
  

  components HplM16c60TimerC as Timers;

  // Counter
  CounterFrom.Timer -> Timers.COUNTER_MILLI32;
  CounterInit -> Timers.COUNTER_MILLI32;
  CounterInit -> Timers.COUNTER_MILLI32_CTRL;
  Init = CounterInit;
  CounterSourceInit -> Timers.COUNTER_MILLI32_SOURCE;
  CounterSourceInit -> Timers.COUNTER_MILLI32_SOURCE_CTRL;
  Init = CounterSourceInit;

  // Alarm
  AlarmFrom -> Timers.ALARM_MILLI32;
  AlarmFrom.Counter -> CounterFrom;
  AlarmInit -> Timers.ALARM_MILLI32;
  AlarmInit -> Timers.ALARM_MILLI32_CTRL;
  Init = AlarmInit.Init;
  AlarmSourceInit -> Timers.ALARM_MILLI32_SOURCE;
  AlarmSourceInit -> Timers.ALARM_MILLI32_SOURCE_CTRL;
  Init = AlarmSourceInit;

  // Transformations
  TCounter.CounterFrom -> CounterFrom;
  Counter = TCounter;
  TAlarm.AlarmFrom -> AlarmFrom;
  TAlarm.Counter -> TCounter;
  Alarm = TAlarm;
}

