/*
 * Copyright (c) 2010, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Janos Sallai
 */ 


#ifndef MICATIMER_H
#define MICATIMER_H

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

#if MHZ == 8

// set TThree to be 1mhz, prescale to 32khz in software

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
#error "Unknown clock rate. MHZ must be defined to 8."
#endif

enum {
  PLATFORM_MHZ = MHZ
};

#endif
