//$Id: VirtualizeTimerC.nc,v 1.6 2006-08-10 00:11:41 idgay Exp $

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
 * VirtualizeTimerC uses a single Timer to create up to 255 virtual timers.
 *
 * <p>See TEP102 for more details.
 *
 * @param precision_tag A type indicating the precision of the Timer being 
 *   virtualized.
 * @param max_timers Number of virtual timers to create.
 *
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 */

generic module VirtualizeTimerC(typedef precision_tag, int max_timers)
{
  provides interface Timer<precision_tag> as Timer[uint8_t num];
  uses interface Timer<precision_tag> as TimerFrom;
}
implementation
{
  enum
  {
    NUM_TIMERS = max_timers,
    END_OF_LIST = 255,
  };

  typedef struct
  {
    uint32_t t0;
    uint32_t dt;
    bool isoneshot : 1;
    bool isrunning : 1;
    bool _reserved : 6;
  } Timer_t;

  Timer_t m_timers[NUM_TIMERS];

  enum {
    /* bitmask */
    S_TIMER_RUNNING = 1,
    S_TIMER_CHANGED = 2
  };
  bool state;

  task void executeTimersNow();

  void executeTimers(uint32_t then)
  {
    int32_t min_remaining = (1UL<<31)-1; //max signed int32_t
    bool min_remaining_isset = FALSE;
    int num;

    /* We always come here with the timer stopped */
    state = 0;

    for(num=0; num<NUM_TIMERS; num++)
    {
      Timer_t* timer = &m_timers[num];

      if (timer->isrunning)
      {
	// Calculate "remaining" before the timer is fired.  If a timer
	// restarts itself in a fired event, then we 1) need a consistent
	// "remaining" value to work with, and no worries because 2) all
	// start commands post executeTimersNow, so the timer will be
	// recomputed later, anyway.

	uint32_t elapsed = then - timer->t0;
	int32_t remaining = timer->dt - elapsed;

	if (remaining <= 0)
	{
	  if (timer->isoneshot)
	  {
	    timer->isrunning = FALSE;
	  }
	  else
	  {
	    // The remaining time is non-positive (the timer had fired).
	    // So add dt to convert it to remaining for the next event.
	    timer->t0 += timer->dt;
	    remaining += timer->dt; 
	  }

	  signal Timer.fired[num]();
	}

	// check isrunning in case the timer was stopped in the fired
	// event or this was a one shot timer; note that a one shot
	// timer that was restarted in its fired event will push us
	// through here with remaining <= 0, but we're already scheduled
	// an executeTimersTask in that case (and suppressed setting
	// TimerFrom)
	if (timer->isrunning)
	{
	  if (remaining < min_remaining)
	    min_remaining = remaining;
	  min_remaining_isset = TRUE;
	}
      }
    }

    if (!(state & S_TIMER_CHANGED) && min_remaining_isset)
    {
      if (min_remaining <= 0)
	post executeTimersNow();
      else
	{
	  call TimerFrom.startOneShotAt(then, min_remaining);
	  state |= S_TIMER_RUNNING;
	}
    }
  }
  

  event void TimerFrom.fired()
  {
    executeTimers(call TimerFrom.gett0() + call TimerFrom.getdt());
  }

  task void executeTimersNow()
  {
    /* If we set a timer, try and stop it. But if it believes it's
       not running, that means that the execution of its fired event
       is pending, so we:
       - don't need to call executeTimers (it will happen soon)
       - we must not call executeTimers, because that would change the
         timer's setting, confusing the pending call to TimerFrom.fired
	 (it would call executeTimers with an incorrect "then"
	 parameter)
       We need to use an atomic section even though it's a "timer",
       because it's based on an underlying alarm, whose transitions
       are asynchronous (yuck?)
    */
    if (state & S_TIMER_RUNNING)
      atomic
	{
	  if (!call TimerFrom.isRunning())
	    return;
	  call TimerFrom.stop();
	}
    executeTimers(call TimerFrom.getNow());
  }

  void startTimer(uint8_t num, uint32_t t0, uint32_t dt, bool isoneshot)
  {
    Timer_t* timer = &m_timers[num];
    timer->t0 = t0;
    timer->dt = dt;
    timer->isoneshot = isoneshot;
    timer->isrunning = TRUE;
    state |= S_TIMER_CHANGED;
    post executeTimersNow();
  }

  command void Timer.startPeriodic[uint8_t num](uint32_t dt)
  {
    startTimer(num, call TimerFrom.getNow(), dt, FALSE);
  }

  command void Timer.startOneShot[uint8_t num](uint32_t dt)
  {
    startTimer(num, call TimerFrom.getNow(), dt, TRUE);
  }

  command void Timer.stop[uint8_t num]()
  {
    m_timers[num].isrunning = FALSE;
  }

  command bool Timer.isRunning[uint8_t num]()
  {
    return m_timers[num].isrunning;
  }

  command bool Timer.isOneShot[uint8_t num]()
  {
    return m_timers[num].isoneshot;
  }

  command void Timer.startPeriodicAt[uint8_t num](uint32_t t0, uint32_t dt)
  {
    startTimer(num, t0, dt, FALSE);
  }

  command void Timer.startOneShotAt[uint8_t num](uint32_t t0, uint32_t dt)
  {
    startTimer(num, t0, dt, TRUE);
  }

  command uint32_t Timer.getNow[uint8_t num]()
  {
    return call TimerFrom.getNow();
  }

  command uint32_t Timer.gett0[uint8_t num]()
  {
    return m_timers[num].t0;
  }

  command uint32_t Timer.getdt[uint8_t num]()
  {
    return m_timers[num].dt;
  }

  default event void Timer.fired[uint8_t num]()
  {
  }
}

