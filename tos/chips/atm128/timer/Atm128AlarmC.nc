/// $Id: Atm128AlarmC.nc,v 1.9 2010-06-29 22:07:43 scipio Exp $

/*
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
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
 * - Neither the name of Crossbow Technology nor the names of
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
 * Build a TEP102 Alarm from an Atmega128 hardware timer and one of its
 * compare registers.
 * @param frequency_tag The frequency tag for this Alarm
 * @param timer_size The width of this Alarm
 * @param mindt The shortest time in the future this Alarm can be set
 *   (in its own time units). Has to be at least 2, as setting a compare
 *   register one above the current counter value is unreliable. Has to be
 *   large enough that the Alarm time does not pass between the computation
 *   of <code>expires</code> and actually setting the compare register.
 *   Check this (for high-frequency timers) by inspecting the generated
 *   assembly code...
 *
 * @author Martin Turon <mturon@xbow.com>
 * @author David Gay <david.e.gay@intel.com>
 */

generic module Atm128AlarmC(typedef frequency_tag, 
			    typedef timer_size @integer(),
			    int mindt) @safe()
{
  provides interface Alarm<frequency_tag, timer_size> as Alarm @atmostonce();

  uses interface HplAtm128Timer<timer_size>;
  uses interface HplAtm128Compare<timer_size>;
}
implementation
{
  async command timer_size Alarm.getNow() {
    return call HplAtm128Timer.get();
  }

  async command timer_size Alarm.getAlarm() {
    return call HplAtm128Compare.get();
  }

  async command bool Alarm.isRunning() {
    return call HplAtm128Compare.isOn();
  }

  async command void Alarm.stop() {
    call HplAtm128Compare.stop();
  }

  async command void Alarm.start( timer_size dt ) 
  {
    call Alarm.startAt( call HplAtm128Timer.get(), dt);
  }

  async command void Alarm.startAt( timer_size t0, timer_size dt ) {
    /* We don't set an interrupt before "now" + mindt to avoid setting
       an interrupt which is in the past by the time we actually set
       it. mindt should always be at least 2, because you cannot
       reliably set an interrupt one cycle in the future. mindt should
       also be large enough to cover the execution time of this
       function. */
    atomic
      {
	timer_size now, elapsed, expires;

	dbg("Atm128AlarmC", "   starting timer at %llu with dt %llu\n",
	    (uint64_t)t0, (uint64_t) dt);

	now = call HplAtm128Timer.get();
	elapsed = now + mindt - t0;
	if (elapsed >= dt)
	  expires = now + mindt;
	else
	  expires = t0 + dt;

	/* Setting the compare register to "-1" is a bad idea
	   (interrupt fires before counter overflow is detected, and all
	   the "current time" stuff goes bad) */
	if (expires == 0)
	  expires = 1;

	/* Note: all HplAtm128Compare.set values have one subtracted,
	   because the comparisons are continuous, but the actual
	   interrupt is signalled at the next timer clock cycle. */
	call HplAtm128Compare.set(expires - 1);
	call HplAtm128Compare.reset();
	call HplAtm128Compare.start();
      }
  }

  async event void HplAtm128Compare.fired() {
    call HplAtm128Compare.stop();
    dbg("Atm128AlarmC", " Compare fired, signal alarm above.\n");
    __nesc_enable_interrupt();
    signal Alarm.fired();
  }

  async event void HplAtm128Timer.overflow() {
  }
}
