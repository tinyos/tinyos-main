// $Id: BlinkM.nc,v 1.4 2006-12-12 18:22:51 vlahan Exp $

/**
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. 
 *
 * CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS 
 * ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS ANY 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
 */

/// @author Martin Turon <mturon@xbow.com>

#define SLOW_COMPARE            50  
#define SLOW_COMPARE_ON_CYCLE   320  
#define SLOW_OVERFLOW_CYCLES    500

#define FAST_COMPARE            16000
#define FAST_COMPARE_ON_CYCLE   4
#define FAST_OVERFLOW_CYCLES    5

#include <ATm128Timer.h>

/**
 * This version of Blink is designed to test ATmega128 AVR timers.
 */
generic module BlinkM(typedef timer_size @integer())
{
  uses interface HplTimer<timer_size> as Timer;
  uses interface HplCompare<timer_size> as Compare;
  uses interface HplTimer<uint16_t> as FastTimer;
  uses interface HplCompare<uint16_t> as FastCompare;
  uses interface Boot;
  uses interface Leds;
}
implementation
{
  norace int scycle = SLOW_OVERFLOW_CYCLES;
  norace int fcycle = FAST_OVERFLOW_CYCLES;

  void slow_timer_init() {
      atomic {
	  CLR_BIT(ASSR, AS0);  // set Timer/Counter0 to use 32,768khz crystal

	  call Timer.setScale(ATM128_CLK8_DIVIDE_32); 
	  call Compare.set(SLOW_COMPARE); // trigger compare in middle of range
	  call Compare.start();

	  call Timer.start();
	  call Timer.set(0);      // overflow after 256-6 = 250 cycles
      }
  }

  void fast_timer_init() {

      atomic {
	  call FastTimer.setScale(AVR_CLOCK_DIVIDE_8); 
	  call FastCompare.set(FAST_COMPARE);  // trigger compare mid pulse
	  call FastCompare.start();

	  call FastTimer.start();
	  call FastTimer.set(0);      // overflow after 256-6 = 250 cycles
      }
  }
  
  event void Boot.booted() {
      slow_timer_init();
      fast_timer_init();

      while(1) {}
  }
 
  async event void Compare.fired() {
      call Leds.led0On();
      call Compare.stop();
  }

  async event void Timer.overflow() {
      call Timer.reset();

      if (scycle == SLOW_COMPARE_ON_CYCLE) {
	  call Compare.reset();
	  call Compare.start();
      }

      if (scycle++ > SLOW_OVERFLOW_CYCLES) {
	  scycle = 0;
	  call Leds.led0Off();
      }
  }

  async event void FastCompare.fired() {
      if (fcycle == FAST_COMPARE_ON_CYCLE) {
	  call Leds.led2On();
	  call FastCompare.stop();
      }
  }

  async event void FastTimer.overflow() {
      call FastTimer.reset();

      if (fcycle == FAST_COMPARE_ON_CYCLE) {
	  call FastCompare.reset();
	  call FastCompare.start();
      }

      if (fcycle++ > FAST_OVERFLOW_CYCLES) {
	  fcycle = 0;
	  call Leds.led1Toggle(); // toggle overflow led
	  call Leds.led2Off();    // clear compare led
      }
  }
}

