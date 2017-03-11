/*
 * Copyright (c) 2016 Eric B. Decker
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * - Neither the name of the copyright holders nor the names of
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
 *
 * Warning: many of these routines directly touch cpu registers
 * it is assumed that this is initilization code and interrupts are
 * off.
 *
 * @author Eric B. Decker
 */

#include "hardware.h"
#include "cpu_stack.h"

#ifndef noinit
#define noinit	__attribute__ ((section(".noinit"))) 
#endif

noinit uint32_t stack_size;

module PlatformP {
  provides {
    interface Init;
    interface Platform;
    interface StdControl;
  }
  uses {
    interface Init as PlatformPins;
    interface Init as PlatformLeds;
    interface Init as PlatformClock;
    interface Init as PeripheralInit;
    interface Stack;
  }
}

implementation {
  command error_t Init.init() {
//    call Stack.init();
//    stack_size = call Stack.size();

    call PlatformLeds.init();   // Initializes the Leds
    call PeripheralInit.init();
    return SUCCESS;
  }


  /*
   * dummy StdControl for PlatformSerial.
   */
  command error_t StdControl.start() {
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    return SUCCESS;
  }


  /* T32 is a count down so negate it */
  async command uint32_t Platform.usecsRaw()       { return -(TIMER32_1->VALUE); }
  async command uint32_t Platform.usecsRawSize()   { return 32; }
  async command uint32_t Platform.jiffiesRaw()     { return (TIMER_A0->R); }
  async command uint32_t Platform.jiffiesRawSize() { return 16; }


  /***************** Defaults ***************/
  default command error_t PeripheralInit.init() {
    return SUCCESS;
  }
}
