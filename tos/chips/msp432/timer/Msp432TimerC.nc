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
 */

/*
 * The MSP432 provides up to 4 16 bit wide timer modules called TA0-TA3.
 * How many is a function of chip packaging and is NOT reflected in any
 * chip header.  The Platform has to know which chip is being used and 
 * then has to make sure that only timers that are present are actually
 * used.
 *
 * All timer modules are exactly alike and are equivilent to the msp430
 * TA5 timing module.  5 (0-4) Compare and Capture registers are available
 * on each timing module.
 *
 * As such, we are currently maintaining the same interfaces as the msp430
 * but modified to reflect the differences in the MSP432.  We also restructure
 * the interfaces to make them easier to understand.
 *
 * Interfaces implemented:
 *
 * Init                     module use initilization
 * Msp432Timer              controls core Timer (TAx->CTL)
 * Msp432TimerCCTL          controls Capture/Compare Register (CCR) [n]
 * Msp432TimerCompare       controls one CCR module for compare func
 * Msp432TimerCaptureV2     controls one CCR module for capture func
 *
 * We export Init to allow initilization functions to happen if a module
 * is actually used.  The reference should wire in PlatformC.PeripheralInit
 * to cause this initilization to be invoked
 *
 * Most h/w timer initilization happens during startup (startup.c) when
 * the clocks are initilized.  This is because how the timers are clocked
 * is inherently platform dependent and tied to how the clocks are set up.
 *
 * However, we don't want to enable the NVIC interrupt unless the actual
 * timer has been wired in.  Init allows this to happen on a per invocation
 * basis.  When a module is instantiated, we also turn on the core wrap
 * interrupt.
 *
 * @author Eric B. Decker <cire831@gmail.com>
 *
 * By convention, we default to TA0 being TMicro and TA1 TMilli (32KiHz)
 */

#include <platform.h>

/*
 * By default Timers are assumed to be clocked synchronously wrt the
 * main system clock.  Define PLATFORM_TAn_ASYNC in platform.h for the
 * platform if the Timer is being clocked by something different.
 *
 * ie. by default TA1 is mapped to the 32KiHz Tmilli background timer
 * and as such the platform should define PLATFORM_TA1_ASYNC.
 */
#ifndef PLATFORM_TA0_ASYNC
#define PLATFORM_TA0_ASYNC FALSE
#endif
#ifndef PLATFORM_TA1_ASYNC
#define PLATFORM_TA1_ASYNC FALSE
#endif
#ifndef PLATFORM_TA2_ASYNC
#define PLATFORM_TA2_ASYNC FALSE
#endif
#ifndef PLATFORM_TA3_ASYNC
#define PLATFORM_TA3_ASYNC FALSE
#endif

