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
 * AlarmMicro16C provides a 16-bit TMicro alarm.
 * It uses 1 hw timer that is used as a alarm.
 * 
 * NOTE: It uses the same source clock as the CounterMicro16C.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

#include "TimerConfig.h"

configuration AlarmMicro16C
{
  provides interface Alarm<TMicro,uint16_t>;
}
implementation
{
  components new M16c62pAlarm16C(TMicro) as AlarmFrom;
  components new M16c62pTimerAInitC(TMR_COUNTER_MODE, M16C_TMRA_TES_TA_PREV, 0, false, false, false) as AlarmInit;

  components HplM16c62pTimerC as Timers,
      CounterMicro16C,
      RealMainP;

  AlarmFrom -> Timers.ALARM_MICRO16;
  AlarmFrom.Counter -> CounterMicro16C;

  AlarmInit -> Timers.ALARM_MICRO16;
  AlarmInit -> Timers.ALARM_MICRO16_CTRL;
  RealMainP.PlatformInit -> AlarmInit.Init;
  Alarm = AlarmFrom;
}
  

