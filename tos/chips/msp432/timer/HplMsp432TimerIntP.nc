/*
 * Copyright (c) 2016, Eric B. Decker
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
 * Author: Eric B. Decker <cire831@gmail.com>
 *
 * The msp432 defines interrupt vectors in tos/platforms/<platform>/startup.c
 * Names are of the form TA[0-3]_{0,N}_Handler.  The startup versions are
 * defined as weak and are overridden here.
 *
 * The chip header defines all 4 TA timers.  Whether a chip has all 4 or
 * not is determined by how the chip is packaged.  There is no way to
 * determine from the chip header what is actually there.  Essentially
 * it is a platform thing.
 * 
 * TA0 is a Tmicro (usec) and TA1 is a Tmilli (msec, 32KiHz ticked).
 * 
 * All timer modules are the same, each has 5 capture registers and
 * the main Register (TAn->R).  The TAn_0 interrupt fires from the
 * CCR0 interrupt, and TAn_N interrupts for all other CCR registers
 * as well as the wrap (TAn->R wrap) interrupt (TAn->CTL.TAIFG).
 *
 * Interrupts on TAn_N are presented via the TAn->IV interrupt
 * vector register.  They are prioritized and when IV is read the
 * highest priority interrupt is cleared.  The value from IV tells
 * which interrupt we should signal.
 * 
 * Interrupts on TAn_0 come from TAn->CCTL0.CCIFG (CCIE must be set)
 * and are NOT automatically cleared.  This must be done manually in
 * the interrupt handler.
 *
 * To enable a given TAn module's interrupts, the corresponding NVIC enable
 * must be set.  This happens else where.  Also when a module is enabled
 * its TAx->CTL.IE (TAIE) should be enabled.  This turns on wrap interrupts.
 * The NVIC enable and TAIE enable happen together.
 * 
 * This module is the connector from the interrupt to the actual driver.
 */

#include <hardware.h>

module HplMsp432TimerIntP {
  provides {
    interface HplMsp432TimerInt as TimerAInt_0[uint8_t instance];
    interface HplMsp432TimerInt as TimerAInt_N[uint8_t instance];
  }
}
implementation {
  void TA0_0_Handler() @C() @spontaneous() __attribute__((interrupt)) {
    BITBAND_PERI(TIMER_A0->CCTL[0], TIMER_A_CCTLN_CCIFG_OFS) = 0;
    signal TimerAInt_0.interrupt[0](0);
  }

  void TA0_N_Handler() @C() @spontaneous() __attribute__((interrupt)) {
    uint8_t v = (TIMER_A0->IV) >> 1;
    signal TimerAInt_N.interrupt[0](v);
  }

  void TA1_0_Handler() @C() @spontaneous() __attribute__((interrupt)) {
    BITBAND_PERI(TIMER_A1->CCTL[0], TIMER_A_CCTLN_CCIFG_OFS) = 0;
    signal TimerAInt_0.interrupt[1](0);
  }

  void TA1_N_Handler() @C() @spontaneous() __attribute__((interrupt)) {
    uint8_t v = (TIMER_A1->IV) >> 1;
    signal TimerAInt_N.interrupt[1](v);
  }

  void TA2_0_Handler() @C() @spontaneous() __attribute__((interrupt)) {
    BITBAND_PERI(TIMER_A2->CCTL[0], TIMER_A_CCTLN_CCIFG_OFS) = 0;
    signal TimerAInt_0.interrupt[2](0);
  }

  void TA2_N_Handler() @C() @spontaneous() __attribute__((interrupt)) {
    uint8_t v = (TIMER_A2->IV) >> 1;
    signal TimerAInt_N.interrupt[2](v);
  }

  void TA3_0_Handler() @C() @spontaneous() __attribute__((interrupt)) {
    BITBAND_PERI(TIMER_A3->CCTL[0], TIMER_A_CCTLN_CCIFG_OFS) = 0;
    signal TimerAInt_0.interrupt[3](0);
  }

  void TA3_N_Handler() @C() @spontaneous() __attribute__((interrupt)) {
    uint8_t v = (TIMER_A3->IV) >> 1;
    signal TimerAInt_N.interrupt[3](v);
  }

  default async event void TimerAInt_0.interrupt[uint8_t instance](uint8_t v) { bkpt(1); }
  default async event void TimerAInt_N.interrupt[uint8_t instance](uint8_t v) { bkpt(1); }
}
