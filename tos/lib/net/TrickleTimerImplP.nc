// $Id: TrickleTimerImplP.nc,v 1.6 2009-07-16 13:00:08 mmaroti Exp $
/*
 * "Copyright (c) 2006 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
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

    for (i = 0; i < count; i++) {
      uint32_t remaining = trickles[i].time;
      if (remaining != 0) {
	remaining -= dt;
	if (remaining == 0) {
	  if (trickles[i].count < k) {
	    atomic {
	      call Pending.set(i);
	    }
	    post timerTask();
	  }

	  generateTime(i);
	    
	  /* Note that this logic is not the exact trickle algorithm.
	   * Rather than C being reset at the beginning of an interval,
	   * it is being reset at a firing point. This means that the
	   * listening period, rather than of length tau/2, is in the
	   * range [tau/2, tau]. 
	   */
	  trickles[i].count = 0;
	}
	else {
	  trickles[i].time = remaining;
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
      if (timeRemaining != 0) {
	atomic {
	  if (!call Changed.get(i)) {
	    call Changed.clear(i);
	    timeRemaining -= elapsed;
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
    }
    if (set) {
      uint32_t timerVal = lowest;
      timerVal = timerVal;
      dbg("Trickle", "Starting time with time %u.\n", timerVal);
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

  
