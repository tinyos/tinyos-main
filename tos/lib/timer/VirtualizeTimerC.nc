//$Id: VirtualizeTimerC.nc,v 1.10 2006-12-12 18:23:32 vlahan Exp $

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
  bool m_timers_changed;

  task void updateFromTimer();

  void fireTimers(uint32_t now)
  {
    uint8_t num;

    for (num=0; num<NUM_TIMERS; num++)
      {
	Timer_t* timer = &m_timers[num];

	if (timer->isrunning)
	  {
	    uint32_t elapsed = now - timer->t0;

	    if (elapsed >= timer->dt)
	      {
		if (timer->isoneshot)
		  timer->isrunning = FALSE;
		else // Update timer for next event
		  timer->t0 += timer->dt;

		signal Timer.fired[num]();
	      }
	  }
      }
    post updateFromTimer();
  }
  
  task void updateFromTimer()
  {
    /* This code supports a maximum dt of MAXINT. If min_remaining and
       remaining were switched to uint32_t, and the logic changed a
       little, dt's up to 2^32-1 should work (but at a slightly higher
       runtime cost). */
    uint32_t now = call TimerFrom.getNow();
    int32_t min_remaining = (1UL << 31) - 1; /* max int32_t */
    bool min_remaining_isset = FALSE;
    uint8_t num;

    call TimerFrom.stop();

    for (num=0; num<NUM_TIMERS; num++)
      {
	Timer_t* timer = &m_timers[num];

	if (timer->isrunning)
	  {
	    uint32_t elapsed = now - timer->t0;
	    int32_t remaining = timer->dt - elapsed;

	    if (remaining < min_remaining)
	      {
		min_remaining = remaining;
		min_remaining_isset = TRUE;
	      }
	  }
      }

    if (min_remaining_isset)
      {
	if (min_remaining <= 0)
	  fireTimers(now);
	else
	  call TimerFrom.startOneShotAt(now, min_remaining);
      }
  }
  
  event void TimerFrom.fired()
  {
    fireTimers(call TimerFrom.getNow());
  }

  void startTimer(uint8_t num, uint32_t t0, uint32_t dt, bool isoneshot)
  {
    Timer_t* timer = &m_timers[num];
    timer->t0 = t0;
    timer->dt = dt;
    timer->isoneshot = isoneshot;
    timer->isrunning = TRUE;
    post updateFromTimer();
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

