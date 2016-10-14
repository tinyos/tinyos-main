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

generic module AlarmMilli16P(uint8_t timer_id) {
  provides interface Alarm<TMilli,uint16_t>;
  provides interface Init;
  uses interface Counter<TMilli,uint32_t>;
  uses interface Jn516Timer;
}
implementation
{
  uint16_t alarm_time = 0;

  async event void Jn516Timer.fired(uint8_t jn516timer_id)
  {
    if(jn516timer_id == timer_id) {
      signal Alarm.fired();
    }
  }

  command error_t Init.init()
  {
    return call Jn516Timer.init(timer_id);
  }

  async command void Alarm.start( uint16_t dt )
  {
    call Alarm.startAt( call Alarm.getNow() , dt );
  }

  async command void Alarm.stop()
  {
    call Jn516Timer.stop(timer_id);
  }

  async command bool Alarm.isRunning()
  {
    return call Jn516Timer.isRunning(timer_id);
  }

  async command void Alarm.startAt( uint16_t t0, uint16_t dt )
  {
    atomic {
      uint16_t now = call Alarm.getNow();
      uint16_t elapsed = now - t0;
      uint16_t remaining = 0;
      uint16_t alarm_duration = 0;

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

      call Jn516Timer.clearFiredStatus(timer_id);
      call Jn516Timer.startSingle(timer_id,alarm_duration);
    }
  }

  async command uint16_t Alarm.getNow()
  {
    return (uint16_t)call Counter.get();
  }

  async command uint16_t Alarm.getAlarm()
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
