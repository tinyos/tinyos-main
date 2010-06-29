/*
 * Copyright (c) 2005 Stanford University. All rights reserved.
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

/**
 * The TOSSIM implementation of the Atm128 Timer0 counter. It handles
 * overflow, scaling, and phase considerations.
 *
 * @date November 22 2005
 *
 * @author Philip Levis <pal@cs.stanford.edu>
 * @author Martin Turon <mturon@xbow.com>
 * @author David Gay <dgay@intel-research.net>
 */

// $Id: HplAtm128Counter0C.nc,v 1.5 2010-06-29 22:07:43 scipio Exp $/// $Id: HplAtm128Timer2C.nc,

#include <Atm128Timer.h>
#include <hardware.h>

module HplAtm128Counter0C {
  provides {
    interface Init @atleastonce();
    // 8-bit Timers
    interface HplAtm128Timer<uint8_t>   as Timer0;
    interface HplAtm128TimerNotify      as Notify;
    interface HplAtm128TimerCtrl8       as Timer0Ctrl;
  }
}
implementation
{
  bool inOverflow = 0;
  uint8_t savedCounter = 0;
  sim_time_t lastZero = 0;

  void adjust_zero(uint8_t currentCounter);

  void cancel_overflow();
  sim_event_t* allocate_overflow();
  void configure_overflow(sim_event_t* e);
  void schedule_new_overflow();

  sim_time_t clock_to_sim(sim_time_t t);
  sim_time_t sim_to_clock(sim_time_t t);
  uint16_t shiftFromScale();

  command error_t Init.init() {
    /* Do nothing. On a standard mote this configures Timer0 to
     * operating in asynchronous mode off an external crystal. Here in
     * TOSSIM it's assumed that's the case. */
    return SUCCESS;
  }
    
  async command sim_time_t Notify.clockTicksPerSec() {
    return ATM128_TIMER0_TICKSPPS;
  }
  
  sim_time_t last_zero() {
    if (lastZero == 0) {
      lastZero = sim_mote_start_time(sim_node());
    }
    return lastZero;
  }
  
  //=== Read the current timer value. ===================================
  async command uint8_t  Timer0.get() {
    uint8_t rval;
    sim_time_t elapsed = sim_time() - last_zero();
    elapsed = sim_to_clock(elapsed);
    elapsed = elapsed >> shiftFromScale();
    rval = (uint8_t)(elapsed & 0xff);
    dbg("HplAtm128Counter0C", "HplAtm128Counter0C: Getting timer: %hhu\n", rval);
    return rval;
  }

  //=== Set/clear the current timer value. ==============================
  /**
   * Set/clear the current timer value.
   *
   * This code is pretty tricky.  */
  async command void Timer0.set(uint8_t newVal)  {
    uint8_t curVal = call Timer0.get();
    if (newVal == curVal) {
      return;
    }
    else {
      sim_time_t adjustment = curVal - newVal;
      adjustment = adjustment << shiftFromScale();
      adjustment = clock_to_sim(adjustment);

      if (newVal < curVal) {
	lastZero += adjustment;
      }
      else { // newVal > curVal
	lastZero -= adjustment;
      }

      schedule_new_overflow();
      signal Notify.changed();
    }
  }

  //=== Read the current timer scale. ===================================
  async command uint8_t Timer0.getScale() {
    return TCCR0 & 0x7;
  }

  //=== Turn off the timers. ============================================
  async command void Timer0.off() {
    call Timer0.setScale(AVR_CLOCK_OFF);
    savedCounter = call Timer0.get();
    cancel_overflow();
    signal Notify.changed();
  }

  //=== Write a new timer scale. ========================================
  async command void Timer0.setScale(uint8_t s)  {
    Atm128TimerControl_t ctrl;
    uint8_t currentScale = call Timer0.getScale();
    uint8_t currentCounter;
    dbg("HplAtm128Counter0C", "Timer0 scale set to %i\n", (int)s);
    if (currentScale == 0) {
      currentCounter = savedCounter;
    }
    else {
      currentCounter = call Timer0.get();
    }
    
    ctrl = call Timer0Ctrl.getControl();
    ctrl.flat &= ~(0x7);
    ctrl.flat |= (s & 0x7);
    call Timer0Ctrl.setControl(ctrl);  

    if (currentScale != s) {
      adjust_zero(currentCounter);
      schedule_new_overflow();
    }
    signal Notify.changed();
  }

  //=== Read the control registers. =====================================
  async command Atm128TimerControl_t Timer0Ctrl.getControl() { 
    return *(Atm128TimerControl_t*)&TCCR0; 
  }

  //=== Write the control registers. ====================================
  async command void Timer0Ctrl.setControl( Atm128TimerControl_t x ) { 
    TCCR0 = x.flat; 
  }

  //=== Read the interrupt mask. =====================================
  async command Atm128_TIMSK_t Timer0Ctrl.getInterruptMask() { 
    return *(Atm128_TIMSK_t*)&TIMSK; 
  }

  //=== Write the interrupt mask. ====================================
  DEFINE_UNION_CAST(TimerMask8_2int, Atm128_TIMSK_t, uint8_t);
  DEFINE_UNION_CAST(TimerMask16_2int, Atm128_ETIMSK_t, uint8_t);

  async command void Timer0Ctrl.setInterruptMask( Atm128_TIMSK_t x ) { 
    TIMSK = TimerMask8_2int(x); 
  }

  //=== Read the interrupt flags. =====================================
  async command Atm128_TIFR_t Timer0Ctrl.getInterruptFlag() { 
    return *(Atm128_TIFR_t*)&TIFR; 
  }

  //=== Write the interrupt flags. ====================================
  DEFINE_UNION_CAST(TimerFlags8_2int, Atm128_TIFR_t, uint8_t);
  DEFINE_UNION_CAST(TimerFlags16_2int, Atm128_ETIFR_t, uint8_t);

  async command void Timer0Ctrl.setInterruptFlag( Atm128_TIFR_t x ) { 
    TIFR = TimerFlags8_2int(x); 
  }

  //=== Timer 8-bit implementation. ====================================
  async command void Timer0.reset() {
    // Clear TOV0. On real hardware, this is a write.
    TIFR &= ~(1 << TOV0);
  }
  async command void Timer0.start() {
    SET_BIT(ATM128_TIMSK, TOIE0);
    dbg("HplAtm128Counter0C", "Enabling TOIE0 at %llu\n", sim_time());
    schedule_new_overflow();
  }
  async command void Timer0.stop()  {
    dbg("HplAtm128Counter0C", "Timer stopped @ %llu\n", sim_time());
    CLR_BIT(ATM128_TIMSK, TOIE0);
    cancel_overflow();
  }

  bool overflowed() {
    return READ_BIT(ATM128_TIFR, TOV0); 
  }

  inline void stabiliseOverflow() {
    /* From the atmel manual:

    During asynchronous operation, the synchronization of the interrupt
    flags for the asynchronous timer takes three processor cycles plus one
    timer cycle.  The timer is therefore advanced by at least one before
    the processor can read the timer value causing the setting of the
    interrupt flag. The output compare pin is changed on the timer clock
    and is not synchronized to the processor clock.

    So: if the timer is = 0, wait till it's = 1, except if
    - we're currently in the overflow interrupt handler
    - or, the overflow flag is already set
    */

    //if (!inOverflow)
    //  while (!TCNT0 && !overflowed())
    //;
  }

  async command bool Timer0.test()  { 
    stabiliseOverflow();
    return overflowed();
  }
  async command bool Timer0.isOn()  { 
    return (call Timer0Ctrl.getInterruptMask()).bits.toie0; 
  }

  default async event void Timer0.overflow() { }
  AVR_ATOMIC_HANDLER(SIG_OVERFLOW0) {
    inOverflow = TRUE;
    signal Timer0.overflow();
    inOverflow = FALSE;
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
  void adjust_zero(uint8_t currentCounter) {
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
    uint8_t scale = call Timer0.getScale();
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

  sim_event_t* overflow;

  void timer0_overflow_handle(sim_event_t* evt) {
    if (evt->cancelled) {
      return;
    }
    else {
      if (READ_BIT(ATM128_TIMSK, TOIE0)) {
	CLR_BIT(ATM128_TIFR, TOV0);
	dbg("HplAtm128Counter0C", "Overflow interrupt at %s\n", sim_time_string());
	SIG_OVERFLOW0();
      }
      else {
	dbg("HplAtm128Counter0C", "Setting overflow bit at %s\n", sim_time_string());
	SET_BIT(ATM128_TIFR, TOV0);
      }
      configure_overflow(evt);
      sim_queue_insert(evt);
    }
  }
  
  sim_event_t* allocate_overflow() {
    sim_event_t* newEvent = sim_queue_allocate_event();

    newEvent->handle = timer0_overflow_handle;
    newEvent->cleanup = sim_queue_cleanup_none;
    return newEvent;
  }
  
  void configure_overflow(sim_event_t* evt) {
    sim_time_t overflowTime = 0;
    uint8_t timerVal = call Timer0.get();
    uint8_t overflowVal = 0;

    // Calculate how many counter increments until timer
    // hits compare, considering wraparound, and special
    // case of complete wraparound.
    overflowTime = ((overflowVal - timerVal) & 0xff);
    if (overflowTime == 0) {
      overflowTime = 256;
    }

    // Now convert the compare time from counter increments
    // to simulation ticks, considering the fact that the
    // increment actually has a phase offset.
    overflowTime = overflowTime << shiftFromScale();
    overflowTime = clock_to_sim(overflowTime);
    overflowTime += sim_time();
    overflowTime -= (sim_time() - last_zero()) % (1 << shiftFromScale());

    dbg("HplAtm128Counter0C", "Scheduling new overflow for %i at time %llu\n", sim_node(), overflowTime);
    
    evt->time = overflowTime;
  }
  
  void schedule_new_overflow() {
    sim_event_t* newEvent = allocate_overflow();
    configure_overflow(newEvent);

    if (overflow != NULL) {
      cancel_overflow();
    }
    overflow = newEvent;
    sim_queue_insert(newEvent);
  }
  
  void cancel_overflow() {
    if (overflow != NULL) {
      overflow->cancelled = 1;
      dbg("HplAtm128Counter0C", "Cancelling overflow %p.\n", overflow);
      overflow->cleanup = sim_queue_cleanup_total;
    }
  }
}
