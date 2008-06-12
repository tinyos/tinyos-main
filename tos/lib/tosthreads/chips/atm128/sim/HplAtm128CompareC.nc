/// $Id: HplAtm128CompareC.nc,v 1.1 2008-06-12 14:02:20 klueska Exp $
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
 * Basic compare abstraction that builds on top of a counter.
 *
 * @author Philip Levis
 * @date   Nov 22 2005
 */

// $Id: HplAtm128CompareC.nc,v 1.1 2008-06-12 14:02:20 klueska Exp $

#include <Atm128Timer.h>

generic module HplAtm128CompareC(typedef width_t @integer(),
				 uint8_t valueRegister,
				 uint8_t interruptRegister,
				 uint8_t interruptBit,
				 uint8_t flagRegister,
				 uint8_t flagBit) 
{
  provides {
    // 8-bit Timers
    interface HplAtm128Compare<width_t> as Compare;
  }
  uses {
    interface HplAtm128Timer<width_t>   as Timer;
    interface HplAtm128TimerCtrl8       as TimerCtrl;
    interface HplAtm128TimerNotify as Notify;
    interface ThreadScheduler;
  }
}
implementation {
  /* lastZero keeps track of the phase of the clock. It denotes the sim
   * time at which the underlying clock started, which is needed to
   * calculate when compares will occur. */
  sim_time_t lastZero = 0;

  /** This variable is needed to keep track of when the underlying
   *  timer starts, in order to reset lastZero. When oldScale is
   *  AVR_CLOCK_OFF and the scale is set to something else, the
   *  clock starts ticking. */
  uint8_t oldScale = AVR_CLOCK_OFF;
  
  void adjust_zero(width_t currentCounter);

  void cancel_compare();
  sim_event_t* allocate_compare();
  void configure_compare(sim_event_t* e);
  void schedule_new_compare();

  sim_time_t clock_to_sim(sim_time_t t);
  sim_time_t sim_to_clock(sim_time_t t);
  uint16_t shiftFromScale();


  sim_time_t last_zero() {
    if (lastZero == 0) {
      lastZero = sim_mote_start_time(sim_node());
    }
    return lastZero;
  }


  async event void Notify.changed() {
    uint8_t newScale = call Timer.getScale();
    if (newScale != AVR_CLOCK_OFF &&
	oldScale == AVR_CLOCK_OFF) {
      lastZero = sim_time();
    }
    oldScale = newScale;
    
    schedule_new_compare();
  }
  
  async command void Compare.reset() { REG_ACCESS(flagRegister) &= ~(1 << flagBit); }
  async command void Compare.start() { SET_BIT(interruptRegister,interruptBit); }
  async command void Compare.stop()  { CLR_BIT(interruptRegister,interruptBit); }
  async command bool Compare.test()  { 
    return (call TimerCtrl.getInterruptFlag()).bits.ocf0; 
  }
  async command bool Compare.isOn()  { 
    return (call TimerCtrl.getInterruptMask()).bits.ocie0; 
  }

  //=== Read the compare registers. =====================================
  async command width_t Compare.get()   { return (width_t)REG_ACCESS(valueRegister); }

  //=== Write the compare registers. ====================================
  async command void Compare.set(width_t t)   { 
    atomic {
	/* Re the comment above: it's a bad idea to wake up at time 0, as
	   we'll just spin when setting the next deadline. Try and reduce
	   the likelihood by delaying the interrupt...
	*/
      if (t == 0 || t >= 0xfe)
	t = 1;
      
      if (t != REG_ACCESS(valueRegister)) {
	REG_ACCESS(valueRegister) = t;
	schedule_new_compare();
      }
    }
  }

  //=== Timer interrupts signals ========================================
  default async event void Compare.fired() { }
  AVR_NONATOMIC_HANDLER(SIG_OUTPUT_COMPARE0) {
    signal Compare.fired();
    call ThreadScheduler.interruptPostAmble();
  }


  /**
   * If the clock was stopped and has restarted, then
   * we need to move the time when the clock was last
   * zero to a time that reflects the current settings.
   * For example, if the clock was stopped when the counter
   * was 52 and then later restarted, then <tt>lastZero</tt>
   * needs to be moved forward in time so that the 52
   * reflects the current time.
   */ 
  void adjust_zero(width_t currentCounter) {
    sim_time_t now = sim_time();
    sim_time_t adjust = currentCounter;
    adjust = adjust << shiftFromScale();
    adjust = clock_to_sim(adjust);
    lastZero = now - adjust;
  }
  
  sim_time_t clock_to_sim(sim_time_t t) {
    t *= sim_ticks_per_sec();
    t /= call Notify.clockTicksPerSec();
    return t;
  }

  sim_time_t sim_to_clock(sim_time_t t) {
    t *= call Notify.clockTicksPerSec();
    t /= sim_ticks_per_sec();
    return t;
  }
  
  uint16_t shiftFromScale() {
    uint8_t scale = call Timer.getScale();
    switch (scale) {
    case 0:
      return 0;
    case 1:
      return 0;
    case 2:
      return 3;
    case 3:
      return 5;
    case 4:
      return 6;
    case 5:
      return 7;
    case 6:
      return 8;
    case 7:
      return 10;
    default:
      return 255;
    }
    
  }

  sim_event_t* compare;

  void timer0_compare_handle(sim_event_t* evt) {
    dbg("HplAtm128CompareC", "%s Beginning compare at 0x%p\n", __FUNCTION__, evt);
    if (evt->cancelled) {
      return;
    }
    else {
      dbg("HplAtm128CompareC", "%s Handling compare at 0x%p @ %s\n",__FUNCTION__,  evt, sim_time_string());
	    
      if (READ_BIT(interruptRegister, interruptBit)) {
	CLR_BIT(flagRegister, flagBit);
	dbg("HplAtm128CompareC", "%s Compare interrupt @ %s\n", __FUNCTION__, sim_time_string());
	SIG_OUTPUT_COMPARE0();
      }
      else {
	SET_BIT(flagRegister, flagBit);
      }
      // If we haven't been cancelled
      if (!evt->cancelled) {
	configure_compare(evt);
	sim_queue_insert(evt);
      }
    }
  }

  sim_event_t* allocate_compare() {
    sim_event_t* newEvent = sim_queue_allocate_event();
    dbg("HplAtm128CompareC", "Allocated compare at 0x%p\n", newEvent);
    newEvent->handle = timer0_compare_handle;
    newEvent->cleanup = sim_queue_cleanup_none;
    return newEvent;
  }
  
  void configure_compare(sim_event_t* evt) {
    sim_time_t compareTime = 0;
    sim_time_t phaseOffset = 0;
    uint8_t timerVal = call Timer.get();
    uint8_t compareVal = call Compare.get();

    // Calculate how many counter increments until timer
    // hits compare, considering wraparound, and special
    // case of complete wraparound.
    compareTime = ((compareVal - timerVal) & 0xff);
    if (compareTime == 0) {
      compareTime = 256;
    }

    // Now convert the compare time from counter increments
    // to simulation ticks, considering the fact that the
    // increment actually has a phase offset.
    compareTime = compareTime << shiftFromScale();
    compareTime = clock_to_sim(compareTime);
    compareTime += sim_time();

    // How long into a timer tick was the clock actually reset?
    // This covers the case when the compare is set midway between
    // a tick, so it will go off a little early
    phaseOffset = sim_time();
    phaseOffset -= last_zero();
    phaseOffset %= clock_to_sim(1 << shiftFromScale());
    compareTime -= phaseOffset;
      
    dbg("HplAtm128CompareC", "Configuring new compare of %i for %i at time %llu  (@ %llu)\n", (int)compareVal, sim_node(), compareTime, sim_time());
    
    evt->time = compareTime;    
  }
  
  void schedule_new_compare() {
    if (compare != NULL) {
      cancel_compare();
    }
    if (call Timer.getScale() != AVR_CLOCK_OFF) {
      sim_event_t* newEvent = allocate_compare();
      configure_compare(newEvent);

      compare = newEvent;
      sim_queue_insert(newEvent);
    }
  }

  void cancel_compare() {
    dbg("HplAtm128CompareC", "Cancelling compare at 0x%p\n", compare);
    if (compare != NULL) {
      compare->cancelled = 1;
      compare->cleanup = sim_queue_cleanup_total;
    }
  }

  async event void Timer.overflow() {}
  
}
