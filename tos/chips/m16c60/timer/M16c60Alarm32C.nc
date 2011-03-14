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
 * Build a TEP102 32bit Alarm from a counter and two M16c60 hardware timers.
 * Use the counter to get the "current time" and the hw timer to count down the
 * remaining time for the alarm to be fired.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

generic module M16c60Alarm32C(typedef precision_tag)
{
  provides interface Alarm<precision_tag, uint32_t> as Alarm @atmostonce();

  uses interface HplM16c60Timer as ATimerLow; // Alarm Timer low bits
  uses interface HplM16c60Timer as ATimerHigh; // Alarm Timer high bits
  uses interface Counter<precision_tag, uint32_t>;
}
implementation
{
  uint32_t alarm = 0;

  async command uint32_t Alarm.getNow()
  {
    return call Counter.get();
  }

  async command uint32_t Alarm.getAlarm()
  {
    atomic return alarm;
  }

  async command bool Alarm.isRunning()
  {
      return call ATimerLow.isInterruptOn() || call ATimerHigh.isInterruptOn();
  }

  async command void Alarm.stop()
  {
    atomic
    {
      call ATimerLow.off();
      call ATimerLow.disableInterrupt();
      call ATimerHigh.off();
      call ATimerHigh.disableInterrupt();
    }
  }

  async command void Alarm.start( uint32_t dt ) 
  {
    call Alarm.startAt( call Alarm.getNow(), dt);
  }

  async command void Alarm.startAt( uint32_t t0, uint32_t dt )
  {
    atomic
    {
      uint32_t now, elapsed, expires;

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
      
      alarm = expires;

      call Alarm.stop();
      
      if (expires <= 0xFFFF)
      {
        call ATimerLow.set((uint16_t)expires);
        call ATimerLow.clearInterrupt();
        call ATimerLow.enableInterrupt();
        call ATimerLow.on();
      }
      else
      {
        uint16_t high_bits;

        high_bits = expires >> 16;
        call ATimerHigh.set(high_bits-1);
        call ATimerHigh.clearInterrupt();
        call ATimerHigh.enableInterrupt();
        call ATimerHigh.on();
        call ATimerLow.set(0xFFFF);
        call ATimerLow.on();
      }
    }
  }

  async event void ATimerLow.fired()
  {
    call Alarm.stop();
    signal Alarm.fired();
  }
  
  async event void ATimerHigh.fired()
  {
    atomic
    {
      uint16_t remaining;
      
      call Alarm.stop();
      
      // All the high bits should have been cleared so only the
      // low should remain.
      remaining = (uint16_t)(alarm & 0xFFFF);
      if (remaining != 0)
      {
        call ATimerLow.set(remaining);
        call ATimerLow.clearInterrupt();
        call ATimerLow.enableInterrupt();
        call ATimerLow.on();
      }
      else
      {
        signal Alarm.fired();
      }
    }
  }
  async event void Counter.overflow() {}
}
