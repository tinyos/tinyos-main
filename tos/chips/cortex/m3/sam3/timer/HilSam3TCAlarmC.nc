/*
 * Copyright (c) 2010 CSIRO Australia
 * All rights reserved.
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
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * HilSam3TCAlarmC is a generic component that wraps the SAM3U HPL timers and
 * compares into a TinyOS Alarm.
 *
 * @author Thomas Schmid
 * @author Kevin Klues
 * @see  Please refer to TEP 102 for more information about this component and its
 *          intended use.
 */

generic module HilSam3TCAlarmC(typedef frequency_tag, uint16_t freq_divisor) @safe()
{
  provides 
  {
      interface Init;
      interface Alarm<frequency_tag,uint16_t> as Alarm;
  }
  uses
  {
      interface HplSam3TCChannel;
      interface HplSam3TCCompare;
  }
}
implementation
{
  command error_t Init.init()
  {
    call HplSam3TCCompare.disable();
    return SUCCESS;
  }

  async command void Alarm.start( uint16_t dt )
  {
    call Alarm.startAt( call Alarm.getNow(), dt );
  }

  async command void Alarm.stop()
  {
    call HplSam3TCCompare.disable();
  }

  async event void HplSam3TCCompare.fired()
  {
    call HplSam3TCCompare.disable();
    signal Alarm.fired();
  }

  async command bool Alarm.isRunning()
  {
    return call HplSam3TCCompare.isEnabled();
  }

  async command void Alarm.startAt( uint16_t t0, uint16_t dt )
  {
    uint32_t freq = call HplSam3TCChannel.getTimerFrequency();
    dt = (dt*freq)/(uint32_t)freq_divisor + 1;
    atomic
    {
      uint16_t now = call HplSam3TCChannel.get();
      uint16_t elapsed = now - t0;
      if( elapsed >= dt )
      {
        call HplSam3TCCompare.setEventFromNow(2);
      }
      else
      {
        uint16_t remaining = dt - elapsed;
        if( remaining <= 2 )
          call HplSam3TCCompare.setEventFromNow(2);
        else
          call HplSam3TCCompare.setEvent( now+remaining );
      }
      call HplSam3TCCompare.clearPendingEvent();
      call HplSam3TCCompare.enable();
    }
  }

  async command uint16_t Alarm.getNow()
  {
    return call HplSam3TCChannel.get();
  }

  async command uint16_t Alarm.getAlarm()
  {
    return call HplSam3TCCompare.getEvent();
  }

  async event void HplSam3TCChannel.overflow()
  {
  }
}

