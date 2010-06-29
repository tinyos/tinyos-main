// $Id: TrickleTimerImplP.nc,v 1.8 2010-06-29 22:07:47 scipio Exp $
/*
 * Copyright (c) 2006 Stanford University. All rights reserved.
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

/*
 * Module that provides a service instance of trickle timers. For
 * details on the working of the parameters, please refer to Levis et
 * al., "A Self-Regulating Algorithm for Code Maintenance and
 * Propagation in Wireless Sensor Networks," NSDI 2004.
 *
 * @param l Lower bound of the time period in seconds.
 * @param h Upper bound of the time period in seconds.
 * @param k Redundancy constant.
 * @param count How many timers to provide.
 *
 * @author Philip Levis
 * @author Gilman Tolle
 * @date   Jan 7 2006
 */ 

#include <Timer.h>

generic module TrickleTimerImplP(uint16_t low,
				 uint16_t high,
				 uint8_t k,
				 uint8_t count,
				 uint8_t scale) {
  provides {
    interface Init;
    interface TrickleTimer[uint8_t id];
  }
  uses {
    interface Timer<TMilli>;
    interface BitVector as Pending;
    interface BitVector as Changed;
    interface Random;
    interface Leds;
  }
}
implementation {

  typedef struct {
    uint16_t period;
    uint32_t time;
    uint32_t remainder;
    uint8_t count;
  } trickle_t;

  trickle_t trickles[count];
  
  void adjustTimer();
  void generateTime(uint8_t id);
  
  command error_t Init.init() {
    int i;
    for (i = 0; i < count; i++) {
      trickles[i].period = high;
      trickles[i].count = 0;
      trickles[i].time = 0;
      trickles[i].remainder = 0;
    }
    atomic {
      call Pending.clearAll();
      call Changed.clearAll();
    }
    return SUCCESS;
  }

  /**
   * Start a trickle timer. Reset the counter to 0.
   */
  command error_t TrickleTimer.start[uint8_t id]() {
    if (trickles[id].time != 0) {
      return EBUSY;
    }
    trickles[id].time = 0;
    trickles[id].remainder = 0;
    trickles[id].count = 0;
    generateTime(id);
    atomic {
      call Changed.set(id);
    }
    adjustTimer();
    dbg("Trickle", "Starting trickle timer %hhu @ %s\n", id, sim_time_string());
    return SUCCESS;
  }

  /**
   * Stop the trickle timer. This call sets the timer period to H.
   */
  command void TrickleTimer.stop[uint8_t id]() {
    trickles[id].time = 0;
    trickles[id].period = high;
    adjustTimer();
    dbg("Trickle", "Stopping trickle timer %hhu @ %s\n", id, sim_time_string());
  }

  /**
   * Reset the timer period to L. If called while the timer is running,
   * then a new interval (of length L) begins immediately.
   */
  command void TrickleTimer.reset[uint8_t id]() {
    trickles[id].period = low;
    trickles[id].count = 0;
    if (trickles[id].time != 0) {
      dbg("Trickle", "Resetting running trickle timer %hhu @ %s\n", id, sim_time_string());
      atomic {
	call Changed.set(id);
      }
      trickles[id].time = 0;
      trickles[id].remainder = 0;
      generateTime(id);
      adjustTimer();
    } else {
      dbg("Trickle", "Resetting  trickle timer %hhu @ %s\n", id, sim_time_string());
    }
  }

  /**
   * Increment the counter C. When an interval ends, C is set to 0.
   */
  command void TrickleTimer.incrementCounter[uint8_t id]() {
    trickles[id].count++;
  }

  task void timerTask() {
    uint8_t i;
    for (i = 0; i < count; i++) {
      bool fire = FALSE;
      atomic {
	if (call Pending.get(i)) {
	  call Pending.clear(i);
	  fire = TRUE;
	}
      }
      if (fire) {
	dbg("Trickle", "Firing trickle timer %hhu @ %s\n", i, sim_time_string());
	signal TrickleTimer.fired[i]();
	post timerTask();
	return;
      }
    }
  }
  
  /**
   * The trickle timer has fired. Signaled if C &gt; K.
   */
  event void Timer.fired() {
    uint8_t i;
    uint32_t dt = call Timer.getdt();
    dbg("Trickle", "Trickle Sub-timer fired\n");
    for (i = 0; i < count; i++) {
      uint32_t remaining = trickles[i].time;
      if (remaining != 0) {
	remaining -= dt;
	if (remaining == 0) {
	  if (trickles[i].count < k) {
	    atomic {
	      dbg("Trickle", "Trickle: mark timer %hhi as pending\n", i);
	      call Pending.set(i);
	    }
	    post timerTask();
	  }
	  call Changed.set(i);
	  generateTime(i);
	    
	  /* Note that this logic is not the exact trickle algorithm.
	   * Rather than C being reset at the beginning of an interval,
	   * it is being reset at a firing point. This means that the
	   * listening period, rather than of length tau/2, is in the
	   * range [tau/2, tau]. 
	   */
	  trickles[i].count = 0;
	}
      }
    }
    adjustTimer();
  }

  // This is where all of the work is done!
  void adjustTimer() {
    uint8_t i;
    uint32_t lowest = 0;
    bool set = FALSE;

    // How much time has elapsed on the current timer
    // since it was scheduled? This value is needed because
    // the time remaining of a running timer is its time
    // value minus time elapsed.
    uint32_t elapsed = (call Timer.getNow() - call Timer.gett0());
	
    for (i = 0; i < count; i++) {
      uint32_t timeRemaining = trickles[i].time;
      dbg("Trickle", "Adjusting: timer %hhi (%u)\n", i, timeRemaining);

      if (timeRemaining == 0) { // Not running, go to next timer
	continue;
      }
      
      atomic {
	if (!call Changed.get(i)) {
	  if (timeRemaining > elapsed) {
	    dbg("Trickle", "  not changed, elapse time remaining to %u.\n", trickles[i].time - elapsed);
	    timeRemaining -= elapsed;
	    trickles[i].time -= elapsed;
	  }
	  else { // Time has already passed, so fire immediately
	    dbg("Trickle", "  not changed, ready to elapse, fire immediately\n");
	    timeRemaining = 1;
	    trickles[i].time = 1;
	  }
	}
	else {
	  dbg("Trickle", "  changed, fall through.\n");
	  call Changed.clear(i);
	}
      }
      if (!set) {
	lowest = timeRemaining;
	set = TRUE;
      }
      else if (timeRemaining < lowest) {
	lowest = timeRemaining;
      }
    }
    
    if (set) {
      uint32_t timerVal = lowest;
      dbg("Trickle", "Starting sub-timer with interval %u.\n", timerVal);
      call Timer.startOneShot(timerVal);
    }
    else {
      call Timer.stop();
    }
  }

  /* Generate a new firing time for a timer. if the timer was already
   * running (time != 0), then double the period.
   */
  void generateTime(uint8_t id) {
    uint32_t newTime;
    uint16_t rval;
    
    if (trickles[id].time != 0) {
      trickles[id].period *= 2;
      if (trickles[id].period > high) {
	trickles[id].period = high;
      }
    }
    
    trickles[id].time = trickles[id].remainder;
    
    newTime = trickles[id].period;
    newTime = newTime << (scale - 1);

    rval = call Random.rand16() % (trickles[id].period << (scale - 1));
    newTime += rval;
    
    trickles[id].remainder = (((uint32_t)trickles[id].period) << scale) - newTime;
    trickles[id].time += newTime;
    dbg("Trickle,TrickleTimes", "Generated time for %hhu with period %hu (%u) is %u (%i + %hu)\n", id, trickles[id].period, (uint32_t)trickles[id].period << scale, trickles[id].time, (trickles[id].period << (scale - 1)), rval);
  }

 default event void TrickleTimer.fired[uint8_t id]() {
   return;
 }
}

  
