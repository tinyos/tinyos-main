/// $Id: HplAtm128Timer3P.nc,v 1.6 2010-06-29 22:07:43 scipio Exp $

/*
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
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
 * - Neither the name of Crossbow Technology nor the names of
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

/**
 * Internal componentr of the HPL interface to Atmega128 timer 3.
 *
 * @author Martin Turon <mturon@xbow.com>
 */

#include <Atm128Timer.h>

module HplAtm128Timer3P
{
  provides {
    interface HplAtm128Timer<uint16_t>   as Timer;
    interface HplAtm128TimerCtrl16       as TimerCtrl;
    interface HplAtm128Capture<uint16_t> as Capture;
    interface HplAtm128Compare<uint16_t> as CompareA;
    interface HplAtm128Compare<uint16_t> as CompareB;
    interface HplAtm128Compare<uint16_t> as CompareC;
  }
}
implementation
{
  //=== Read the current timer value. ===================================
  async command uint16_t Timer.get() { return TCNT3; }

  //=== Set/clear the current timer value. ==============================
  async command void Timer.set(uint16_t t) { TCNT3 = t; }

  //=== Read the current timer scale. ===================================
  async command uint8_t Timer.getScale() { return TCCR3B & 0x7; }

  //=== Turn off the timers. ============================================
  async command void Timer.off() { call Timer.setScale(AVR_CLOCK_OFF); }

  //=== Write a new timer scale. ========================================
  async command void Timer.setScale(uint8_t s)  { 
    Atm128TimerCtrlCapture_t x = call TimerCtrl.getCtrlCapture();
    x.bits.cs = s;
    call TimerCtrl.setCtrlCapture(x);  
  }

  //=== Read the control registers. =====================================
  async command Atm128TimerCtrlCompare_t TimerCtrl.getCtrlCompare() { 
    return *(Atm128TimerCtrlCompare_t*)&TCCR3A; 
  }
  async command Atm128TimerCtrlCapture_t TimerCtrl.getCtrlCapture() { 
    return *(Atm128TimerCtrlCapture_t*)&TCCR3B; 
  }
  async command Atm128TimerCtrlClock_t TimerCtrl.getCtrlClock() { 
    return *(Atm128TimerCtrlClock_t*)&TCCR3C; 
  }


  //=== Control registers utilities. ==================================
  DEFINE_UNION_CAST(TimerCtrlCompare2int, Atm128TimerCtrlCompare_t, uint16_t);
  DEFINE_UNION_CAST(TimerCtrlCapture2int, Atm128TimerCtrlCapture_t, uint16_t);
  DEFINE_UNION_CAST(TimerCtrlClock2int, Atm128TimerCtrlClock_t, uint16_t);

  //=== Write the control registers. ====================================
  async command void TimerCtrl.setCtrlCompare( Atm128_TCCR3A_t x ) { 
    TCCR3A = TimerCtrlCompare2int(x); 
  }
  async command void TimerCtrl.setCtrlCapture( Atm128_TCCR3B_t x ) { 
    TCCR3B = TimerCtrlCapture2int(x); 
  }
  async command void TimerCtrl.setCtrlClock( Atm128_TCCR3C_t x ) { 
    TCCR3C = TimerCtrlClock2int(x); 
  }

  //=== Read the interrupt mask. =====================================
  async command Atm128_ETIMSK_t TimerCtrl.getInterruptMask() { 
    return *(Atm128_ETIMSK_t*)&ETIMSK; 
  }

  //=== Write the interrupt mask. ====================================
  DEFINE_UNION_CAST(TimerMask16_2int, Atm128_ETIMSK_t, uint8_t);

  async command void TimerCtrl.setInterruptMask( Atm128_ETIMSK_t x ) { 
    ETIMSK = TimerMask16_2int(x); 
  }

  //=== Read the interrupt flags. =====================================
  async command Atm128_ETIFR_t TimerCtrl.getInterruptFlag() { 
    return *(Atm128_ETIFR_t*)&ETIFR; 
  }

  //=== Write the interrupt flags. ====================================
  DEFINE_UNION_CAST(TimerFlags16_2int, Atm128_ETIFR_t, uint8_t);

  async command void TimerCtrl.setInterruptFlag( Atm128_ETIFR_t x ) { 
    ETIFR = TimerFlags16_2int(x); 
  }

  //=== Capture 16-bit implementation. ===================================
  async command void Capture.setEdge(bool up) { WRITE_BIT(TCCR3B,ICES3, up); }

  //=== Timer 16-bit implementation. ===================================
  async command void Timer.reset()    { ETIFR = 1 << TOV3; }
  async command void Capture.reset()  { ETIFR = 1 << ICF3; }
  async command void CompareA.reset() { ETIFR = 1 << OCF3A; }
  async command void CompareB.reset() { ETIFR = 1 << OCF3B; }
  async command void CompareC.reset() { ETIFR = 1 << OCF3C; }

  async command void Timer.start()    { SET_BIT(ETIMSK,TOIE3); }
  async command void Capture.start()  { SET_BIT(ETIMSK,TICIE3); }
  async command void CompareA.start() { SET_BIT(ETIMSK,OCIE3A); }
  async command void CompareB.start() { SET_BIT(ETIMSK,OCIE3B); }
  async command void CompareC.start() { SET_BIT(ETIMSK,OCIE3C); }

  async command void Timer.stop()    { CLR_BIT(ETIMSK,TOIE3); }
  async command void Capture.stop()  { CLR_BIT(ETIMSK,TICIE3); }
  async command void CompareA.stop() { CLR_BIT(ETIMSK,OCIE3A); }
  async command void CompareB.stop() { CLR_BIT(ETIMSK,OCIE3B); }
  async command void CompareC.stop() { CLR_BIT(ETIMSK,OCIE3C); }

  async command bool Timer.test() { 
    return (call TimerCtrl.getInterruptFlag()).bits.tov3; 
  }
  async command bool Capture.test()  { 
    return (call TimerCtrl.getInterruptFlag()).bits.icf3; 
  }
  async command bool CompareA.test() { 
    return (call TimerCtrl.getInterruptFlag()).bits.ocf3a; 
  }
  async command bool CompareB.test() { 
    return (call TimerCtrl.getInterruptFlag()).bits.ocf3b; 
  }
  async command bool CompareC.test() { 
    return (call TimerCtrl.getInterruptFlag()).bits.ocf3c; 
  }

  async command bool Timer.isOn() {
    return (call TimerCtrl.getInterruptMask()).bits.toie3;
  }
  async command bool Capture.isOn()  {
    return (call TimerCtrl.getInterruptMask()).bits.ticie3;
  }
  async command bool CompareA.isOn() {
    return (call TimerCtrl.getInterruptMask()).bits.ocie3a;
  }
  async command bool CompareB.isOn() {
    return (call TimerCtrl.getInterruptMask()).bits.ocie3b;
  }
  async command bool CompareC.isOn() {
    return (call TimerCtrl.getInterruptMask()).bits.ocie3c;
  }

  //=== Read the compare registers. =====================================
  async command uint16_t CompareA.get() { return OCR3A; }
  async command uint16_t CompareB.get() { return OCR3B; }
  async command uint16_t CompareC.get() { return OCR3C; }

  //=== Write the compare registers. ====================================
  async command void CompareA.set(uint16_t t) { OCR3A = t; }
  async command void CompareB.set(uint16_t t) { OCR3B = t; }
  async command void CompareC.set(uint16_t t) { OCR3C = t; }

  //=== Read the capture registers. =====================================
  async command uint16_t Capture.get() { return ICR3; }

  //=== Write the capture registers. ====================================
  async command void Capture.set(uint16_t t)  { ICR3 = t; }

  //=== Timer interrupts signals ========================================
  default async event void CompareA.fired() { }
  AVR_NONATOMIC_HANDLER(SIG_OUTPUT_COMPARE3A) {
    signal CompareA.fired();
  }
  default async event void CompareB.fired() { }
  AVR_NONATOMIC_HANDLER(SIG_OUTPUT_COMPARE3B) {
    signal CompareB.fired();
  }
  default async event void CompareC.fired() { }
  AVR_NONATOMIC_HANDLER(SIG_OUTPUT_COMPARE3C) {
    signal CompareC.fired();
  }
  default async event void Capture.captured(uint16_t time) { }
  AVR_NONATOMIC_HANDLER(SIG_INPUT_CAPTURE3) {
    signal Capture.captured(call Capture.get());
  }
  default async event void Timer.overflow() { }
  AVR_NONATOMIC_HANDLER(SIG_OVERFLOW3) {
    signal Timer.overflow();
  }
}
