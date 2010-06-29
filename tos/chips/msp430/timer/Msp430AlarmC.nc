//$Id: Msp430AlarmC.nc,v 1.6 2010-06-29 22:07:45 scipio Exp $

/* Copyright (c) 2000-2003 The Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Msp430Alarm is a generic component that wraps the MSP430 HPL timers and
 * compares into a TinyOS Alarm.
 *
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 * @see  Please refer to TEP 102 for more information about this component and its
 *          intended use.
 */

generic module Msp430AlarmC(typedef frequency_tag) @safe()
{
  provides interface Init;
  provides interface Alarm<frequency_tag,uint16_t> as Alarm;
  uses interface Msp430Timer;
  uses interface Msp430TimerControl;
  uses interface Msp430Compare;
}
implementation
{
  command error_t Init.init()
  {
    call Msp430TimerControl.disableEvents();
    call Msp430TimerControl.setControlAsCompare();
    return SUCCESS;
  }

  async command void Alarm.start( uint16_t dt )
  {
    call Alarm.startAt( call Alarm.getNow(), dt );
  }

  async command void Alarm.stop()
  {
    call Msp430TimerControl.disableEvents();
  }

  async event void Msp430Compare.fired()
  {
    call Msp430TimerControl.disableEvents();
    signal Alarm.fired();
  }

  async command bool Alarm.isRunning()
  {
    return call Msp430TimerControl.areEventsEnabled();
  }

  async command void Alarm.startAt( uint16_t t0, uint16_t dt )
  {
    atomic
    {
      uint16_t now = call Msp430Timer.get();
      uint16_t elapsed = now - t0;
      if( elapsed >= dt )
      {
        call Msp430Compare.setEventFromNow(2);
      }
      else
      {
        uint16_t remaining = dt - elapsed;
        if( remaining <= 2 )
          call Msp430Compare.setEventFromNow(2);
        else
          call Msp430Compare.setEvent( now+remaining );
      }
      call Msp430TimerControl.clearPendingInterrupt();
      call Msp430TimerControl.enableEvents();
    }
  }

  async command uint16_t Alarm.getNow()
  {
    return call Msp430Timer.get();
  }

  async command uint16_t Alarm.getAlarm()
  {
    return call Msp430Compare.getEvent();
  }

  async event void Msp430Timer.overflow()
  {
  }
}

