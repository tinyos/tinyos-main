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
 * Build a TEP102 16bits Alarm from a counter and a M16c62p hardware timers.
 * Use the counter to get the "current time" and the hw timer to count down the
 * remaining time for the alarm to be fired.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

generic module M16c62pAlarm16C(typedef precision_tag)
{
  provides interface Alarm<precision_tag, uint16_t> as Alarm @atmostonce();

  uses interface HplM16c62pTimer as ATimer; // Alarm Timer
  uses interface Counter<precision_tag, uint16_t>;
}
implementation
{
  uint16_t alarm = 0;
  async command uint16_t Alarm.getNow()
  {
    return call Counter.get();
  }

  async command uint16_t Alarm.getAlarm()
  {
    return alarm;
  }

  async command bool Alarm.isRunning()
  {
    return call ATimer.isInterruptOn();
  }

  async command void Alarm.stop()
  {
    atomic
    {
      call ATimer.off();
      call ATimer.disableInterrupt();
    }
  }

  async command void Alarm.start( uint16_t dt ) 
  {
    call Alarm.startAt( call Alarm.getNow(), dt);
  }

  async command void Alarm.startAt( uint16_t t0, uint16_t dt )
  {
    atomic
    {
      uint16_t now, elapsed, expires;

      now = call Alarm.getNow();
      elapsed = now - t0;
        
      if (elapsed >= dt)
      {
        expires = 0;
      }
      else
      {
        expires = dt - elapsed - 1;
      }
        
      call ATimer.off();
      call ATimer.set(expires);
      call ATimer.clearInterrupt();
      call ATimer.enableInterrupt();
      call ATimer.on();
    }
  }

  async event void ATimer.fired()
  {
    call Alarm.stop();
    signal Alarm.fired();
  }

  async event void Counter.overflow() {}
}
