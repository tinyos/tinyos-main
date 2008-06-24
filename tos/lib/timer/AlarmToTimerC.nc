//$Id: AlarmToTimerC.nc,v 1.6 2008-06-24 05:32:31 regehr Exp $

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

#include "Timer.h"

/**
 * AlarmToTimerC converts a 32-bit Alarm to a Timer.  
 *
 * <p>See TEP102 for more details.
 * @param precision_tag A type indicating the precision of the Alarm and
 * Timer being converted.
 *
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 */

generic module AlarmToTimerC(typedef precision_tag) @safe()
{
  provides interface Timer<precision_tag>;
  uses interface Alarm<precision_tag,uint32_t>;
}
implementation
{
  // there might be ways to save bytes here, but I'll do it in the obviously
  // right way for now
  uint32_t m_dt;
  bool m_oneshot;

  void start(uint32_t t0, uint32_t dt, bool oneshot)
  {
    m_dt = dt;
    m_oneshot = oneshot;
    call Alarm.startAt(t0, dt);
  }

  command void Timer.startPeriodic(uint32_t dt)
  { start(call Alarm.getNow(), dt, FALSE); }

  command void Timer.startOneShot(uint32_t dt)
  { start(call Alarm.getNow(), dt, TRUE); }

  command void Timer.stop()
  { call Alarm.stop(); }

  task void fired()
  { 
    if(m_oneshot == FALSE)
      start(call Alarm.getAlarm(), m_dt, FALSE);
    signal Timer.fired();
  }

  async event void Alarm.fired()
  { post fired(); }

  command bool Timer.isRunning()
  { return call Alarm.isRunning(); }

  command bool Timer.isOneShot()
  { return m_oneshot; }

  command void Timer.startPeriodicAt(uint32_t t0, uint32_t dt)
  { start(t0, dt, FALSE); }

  command void Timer.startOneShotAt(uint32_t t0, uint32_t dt)
  { start(t0, dt, TRUE); }

  command uint32_t Timer.getNow()
  { return call Alarm.getNow(); }

  command uint32_t Timer.gett0()
  { return call Alarm.getAlarm() - m_dt; }

  command uint32_t Timer.getdt()
  { return m_dt; }
}