configuration Msp432TimerC {
  provides {

    /* nomenclature:
     *           A0     core timer (TA0)
     *           A0_0   TA0 CCR0
     *           A0_1   TA0 CCR1
     * Timer_CCTLA0_0   Control for TA0 CCR0
     * Timer_COMPA0_0   Compare interface for TA0 CCR0
     * Timer_CAPTA0_0   Capture interface for TA0 CCR0
     * Timer_CCTLA1_2   Control for TA1 CCR2
     * Timer_COMPA1_3   Compare interface for TA1 CCR3
     * Timer_CAPTA1_4   Capture interface for TA1 CCR4
     */

    interface Init                 as Timer_A0_Init;
    interface Msp432Timer          as xTimer_A0;
    interface Msp432TimerCCTL      as Timer_CCTLA0_0; /* CCR0 */
    interface Msp432TimerCompare   as Timer_COMPA0_0;
    interface Msp432TimerCaptureV2 as Timer_CAPTA0_0;

    interface Msp432TimerCCTL      as Timer_CCTLA0_1; /* CCR1 */
    interface Msp432TimerCompare   as Timer_COMPA0_1;
    interface Msp432TimerCaptureV2 as Timer_CAPTA0_1;

    interface Msp432TimerCCTL      as Timer_CCTLA0_2; /* CCR2 */
    interface Msp432TimerCompare   as Timer_COMPA0_2;
    interface Msp432TimerCaptureV2 as Timer_CAPTA0_2;

    interface Msp432TimerCCTL      as Timer_CCTLA0_3; /* CCR3 */
    interface Msp432TimerCompare   as Timer_COMPA0_3;
    interface Msp432TimerCaptureV2 as Timer_CAPTA0_3;

    interface Msp432TimerCCTL      as Timer_CCTLA0_4; /* CCR4 */
    interface Msp432TimerCompare   as Timer_COMPA0_4;
    interface Msp432TimerCaptureV2 as Timer_CAPTA0_4;


    interface Init                 as Timer_A1_Init;
    interface Msp432Timer          as xTimer_A1;
    interface Msp432TimerCCTL      as Timer_CCTLA1_0; /* CCR0 */
    interface Msp432TimerCompare   as Timer_COMPA1_0;
    interface Msp432TimerCaptureV2 as Timer_CAPTA1_0;

    interface Msp432TimerCCTL      as Timer_CCTLA1_1; /* CCR1 */
    interface Msp432TimerCompare   as Timer_COMPA1_1;
    interface Msp432TimerCaptureV2 as Timer_CAPTA1_1;

    interface Msp432TimerCCTL      as Timer_CCTLA1_2; /* CCR2 */
    interface Msp432TimerCompare   as Timer_COMPA1_2;
    interface Msp432TimerCaptureV2 as Timer_CAPTA1_2;

    interface Msp432TimerCCTL      as Timer_CCTLA1_3; /* CCR3 */
    interface Msp432TimerCompare   as Timer_COMPA1_3;
    interface Msp432TimerCaptureV2 as Timer_CAPTA1_3;

    interface Msp432TimerCCTL      as Timer_CCTLA1_4; /* CCR4 */
    interface Msp432TimerCompare   as Timer_COMPA1_4;
    interface Msp432TimerCaptureV2 as Timer_CAPTA1_4;


    interface Init                 as Timer_A2_Init;
    interface Msp432Timer          as xTimer_A2;
    interface Msp432TimerCCTL      as Timer_CCTLA2_0; /* CCR0 */
    interface Msp432TimerCompare   as Timer_COMPA2_0;
    interface Msp432TimerCaptureV2 as Timer_CAPTA2_0;

    interface Msp432TimerCCTL      as Timer_CCTLA2_1; /* CCR1 */
    interface Msp432TimerCompare   as Timer_COMPA2_1;
    interface Msp432TimerCaptureV2 as Timer_CAPTA2_1;

    interface Msp432TimerCCTL      as Timer_CCTLA2_2; /* CCR2 */
    interface Msp432TimerCompare   as Timer_COMPA2_2;
    interface Msp432TimerCaptureV2 as Timer_CAPTA2_2;

    interface Msp432TimerCCTL      as Timer_CCTLA2_3; /* CCR3 */
    interface Msp432TimerCompare   as Timer_COMPA2_3;
    interface Msp432TimerCaptureV2 as Timer_CAPTA2_3;

    interface Msp432TimerCCTL      as Timer_CCTLA2_4; /* CCR4 */
    interface Msp432TimerCompare   as Timer_COMPA2_4;
    interface Msp432TimerCaptureV2 as Timer_CAPTA2_4;


    interface Init                 as Timer_A3_Init;
    interface Msp432Timer          as xTimer_A3;
    interface Msp432TimerCCTL      as Timer_CCTLA3_0; /* CCR0 */
    interface Msp432TimerCompare   as Timer_COMPA3_0;
    interface Msp432TimerCaptureV2 as Timer_CAPTA3_0;

    interface Msp432TimerCCTL      as Timer_CCTLA3_1; /* CCR1 */
    interface Msp432TimerCompare   as Timer_COMPA3_1;
    interface Msp432TimerCaptureV2 as Timer_CAPTA3_1;

    interface Msp432TimerCCTL      as Timer_CCTLA3_2; /* CCR2 */
    interface Msp432TimerCompare   as Timer_COMPA3_2;
    interface Msp432TimerCaptureV2 as Timer_CAPTA3_2;

    interface Msp432TimerCCTL      as Timer_CCTLA3_3; /* CCR3 */
    interface Msp432TimerCompare   as Timer_COMPA3_3;
    interface Msp432TimerCaptureV2 as Timer_CAPTA3_3;

    interface Msp432TimerCCTL      as Timer_CCTLA3_4; /* CCR4 */
    interface Msp432TimerCompare   as Timer_COMPA3_4;
    interface Msp432TimerCaptureV2 as Timer_CAPTA3_4;
  }
}
implementation {
  components PanicC;
  components HplMsp432TimerIntP as TimerInts;

  components new Msp432TimerP((uint32_t) TIMER_A0, TA0_0_IRQn,
                              PLATFORM_TA0_ASYNC) as TA0;

  xTimer_A0 = TA0.Timer;
  Timer_A0_Init = TA0.Init;
  TA0.TimerVec_0 -> TimerInts.TimerAInt_0[0];
  TA0.TimerVec_N -> TimerInts.TimerAInt_N[0];
  TA0.Overflow   -> TA0.Event[7];
  TA0.Panic      -> PanicC;

  components new Msp432TimerCapComP((uint32_t) TIMER_A0, 0) as TA0_0;
  Timer_CCTLA0_0 = TA0_0.CCTL;
  Timer_COMPA0_0 = TA0_0.Compare;
  Timer_CAPTA0_0 = TA0_0.Capture;
  TA0_0.Timer -> TA0.Timer;
  TA0_0.Event -> TA0.Event[0];

  components new Msp432TimerCapComP((uint32_t) TIMER_A0, 1) as TA0_1;
  Timer_CCTLA0_1 = TA0_1.CCTL;
  Timer_COMPA0_1 = TA0_1.Compare;
  Timer_CAPTA0_1 = TA0_1.Capture;
  TA0_1.Timer -> TA0.Timer;
  TA0_1.Event -> TA0.Event[1];

  components new Msp432TimerCapComP((uint32_t) TIMER_A0, 2) as TA0_2;
  Timer_CCTLA0_2 = TA0_2.CCTL;
  Timer_COMPA0_2 = TA0_2.Compare;
  Timer_CAPTA0_2 = TA0_2.Capture;
  TA0_2.Timer -> TA0.Timer;
  TA0_2.Event -> TA0.Event[2];

  components new Msp432TimerCapComP((uint32_t) TIMER_A0, 3) as TA0_3;
  Timer_CCTLA0_3 = TA0_3.CCTL;
  Timer_COMPA0_3 = TA0_3.Compare;
  Timer_CAPTA0_3 = TA0_3.Capture;
  TA0_3.Timer -> TA0.Timer;
  TA0_3.Event -> TA0.Event[3];

  components new Msp432TimerCapComP((uint32_t) TIMER_A0, 4) as TA0_4;
  Timer_CCTLA0_4 = TA0_4.CCTL;
  Timer_COMPA0_4 = TA0_4.Compare;
  Timer_CAPTA0_4 = TA0_4.Capture;
  TA0_4.Timer -> TA0.Timer;
  TA0_4.Event -> TA0.Event[4];


  components new Msp432TimerP((uint32_t) TIMER_A1, TA1_0_IRQn,
                              PLATFORM_TA1_ASYNC) as TA1;

  xTimer_A1 = TA1.Timer;
  Timer_A1_Init = TA1.Init;
  TA1.TimerVec_0 -> TimerInts.TimerAInt_0[1];
  TA1.TimerVec_N -> TimerInts.TimerAInt_N[1];
  TA1.Overflow   -> TA1.Event[7];
  TA1.Panic      -> PanicC;

  components new Msp432TimerCapComP((uint32_t) TIMER_A1, 0) as TA1_0;
  Timer_CCTLA1_0 = TA1_0.CCTL;
  Timer_COMPA1_0 = TA1_0.Compare;
  Timer_CAPTA1_0 = TA1_0.Capture;
  TA1_0.Timer -> TA1.Timer;
  TA1_0.Event -> TA1.Event[0];

  components new Msp432TimerCapComP((uint32_t) TIMER_A1, 1) as TA1_1;
  Timer_CCTLA1_1 = TA1_1.CCTL;
  Timer_COMPA1_1 = TA1_1.Compare;
  Timer_CAPTA1_1 = TA1_1.Capture;
  TA1_1.Timer -> TA1.Timer;
  TA1_1.Event -> TA1.Event[1];

  components new Msp432TimerCapComP((uint32_t) TIMER_A1, 2) as TA1_2;
  Timer_CCTLA1_2 = TA1_2.CCTL;
  Timer_COMPA1_2 = TA1_2.Compare;
  Timer_CAPTA1_2 = TA1_2.Capture;
  TA1_2.Timer -> TA1.Timer;
  TA1_2.Event -> TA1.Event[2];

  components new Msp432TimerCapComP((uint32_t) TIMER_A1, 3) as TA1_3;
  Timer_CCTLA1_3 = TA1_3.CCTL;
  Timer_COMPA1_3 = TA1_3.Compare;
  Timer_CAPTA1_3 = TA1_3.Capture;
  TA1_3.Timer -> TA1.Timer;
  TA1_3.Event -> TA1.Event[3];

  components new Msp432TimerCapComP((uint32_t) TIMER_A1, 4) as TA1_4;
  Timer_CCTLA1_4 = TA1_4.CCTL;
  Timer_COMPA1_4 = TA1_4.Compare;
  Timer_CAPTA1_4 = TA1_4.Capture;
  TA1_4.Timer -> TA1.Timer;
  TA1_4.Event -> TA1.Event[4];


  components new Msp432TimerP((uint32_t) TIMER_A2, TA2_0_IRQn,
                              PLATFORM_TA2_ASYNC) as TA2;

  xTimer_A2 = TA2.Timer;
  Timer_A2_Init = TA2.Init;
  TA2.TimerVec_0 -> TimerInts.TimerAInt_0[2];
  TA2.TimerVec_N -> TimerInts.TimerAInt_N[2];
  TA2.Overflow   -> TA2.Event[7];
  TA2.Panic      -> PanicC;

  components new Msp432TimerCapComP((uint32_t) TIMER_A2, 0) as TA2_0;
  Timer_CCTLA2_0 = TA2_0.CCTL;
  Timer_COMPA2_0 = TA2_0.Compare;
  Timer_CAPTA2_0 = TA2_0.Capture;
  TA2_0.Timer -> TA2.Timer;
  TA2_0.Event -> TA2.Event[0];

  components new Msp432TimerCapComP((uint32_t) TIMER_A2, 1) as TA2_1;
  Timer_CCTLA2_1 = TA2_1.CCTL;
  Timer_COMPA2_1 = TA2_1.Compare;
  Timer_CAPTA2_1 = TA2_1.Capture;
  TA2_1.Timer -> TA2.Timer;
  TA2_1.Event -> TA2.Event[1];

  components new Msp432TimerCapComP((uint32_t) TIMER_A2, 2) as TA2_2;
  Timer_CCTLA2_2 = TA2_2.CCTL;
  Timer_COMPA2_2 = TA2_2.Compare;
  Timer_CAPTA2_2 = TA2_2.Capture;
  TA2_2.Timer -> TA2.Timer;
  TA2_2.Event -> TA2.Event[2];

  components new Msp432TimerCapComP((uint32_t) TIMER_A2, 3) as TA2_3;
  Timer_CCTLA2_3 = TA2_3.CCTL;
  Timer_COMPA2_3 = TA2_3.Compare;
  Timer_CAPTA2_3 = TA2_3.Capture;
  TA2_3.Timer -> TA2.Timer;
  TA2_3.Event -> TA2.Event[3];

  components new Msp432TimerCapComP((uint32_t) TIMER_A2, 4) as TA2_4;
  Timer_CCTLA2_4 = TA2_4.CCTL;
  Timer_COMPA2_4 = TA2_4.Compare;
  Timer_CAPTA2_4 = TA2_4.Capture;
  TA2_4.Timer -> TA2.Timer;
  TA2_4.Event -> TA2.Event[4];


  components new Msp432TimerP((uint32_t) TIMER_A3, TA3_0_IRQn,
                              PLATFORM_TA3_ASYNC) as TA3;

  xTimer_A3 = TA3.Timer;
  Timer_A3_Init = TA3.Init;
  TA3.TimerVec_0 -> TimerInts.TimerAInt_0[3];
  TA3.TimerVec_N -> TimerInts.TimerAInt_N[3];
  TA3.Overflow   -> TA3.Event[7];
  TA3.Panic      -> PanicC;

  components new Msp432TimerCapComP((uint32_t) TIMER_A3, 0) as TA3_0;
  Timer_CCTLA3_0 = TA3_0.CCTL;
  Timer_COMPA3_0 = TA3_0.Compare;
  Timer_CAPTA3_0 = TA3_0.Capture;
  TA3_0.Timer -> TA3.Timer;
  TA3_0.Event -> TA3.Event[0];

  components new Msp432TimerCapComP((uint32_t) TIMER_A3, 1) as TA3_1;
  Timer_CCTLA3_1 = TA3_1.CCTL;
  Timer_COMPA3_1 = TA3_1.Compare;
  Timer_CAPTA3_1 = TA3_1.Capture;
  TA3_1.Timer -> TA3.Timer;
  TA3_1.Event -> TA3.Event[1];

  components new Msp432TimerCapComP((uint32_t) TIMER_A3, 2) as TA3_2;
  Timer_CCTLA3_2 = TA3_2.CCTL;
  Timer_COMPA3_2 = TA3_2.Compare;
  Timer_CAPTA3_2 = TA3_2.Capture;
  TA3_2.Timer -> TA3.Timer;
  TA3_2.Event -> TA3.Event[2];

  components new Msp432TimerCapComP((uint32_t) TIMER_A3, 3) as TA3_3;
  Timer_CCTLA3_3 = TA3_3.CCTL;
  Timer_COMPA3_3 = TA3_3.Compare;
  Timer_CAPTA3_3 = TA3_3.Capture;
  TA3_3.Timer -> TA3.Timer;
  TA3_3.Event -> TA3.Event[3];

  components new Msp432TimerCapComP((uint32_t) TIMER_A3, 4) as TA3_4;
  Timer_CCTLA3_4 = TA3_4.CCTL;
  Timer_COMPA3_4 = TA3_4.Compare;
  Timer_CAPTA3_4 = TA3_4.Capture;
  TA3_4.Timer -> TA3.Timer;
  TA3_4.Event -> TA3.Event[4];
}
