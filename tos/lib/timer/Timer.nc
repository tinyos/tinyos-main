//$Id: Timer.nc,v 1.5 2010-06-29 22:07:50 scipio Exp $

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
 * - Neither the name of the copyright holder nor the names of
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

#include "Timer.h"

/**
 * A Timer is TinyOS's general purpose timing interface. For more precise
 * timing, you may wish to use a (platform-specific) component offering
 * an Alarm interface.
 *
 * <p>A Timer is parameterised by its "precision" (milliseconds,
 * microseconds, etc), identified by a type. This prevents, e.g.,
 * unintentionally mixing components expecting milliseconds with those
 * expecting microseconds as those interfaces have a different type.
 *
 * <p>See TEP102 for more details.
 *
 * @param precision_tag A type indicating the precision of this Alarm.
 *
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 */

interface Timer<precision_tag>
{
  // basic interface 
  /**
   * Set a periodic timer to repeat every dt time units. Replaces any
   * current timer settings. Equivalent to startPeriodicAt(getNow(),
   * dt). The <code>fired</code> will be signaled every dt units (first
   * event in dt units).
   *
   * @param dt Time until the timer fires.
   */
  command void startPeriodic(uint32_t dt);

  /**
   * Set a single-short timer to some time units in the future. Replaces
   * any current timer settings. Equivalent to startOneShotAt(getNow(),
   * dt). The <code>fired</code> will be signaled when the timer expires.
   *
   * @param dt Time until the timer fires.
   */
  command void startOneShot(uint32_t dt);

  /**
   * Cancel a timer.
   */
  command void stop();

  /**
   * Signaled when the timer expires (one-shot) or repeats (periodic).
   */
  event void fired();

  // extended interface
  /**
   * Check if timer is running. Periodic timers run until stopped or
   * replaced, one-shot timers run until their deadline expires.
   *
   * @return TRUE if the timer is still running.
   */
  command bool isRunning();

  /**
   * Check if this is a one-shot timer.
   * @return TRUE for one-shot timers, FALSE for periodic timers.
   */
  command bool isOneShot();

  /**
   * Set a periodic timer to repeat every dt time units. Replaces any
   * current timer settings. The <code>fired</code> will be signaled every
   * dt units (first event at t0+dt units). Periodic timers set in the past
   * will get a bunch of events in succession, until the timer "catches up".
   *
   * <p>Because the current time may wrap around, it is possible to use
   * values of t0 greater than the <code>getNow</code>'s result. These
   * values represent times in the past, i.e., the time at which getNow()
   * would last of returned that value.
   *
   * @param t0 Base time for timer.
   * @param dt Time until the timer fires.
   */
  command void startPeriodicAt(uint32_t t0, uint32_t dt);

  /**
   * Set a single-short timer to time t0+dt. Replaces any current timer
   * settings. The <code>fired</code> will be signaled when the timer
   * expires. Timers set in the past will fire "soon".
   *
   * <p>Because the current time may wrap around, it is possible to use
   * values of t0 greater than the <code>getNow</code>'s result. These
   * values represent times in the past, i.e., the time at which getNow()
   * would last of returned that value.
   *
   * @param t0 Base time for timer.
   * @param dt Time until the timer fires.
   */
  command void startOneShotAt(uint32_t t0, uint32_t dt);


  /**
   * Return the current time.
   * @return Current time.
   */
  command uint32_t getNow();

  /**
   * Return the time anchor for the previously started timer or the time of
   * the previous event for periodic timers. The next fired event will occur
   * at gett0() + getdt().
   * @return Timer's base time.
   */
  command uint32_t gett0();

  /**
   * Return the delay or period for the previously started timer. The next
   * fired event will occur at gett0() + getdt().
   * @return Timer's interval.
   */
  command uint32_t getdt();
}

