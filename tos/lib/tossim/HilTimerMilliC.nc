// $Id: HilTimerMilliC.nc,v 1.3 2006-11-07 19:31:21 scipio Exp $
/*
 * "Copyright (c) 2005 Stanford University. All rights reserved.
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

/**
 * This is a TOSSIM-specific implementation of TimerMilliC that
 * directly emulates timers rather than their underlying hardware.  It
 * is intended to be a basic fill-in for microcontrollers that do not
 * have TOSSIM simulation support.
 *
 * @author Philip Levis
 * @date   December 1 2005
 */

#include <Timer.h>

module HilTimerMilliC {
  provides interface Init;
  provides interface Timer<TMilli> as TimerMilli[uint8_t num];
}
implementation {

  enum {
    TIMER_COUNT = uniqueCount("UQ_TIMER_MILLI")
  };

  typedef struct tossim_timer {
    uint32_t t0;
    uint32_t dt;
    bool isPeriodic;
    bool isActive;
    sim_event_t* evt;
  } tossim_timer_t;

  tossim_timer_t timers[TIMER_COUNT];
  sim_time_t initTime;

  void initializeEvent(sim_event_t* evt, uint8_t timerID);
  
  sim_time_t clockToSim(sim_time_t clockVal) {
    return (clockVal * sim_ticks_per_sec()) / 1024;
  }

  sim_time_t simToClock(sim_time_t sim) {
    return (sim * 1024) / sim_ticks_per_sec();
  }
  
  command error_t Init.init() {
    memset(timers, 0, sizeof(timers));
    initTime = sim_time();
    return SUCCESS;
  }
  
  command void TimerMilli.startPeriodic[uint8_t id]( uint32_t dt ) {
    call TimerMilli.startPeriodicAt[id](call TimerMilli.getNow[id](), dt);
  }
  command void TimerMilli.startOneShot[uint8_t id]( uint32_t dt ) {
    call TimerMilli.startOneShotAt[id](call TimerMilli.getNow[id](), dt);
  }

  command void TimerMilli.stop[uint8_t id]() {
    timers[id].isActive = 0;
    if (timers[0].evt != NULL) {
      timers[0].evt->cancelled = 1;
      timers[0].evt->cleanup = sim_queue_cleanup_total;
      timers[0].evt = NULL;
    }
  }

  // extended interface
  command bool TimerMilli.isRunning[uint8_t id]() {return timers[id].isActive;}
  command bool TimerMilli.isOneShot[uint8_t id]() {return !timers[id].isActive;}
  
  command void TimerMilli.startPeriodicAt[uint8_t id]( uint32_t t0, uint32_t dt ) {
    call TimerMilli.startOneShotAt[id](t0, dt);
    timers[id].isPeriodic = 1;
  }
  command void TimerMilli.startOneShotAt[uint8_t id]( uint32_t t0, uint32_t dt ) {
    uint32_t currentTime = call TimerMilli.getNow[id]();
    sim_time_t fireTime = sim_time();

    call TimerMilli.stop[id]();
    
    timers[id].evt = sim_queue_allocate_event();
    initializeEvent(timers[id].evt, id);

    fireTime += clockToSim(dt);
    
    // Be careful about signing and casts, etc.
    if (currentTime > t0) {
      fireTime -= clockToSim(currentTime - t0);
    }
    else {
      fireTime += clockToSim(t0 - currentTime);      
    }

    timers[id].evt->time = fireTime;
    timers[id].isPeriodic = 0;
    timers[id].isActive = 1;
    timers[id].t0 = t0;
    timers[id].dt = dt;

    sim_queue_insert(timers[id].evt);
  }
    
  command uint32_t TimerMilli.getNow[uint8_t id]() {
    sim_time_t nowTime = sim_time();
    nowTime -= initTime;
    nowTime = simToClock(nowTime);
    return nowTime & 0xffffffff;
  }
  
  command uint32_t TimerMilli.gett0[uint8_t id]() {
    return timers[id].t0;
  }
  command uint32_t TimerMilli.getdt[uint8_t id]() {
    return timers[id].dt;
  }

  void tossim_timer_handle(sim_event_t* evt) {
    uint8_t* datum = (uint8_t*)evt->data;
    uint8_t id = *datum;
    signal TimerMilli.fired[id]();

    // We should only re-enqueue the event if it is a follow-up firing
    // of the same timer.  If the timer is stopped, it's a one shot,
    // or someone has started a new timer, don't re-enqueue it.
    if (timers[id].isActive &&
	timers[id].isPeriodic &&
	timers[id].evt == evt) {
      evt->time = evt->time += clockToSim(timers[id].dt);
      sim_queue_insert(evt);
    }
    // If we aren't enqueueing it, and nobody has done something that
    // would cause the event to have been garbage collected, then do
    // so.
    else if (timers[id].evt == evt) {
      call TimerMilli.stop[id]();
    }
  }
  
  void initializeEvent(sim_event_t* evt, uint8_t timerID) {
    uint8_t* data = (uint8_t*)malloc(sizeof(uint8_t));
    *data = timerID;

    evt->handle = tossim_timer_handle;
    evt->cleanup = sim_queue_cleanup_none;
    evt->data = data;
  }

 default event void TimerMilli.fired[uint8_t id]() {}
}

