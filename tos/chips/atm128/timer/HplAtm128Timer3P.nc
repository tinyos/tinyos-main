/// $Id: HplAtm128Timer3P.nc,v 1.5 2010-05-07 04:32:15 sallai Exp $

/*
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. 
 *
 * CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS 
 * ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS ANY 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
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
