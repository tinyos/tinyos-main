//$Id: Msp430AlarmC.nc,v 1.5 2008/06/24 04:07:29 regehr Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
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

