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
 * @author Eric B. Decker <cire831@gmail.com>
 */

/*
 * FIXME: we didn't actually to the encoded nx implementation.  Didn't
 * really buy anything and requires that we figure out which Timer
 * we are messing with.  The core code is the same so consolidating
 * didn't buy that much.  Further, the potential complication of asyncrony 
 * requires either indepenent instatation or every timer has to eat
 * the atomic surrounding TAx->R references.
 *
 * Clean up the chat about nx.
 *
 * n:  timer being referenced.  0-3
 * nx: combined timer and event.  ie.  x can be 0-f, n can be 0-3
 *     nx = (n << 4) | x
 * 
 * events are values from the IV register shifted to the right one bit.
 * as follows:
 *
 *     0x00:    (0) TA0->CCTL0.CCIFG (from TA0_0_Handler)
 *     0x01:    (2) TA0->CCTL1.CCIFG (from TA0_N_Handler)
 *     0x02:    (4) TA0->CCTL2.CCIFG
 *     0x03:    (6) TA0->CCTL3.CCIFG
 *     0x04:    (8) TA0->CCTL4.CCIFG
 *     0x05:    (a) TA0->CCTL5.CCIFG
 *     0x06:    (c) TA0->CCTL6.CCIFG
 *     0x07:    (e) TA0->CTL.IFG
 *     0x10:    TA1->CCTL0.CCIFG
 *
 * NOTE: the msp432 currently only support up to 4 TA modules each
 * with 5 CCRs, this is denoted in the TI literature as TA: 5,5,5,5.
 * So in practice n will be 0-3 and x can be 0-4 and 7 (wrap).
 *
 * TAx_0_Handler handles the interrupt from TAx->CCTL0.CCIFG.  This
 * gets signalled as Event[nx] where nx = n << 4 | x, x = [0:4,7]
 *
 * TAx_N_Handler handles all other timer interrupts and the TAx->IV
 * indicates which one popped.  Reading IV clears the interrupt.
 */

generic module Msp432TimerP(uint32_t timer_ptr, bool isAsync) {
  provides {
    interface Msp432Timer      as Timer;
    interface Msp432TimerEvent as Event[uint8_t n];
  }
  uses {
    interface Msp432TimerEvent as Overflow;
    interface HplMsp432TimerInt   as TimerVec_0;
    interface HplMsp432TimerInt   as TimerVec_N;
  }
}
implementation {

#define TAx ((Timer_A_Type *) timer_ptr)

  async command uint16_t Timer.get() {
    uint16_t t0, t1;

    /*
     * WARNING: It is possible that the timer being referenced is being clocked
     * by something other than a clock syncronized to the main CPU clock.  Define
     * isAsync as TRUE to enable a major vote when reading TAx->R to avoid 
     * propagation effects and inconsistent reads.
     *
     * (See section 17.2.1.1 (pg 605) of the msp432 family TRM (SLAU356D)).
     *
     * This is a platform thing, and only needs to be done if the clock for 
     * this timer is something other than a main cpu clock derived. ie.ACLK
     * when run from a 32KiHz watch crystal.
     */
    if (isAsync) {
      atomic {
        t0 = TAx->R;
        t1 = TAx->R;
        if (t0 == t1)
          return t0;
        do { t0 = t1; t1 = TAx->R; } while( t0 != t1 );
        return t1;
      }
    } else
      return TAx->R;
  }

  /*
   * NOTE: on msp432 processors, the Overflow is actually TAx->CTL.IFG
   * which trips when TAx->R wraps.  If enabled, the cpu will interrupt
   * through vector TAx_N_Handler with a TAx->IV of 0xE (which becomes 7 
   * (>> 1)).  If the interrupt is acknowledged, reading of TAx->IV will
   * clear the interrupt which will clear TAx->CTL.IFG.
   *
   * It is very important that all callers of isOverflowPending to have
   * TAx_N interrupts disabled (or all interrupts) prior to entering
   * the section that looks at the timer state (ie. calls isOverflowPending).
   */
  async command bool Timer.isOverflowPending() {
    return BITBAND_PERI(TAx->CTL, TIMER_A_CTL_IFG_OFS);
  }

  async command void Timer.clearOverflow() {
    BITBAND_PERI(TAx->CTL, TIMER_A_CTL_IFG_OFS) = 0;
  }

  async command void Timer.setMode(uint8_t mode) {
    TAx->CTL = (TAx->CTL & ~(TIMER_A_CTL_MC_MASK)) |
          ((mode << TIMER_A_CTL_MC_OFS) & (TIMER_A_CTL_MC_MASK));
  }

  async command uint8_t Timer.getMode() {
    return (TAx->CTL & (TIMER_A_CTL_MC_MASK)) >> TIMER_A_CTL_MC_OFS;
  }

  /*
   * WARNING: using clear causes not only TAx->R to clear but
   * it also clears the clock divider and count direction (MC)
   */
  async command void Timer.clear() {
    BITBAND_PERI(TAx->CTL, TIMER_A_CTL_CLR_OFS) = 1;
  }

  async command void Timer.enableEvents() {
    BITBAND_PERI(TAx->CTL, TIMER_A_CTL_IE_OFS) = 1;
  }

  async command void Timer.disableEvents() {
    BITBAND_PERI(TAx->CTL, TIMER_A_CTL_IE_OFS) = 0;
  }

  async command void Timer.setClockSource(uint16_t clockSource) {
    TAx->CTL = (TAx->CTL & ~(TIMER_A_CTL_SSEL_MASK)) |
        ((clockSource << TIMER_A_CTL_SSEL_OFS) & (TIMER_A_CTL_SSEL_MASK));
  }

  async command void Timer.setInputDivider(uint16_t inputDivider) {
    TAx->CTL = (TAx->CTL & ~(TIMER_A_CTL_ID_MASK)) | 
        ((inputDivider << TIMER_A_CTL_ID_OFS) & (TIMER_A_CTL_ID_MASK));
  }

  /*
   * The MSP432 provides two interrupt vectors for each timer module.  The first is
   * dedicated  to CCR0.   The TACCR0 IFG (interrupt flag) is NOT automatically
   * cleared by the h/w.  The TAx_0_Handler (1st level interrupt handler) takes
   * care of that.
   *
   * TimerVec_0 handles TAx->CCTL0.CCIFG (CCR0) interrupts.  It needs to be
   * wired to the handler TAx_0_Handler.
   */
  async event void TimerVec_0.interrupt(uint8_t v) {
    signal Event.fired[0]();
  }

  /*
   * TimerVec_N handles interrupts for other TAx interrupts, TAx->CTL.IFG 
   * (timer overflow), and TAx->CCTLn (CCRn) for  n > 0.  An interrupt vector
   * register (TAx->IV) indicates which interrupt has occured (with priority,
   * highest is presented first).
   *
   * When TAx->IV is read the highest priority interrupt is cleared also 
   * clearing the associated IFG.  That is handled by the 1st stage interrupt
   * handler.
   */
  async event void TimerVec_N.interrupt(uint8_t v) {
    signal Event.fired[v]();
  }

  async event void Overflow.fired() {
    signal Timer.overflow();
  }

  default async event void Timer.overflow() { }
  default async event void Event.fired[uint8_t n]() { }
}
