/*
 * Copyright (c) 2009 Communication Group and Eislab at
 * Lulea University of Technology
 *
 * Contact: Laurynas Riliskis, LTU
 * Mail: laurynas.riliskis@ltu.se
 * All rights reserved.
 *
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
 * - Neither the name of Communication Group at Lulea University of Technology
 *   nor the names of its contributors may be used to endorse or promote
 *    products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * The M16c/62p hardware timer configuration used by Mulle.
 * 
 * STOP MODE ENABLED:
 *   TB0 bridges its tics from the RV8564 to TB2 in TMilli speed.
 *   TA0 and TA1 are used to create a 32 bit counter. TA0 counts
 *   tics from TB2 and TA1 counts TA0 underflows.
 *   TB0 and TB1 are used to create a 32 bit Alarm. TB0 counts
 *   tics from TB2 and TB1 counts TB0 underflows.
 *
 * STOP MODE DISABLED:
 *   TA0 generates TMilli tics.
 *   TB0 generates TMilli tics.
 *   TA1 is a 16 bit counter that counts tics from TA0.
 *   TB1 is a 16 bit alarm that counts tics from TB0.
 *
 * ALWAYS USED:
 *  NOTE: Counter timers are turned off when the mcu goes into stop mode.
 *   TA3 generates TMicro tics.
 *   TA2 is a 16 bit TMicro counter that counts tics from TA3.
 *   TA4 is a 16 bit TMicro alarm that counts tics from TA3.
 * 	 TB3 is a 16 bit Radio counter.
 *   TB4 is a 16 bit Radio alarm.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

#ifndef __TIMERCONFIG_H__
#define __TIMERCONFIG_H__

#ifdef ENABLE_STOP_MODE
  #define HIL_TIMERS RV8564AlarmCounterMilli32C
#else
  #define HIL_TIMERS AlarmCounterMilli32C
#endif

// Use hw timers alone.
#define COUNTER_MILLI32_SOURCE TimerB0
#define COUNTER_MILLI32_SOURCE_CTRL TimerB0Ctrl
#define COUNTER_MILLI32 TimerB1
#define COUNTER_MILLI32_CTRL TimerB1Ctrl

#define ALARM_MILLI32_SOURCE TimerA0
#define ALARM_MILLI32_SOURCE_CTRL TimerA0Ctrl
#define ALARM_MILLI32 TimerA1
#define ALARM_MILLI32_CTRL TimerA1Ctrl
// End

// Use the RV8564 chip to generate tics (stop mode enabled).
#define MILLI32_SOURCE_RV8564 TimerB2
#define MILLI32_SOURCE_RV8564_CTRL TimerB2Ctrl

#define COUNTER_MILLI32_LOW TimerA0
#define COUNTER_MILLI32_LOW_CTRL TimerA0Ctrl
#define COUNTER_MILLI32_HIGH TimerA1
#define COUNTER_MILLI32_HIGH_CTRL TimerA1Ctrl

#define ALARM_MILLI32_LOW TimerB0
#define ALARM_MILLI32_LOW_CTRL TimerB0Ctrl
#define ALARM_MILLI32_HIGH TimerB1
#define ALARM_MILLI32_HIGH_CTRL TimerB1Ctrl
// end

// Common settings.
#define COUNTER_MICRO16 TimerA2
#define COUNTER_MICRO16_CTRL TimerA2Ctrl
#define MICRO16_SOURCE TimerA3
#define MICRO16_SOURCE_CTRL TimerA3Ctrl
#define ALARM_MICRO16 TimerA4
#define ALARM_MICRO16_CTRL TimerA4Ctrl

#define COUNTER_RF23016 TimerB3
#define COUNTER_RF23016_CTRL TimerB3Ctrl
#define ALARM_RF23016 TimerB4
#define ALARM_RF23016_CTRL TimerB4Ctrl
// end.

#endif  // __TIMERCONFIG_H__
