/*
 * Copyright (c) 2015, Technische Universitaet Berlin
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
 */

/*
 *	author: RICH TU Berlin Team
 */

#include "printf.h"
#include <AppHardwareApi.h>

module PlatformTestC {
  uses {
    interface Boot;
    interface Leds;
    interface Timer<TMilli>;
  }
}
implementation {

#ifdef CAUSE_STACK_OVERFLOW
#warning Causing stack overflow
  uint32_t overflow_the_stack(uint32_t in) {
    volatile uint32_t i = 0;
    i += overflow_the_stack(in*2);
    return i;
  }
  volatile uint32_t overflow = 0;
#endif

  event void Boot.booted() {
    // XXX HACK! cause an unaligned access exception
#ifdef CAUSE_UNALIGNED_ACCESS
#warning Causing unaligned access
    volatile uint16_t a[4];
    volatile uint32_t* p;
    volatile uint32_t target;
#endif

    call Leds.led0On();

#ifdef CAUSE_STACK_OVERFLOW
    vAHI_SetStackOverflow(TRUE, 0x07800);
    overflow = overflow_the_stack(0);
#endif

#ifdef CAUSE_UNALIGNED_ACCESS
    a[0] = 0xFFEE; a[1] = 0xDDCC; a[2] = 0xBBAA; a[3] = 0x9988;
    p = (uint32_t*) &a[1];
    target = *p;
    printf("TEST: %.2X, %.4X, %.2X\n", a[0], p, target);
#endif

    call Leds.led1On();

    call Timer.startOneShot(2048);
  }

  event void Timer.fired() {
    bool is_rc_oscillator, is_32mhz_clock_stable;
    uint8_t clockrate;

    is_32mhz_clock_stable = bAHI_Clock32MHzStable();
    is_rc_oscillator = bAHI_GetClkSource();
    clockrate = u8AHI_GetSystemClkRate();
    printf("32MHz Clock stable: %i \n", is_32mhz_clock_stable);
    printf("Using internal RC oscillator: %i \n", is_rc_oscillator);
    printf("Clock rate return value: %i \n", clockrate);
    printfflush();

    printf("void*: size: %.2X, alignof: %.2X\n", sizeof(void*), __alignof__(void*));
    printf("float: size: %.2X, alignof: %.2X\n", sizeof(float), __alignof__(float));
    printf("double: size: %.2X, alignof: %.2X\n", sizeof(double), __alignof__(double));
    printf("long double: size: %.2X, alignof: %.2X\n", sizeof(long double), __alignof__(long double));
    printf("short: size: %.2X, alignof: %.2X\n", sizeof(short), __alignof__(short));
    printf("int: size: %.2X, alignof: %.2X\n", sizeof(int), __alignof__(int));
    printf("long: size: %.2X, alignof: %.2X\n", sizeof(long), __alignof__(long));
    printf("long long: size: %.2X, alignof: %.2X\n", sizeof(long), __alignof__(long));
    printf("wchar_t: size: %.2X\nsize_t: size: %.2X\n", sizeof(wchar_t), sizeof(size_t));
    printfflush();
  }
}

