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
 */

generic module Alarm32khz32P(uint8_t timer_id) {
  provides interface Alarm<T32khz,uint32_t>;
  provides interface Init;
  uses interface Counter<T32khz,uint32_t>;
  uses interface Jn516WakeTimer;
}
implementation
{
  uint32_t alarm_time = 0;

  async event void Jn516WakeTimer.fired(uint8_t waketimer_id)
  {
    if(waketimer_id == timer_id) {
      signal Alarm.fired();
    }
  }

  command error_t Init.init()
  {
    return call Jn516WakeTimer.init(timer_id);
  }

  async command void Alarm.start( uint32_t dt )
  {
    call Alarm.startAt( call Alarm.getNow() , dt );
  }

  async command void Alarm.stop()
  {
    call Jn516WakeTimer.stop(timer_id);
  }

  async command bool Alarm.isRunning()
  {
    return call Jn516WakeTimer.isRunning(timer_id);
  }

  async command void Alarm.startAt( uint32_t t0, uint32_t dt )
  {
    atomic {
      uint32_t now = call Alarm.getNow();
      uint32_t elapsed = now - t0;
      uint32_t remaining = 0;
      uint32_t alarm_duration = 0;

      if (elapsed >= dt) {
        alarm_duration = 2;
      }
      else {
        remaining = dt - elapsed;
        if (remaining <= 2)
          alarm_duration = 2;
        else
          alarm_duration = remaining;
      }

      alarm_time = now + alarm_duration;

      call Jn516WakeTimer.clearFiredStatus(timer_id);
      call Jn516WakeTimer.start(timer_id,alarm_duration);
    }
  }

  async command uint32_t Alarm.getNow()
  {
    return call Counter.get();
  }

  async command uint32_t Alarm.getAlarm()
  {
    return alarm_time;
  }

  default async event void Alarm.fired()
  {
  }

  async event void Counter.overflow()
  {
  }
}
