/* 
 * Copyright (c) 2009-2010 People Power Company
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the People Power Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * PEOPLE POWER CO. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/** Multiple-LED test.
 *
 * Twice per second, a counter will be incremented, and the counter
 * value depicted in the LEDs.  The value of the counter, and the
 * value read from the LEDs, will be printed.  Verify that the LEDs
 * light in order to represent the counter value.  Watch the serial
 * output to ensure the counter and led value match in their lower
 * bits.
 *
 * TESTS: MultiLed interface
 * TESTS: Timer<TMilli>
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com> */

#include <stdio.h>

module TestP {
  uses {
    interface Boot;
    interface Timer<TMilli> as Timer;
    interface MultiLed;
  }
} implementation {

  unsigned int last_set;
  unsigned int counter;
  
  task void showState_task ()
  {
    printf("count=%04x, led=%04x\r\n", last_set, call MultiLed.get());
  }

  event void Boot.booted() {
    counter = 0;
    call Timer.startPeriodic(512);
  }
  
  event void Timer.fired() {
    last_set = ++counter;
    call MultiLed.set(last_set);
    post showState_task();
  }
  
}
