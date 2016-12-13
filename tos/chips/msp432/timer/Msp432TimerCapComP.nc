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

#include "Msp432Timer.h"

generic module Msp432TimerCapComP(uint32_t timer_ptr, uint8_t CCRn) {
  provides {
    interface Msp432TimerCCTL      as CCTL;
    interface Msp432TimerCompare   as Compare;
    interface Msp432TimerCaptureV2 as Capture;
  }
  uses {
    interface Msp432Timer      as Timer;
    interface Msp432TimerEvent as Event;
  }
}
implementation {

#define TAx ((Timer_A_Type *) timer_ptr)

  async command bool CCTL.isInterruptPending() {
    return BITBAND_PERI(TAx->CCTL[CCRn], TIMER_A_CCTLN_CCIFG_OFS);
  }


  async command void CCTL.clearPendingInterrupt() {
    BITBAND_PERI(TAx->CCTL[CCRn], TIMER_A_CCTLN_CCIFG_OFS) = 0;
  }


  async command void CCTL.setCCTL(uint16_t x) {
    TAx->CCTL[CCRn] = x;
  }


  async command uint16_t CCTL.getCCTL() {
    return TAx->CCTL[CCRn];
  }

  /*
   * build a control word for setting up Capture/Compare on the msp432 h/w
   * see msp432p401r.h for values, and/or the msp432 TRM.
   *
   * l_cm: the capture/compare control mode
   * ccis: cap/compare input select.
   * cap: 0 for compare, 1 for capture
   */

  uint16_t capComControl(uint8_t l_cm, uint8_t ccis, uint8_t cap_val) {
    return ((l_cm << TIMER_A_CCTLN_CM_OFS) & TIMER_A_CCTLN_CM_MASK) |
      ((ccis << TIMER_A_CCTLN_CCIS_OFS) & TIMER_A_CCTLN_CCIS_MASK) |
      ((cap_val & 1) << TIMER_A_CCTLN_CAP_OFS);
  }


  async command void CCTL.setCCRforCompare() {
    /* defaults to no capture and CCIS channel A */
    TAx->CCTL[CCRn] = capComControl(0, MSP432TIMER_CCI_A, 0);
  }


  async command void CCTL.setCCRforCapture(uint8_t cm, uint8_t ccis) {
    TAx->CCTL[CCRn] = capComControl(cm, ccis, 1);
  }


  async command void CCTL.enableEvents() {
    BITBAND_PERI(TAx->CCTL[CCRn], TIMER_A_CCTLN_CCIE_OFS) = 1;
  }

  async command void CCTL.disableEvents() {
    BITBAND_PERI(TAx->CCTL[CCRn], TIMER_A_CCTLN_CCIE_OFS) = 0;
  }

  async command bool CCTL.areEventsEnabled() {
    return BITBAND_PERI(TAx->CCTL[CCRn], TIMER_A_CCTLN_CCIE_OFS);
  }


  async command uint16_t Compare.getEvent() {
    return TAx->CCR[CCRn];
  }


  async command void Compare.setEvent(uint16_t x) {
    TAx->CCR[CCRn] = x;
  }


  async command void Compare.setEventFromPrev(uint16_t delta) {
    TAx->CCR[CCRn] += delta;
  }


  async command void Compare.setEventFromNow(uint16_t delta) {
    TAx->CCR[CCRn] = call Timer.get() + delta;
  }


  async command uint16_t Capture.getEvent() {
    return TAx->CCR[CCRn];
  }


  async command void Capture.setEdge(uint8_t cm) {
    uint16_t t;

    t = TAx->CCTL[CCRn] & ~TIMER_A_CCTLN_CM_MASK;
    t |= ((cm & 3) << TIMER_A_CCTLN_CM_OFS);
    TAx->CCTL[CCRn] = t;
  }


  async command bool Capture.isOverflowPending() {
    return BITBAND_PERI(TAx->CCTL[CCRn], TIMER_A_CCTLN_COV_OFS);
  }


  async command void Capture.clearOverflow() {
    BITBAND_PERI(TAx->CCTL[CCRn], TIMER_A_CCTLN_COV_OFS) = 0;
  }


  async command void Capture.setSynchronous(bool sync) {
    BITBAND_PERI(TAx->CCTL[CCRn], TIMER_A_CCTLN_SCS_OFS) = (sync ? 1 : 0);
  }


  async event void Event.fired() {
    if (BITBAND_PERI(TAx->CCTL[CCRn], TIMER_A_CCTLN_CAP_OFS))
      signal Capture.captured(call Capture.getEvent(),
            BITBAND_PERI(TAx->CCTL[CCRn], TIMER_A_CCTLN_COV_OFS));
    else
      signal Compare.fired();
  }

  async event void Timer.overflow() { }

  default async event void Capture.captured(uint16_t n, bool overflowed) { }
  default async event void Compare.fired() { }
}
