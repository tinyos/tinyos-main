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
 * @author Jasper Büsch <code@tkn.tu-berlin.de>
 */

#include <AppHardwareApi.h>

//generic configuration AlarmMilli32C(uint8_t timer_id)
generic configuration AlarmMilli32C()
{
  provides interface Init;
  provides interface Alarm<TMilli,uint32_t>;
}
implementation
{
  //components new AlarmMilli16P(timer_id) as AlarmFrom;
  components new AlarmMilli16P(E_AHI_TIMER_1) as AlarmFrom;
  components CounterMilli32C as Counter;
  AlarmFrom.Counter -> Counter;

  components new TransformAlarmC(TMilli,uint32_t,TMilli,uint16_t,0) as Transform;
  Transform.AlarmFrom -> AlarmFrom;
  Transform.Counter -> Counter;

  Init = AlarmFrom;
  Alarm = Transform;

  components Jn516TimerP;
  AlarmFrom.Jn516Timer -> Jn516TimerP;

  components McuSleepC;
  Jn516TimerP.McuPowerState -> McuSleepC;
  McuSleepC.McuPowerOverride -> Jn516TimerP;
}
