// $Id: MicaTimer.h,v 1.3 2010-06-29 22:07:53 scipio Exp $
/*
 * Copyright (c) 2005-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/*
 * Copyright (c) 2007, Vanderbilt University
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
 *
 */

#ifndef MICATIMER_H
#define MICATIMER_H

/* This file defines the rates at which the mica family's atmega1281 timer 1
   and 3 timers run at. The goal is to present the user with microsend and
   32khz timers, but it may not be possible to run the timers at these rates
   (because of the limited prescaler selection).

   So TinyOS picks a prescaler (based on the selected processor MHz) for
   each of these timers, and builds corresponding 16-bit alarms&counters
   (AlarmOne16C, AlarmThree16C, CounterOne16C, CounterThree16C) over
   hardware timers 1 and 3. TinyOS then divides these hardware timers by
   the appropriate power of 2 to get approximate 32-bit 32kHz and 1MHz
   alarms and counters (Alarm32khz32C, AlarmMicro32C, Counter32khz32C,
   CounterMicro32C).

   The constants and typedefs for all this configuration are defined here,
   based on the value of the MHZ preprocessor symbol, which shoud approximate
   the platform's MHZ rate.

   Note that the timers thus obtained will not be exactly at 32768Hz or
   1MHz, because the clock doesn't divide by a power of two to those
   frequencies, and/or the clock frequency is not accurate. If you need
   more accurate timing, you should use the calibration functions
   offered by the Atm128Calibrate interface provided by PlatformC.

   This file also defines EXT_STANDBY_T0_THRESHOLD, a threshold on
   remaining time till the next timer 0 interrupt under which the mote
   should sleep in ext standby rather than power save. This is only
   important when not using the internal oscillator.  Wake up from power
   save takes 65536 cycles (6 cycles for ext standby), which is, e.g.,
   ~9.4ms at 7Mhz.
*/

#include <Timer.h>
#include <Atm128Timer.h>

/* Some types for the non-standard rates that mica timers might be running
   at.
 */
typedef struct { } T64khz;
typedef struct { } T128khz;
typedef struct { } T2mhz;
typedef struct { } T4mhz;

/* TX is the typedef for the rate of timer X, 
   MICA_PRESCALER_X is the prescaler for timer X,
   MICA_DIVIDER_X_FOR_Y_LOG2 is the number of bits to shift timer X by
     to get rate Y,
   counter_X_overflow_t is uint16_t if MICA_DIVIDER_X_FOR_Y_LOG2 is 0,
     uint32_t otherwise.
*/

#if MHZ == 1
typedef T128khz TOne;
typedef TMicro TThree;
typedef uint32_t counter_one_overflow_t;
typedef uint16_t counter_three_overflow_t;

enum {
  MICA_PRESCALER_ONE = ATM128_CLK16_DIVIDE_8,
  MICA_DIVIDE_ONE_FOR_32KHZ_LOG2 = 2,
  MICA_PRESCALER_THREE = ATM128_CLK16_NORMAL,
  MICA_DIVIDE_THREE_FOR_MICRO_LOG2 = 0,
  EXT_STANDBY_T0_THRESHOLD = 80,
};

#elif MHZ == 2
typedef T32khz TOne;
typedef T2mhz TThree;
typedef uint16_t counter_one_overflow_t;
typedef uint32_t counter_three_overflow_t;

enum {
  MICA_PRESCALER_ONE = ATM128_CLK16_DIVIDE_64,
  MICA_DIVIDE_ONE_FOR_32KHZ_LOG2 = 0,
  MICA_PRESCALER_THREE = ATM128_CLK16_NORMAL,
  MICA_DIVIDE_THREE_FOR_MICRO_LOG2 = 1,
  EXT_STANDBY_T0_THRESHOLD = 40
};

#elif MHZ == 4
typedef T64khz TOne;
typedef T4mhz TThree;
typedef uint32_t counter_one_overflow_t;
typedef uint32_t counter_three_overflow_t;

enum {
  MICA_PRESCALER_ONE = ATM128_CLK16_DIVIDE_64,
  MICA_DIVIDE_ONE_FOR_32KHZ_LOG2 = 1,
  MICA_PRESCALER_THREE = ATM128_CLK16_NORMAL,
  MICA_DIVIDE_THREE_FOR_MICRO_LOG2 = 2,
  EXT_STANDBY_T0_THRESHOLD = 24
};

#elif MHZ == 8
/*
typedef T32khz TOne;
typedef TMicro TThree;
typedef uint16_t counter_one_overflow_t;
typedef uint16_t counter_three_overflow_t;

enum {
  MICA_PRESCALER_ONE = ATM128_CLK16_DIVIDE_256,
  MICA_DIVIDE_ONE_FOR_32KHZ_LOG2 = 0,
  MICA_PRESCALER_THREE = ATM128_CLK16_DIVIDE_8,
  MICA_DIVIDE_THREE_FOR_MICRO_LOG2 = 0,
  EXT_STANDBY_T0_THRESHOLD = 12
};
*/

// get a 1MHz (1 microsecond resolution) timer for debugging purposes

typedef TMicro TOne;
typedef TMicro TThree;
typedef uint32_t counter_one_overflow_t;
typedef uint16_t counter_three_overflow_t;
enum {
  MICA_PRESCALER_ONE = ATM128_CLK16_DIVIDE_8,
  MICA_DIVIDE_ONE_FOR_32KHZ_LOG2 = 5,
  MICA_PRESCALER_THREE = ATM128_CLK16_DIVIDE_8,
  MICA_DIVIDE_THREE_FOR_MICRO_LOG2 = 0,
  EXT_STANDBY_T0_THRESHOLD = 12,
};

#else
#error "Unknown clock rate. MHZ must be defined to one of 1, 2, 4, or 8."
#endif

enum {
  PLATFORM_MHZ = MHZ
};

#endif
