/// $Id: HplAtm128Timer2C.nc,v 1.2 2010-06-29 22:07:51 scipio Exp $

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
 * HPL interface to Atmega128 timer 2.
 *
 * @author Martin Turon <mturon@xbow.com>
 */

#include <Atm128Timer.h>

module HplAtm128Timer2C
{
  provides {
    interface HplAtm128Timer<uint8_t>   as Timer;
    interface HplAtm128TimerCtrl8       as TimerCtrl;
    interface HplAtm128Compare<uint8_t> as Compare;
  }
  uses interface ThreadScheduler;
}
implementation
{
  //=== Read the current timer value. ===================================
  async command uint8_t  Timer.get() { return TCNT2; }

  //=== Set/clear the current timer value. ==============================
  async command void Timer.set(uint8_t t)  { TCNT2 = t; }

  //=== Read the current timer scale. ===================================
  async command uint8_t Timer.getScale() { return TCCR2 & 0x7; }

  //=== Turn off the timers. ============================================
  async command void Timer.off() { call Timer.setScale(AVR_CLOCK_OFF); }

  //=== Write a new timer scale. ========================================
  async command void Timer.setScale(uint8_t s)  { 
    Atm128TimerControl_t x = call TimerCtrl.getControl();
    x.bits.cs = s;
    call TimerCtrl.setControl(x);  
  }

  //=== Read the control registers. =====================================
  async command Atm128TimerControl_t TimerCtrl.getControl() { 
    return *(Atm128TimerControl_t*)&TCCR2; 
  }

  //=== Control registers utilities. ==================================
  DEFINE_UNION_CAST(TimerCtrlCompareint, Atm128TimerCtrlCompare_t, uint16_t);
  DEFINE_UNION_CAST(TimerCtrlCapture2int, Atm128TimerCtrlCapture_t, uint16_t);
  DEFINE_UNION_CAST(TimerCtrlClock2int, Atm128TimerCtrlClock_t, uint16_t);

  //=== Write the control registers. ====================================
  async command void TimerCtrl.setControl( Atm128TimerControl_t x ) { 
    TCCR2 = x.flat; 
  }

  //=== Read the interrupt mask. =====================================
  async command Atm128_TIMSK_t TimerCtrl.getInterruptMask() { 
    return *(Atm128_TIMSK_t*)&TIMSK; 
  }

  //=== Write the interrupt mask. ====================================
  DEFINE_UNION_CAST(TimerMask8_2int, Atm128_TIMSK_t, uint8_t);

  async command void TimerCtrl.setInterruptMask( Atm128_TIMSK_t x ) { 
    TIMSK = TimerMask8_2int(x); 
  }

  //=== Read the interrupt flags. =====================================
  async command Atm128_TIFR_t TimerCtrl.getInterruptFlag() { 
    return *(Atm128_TIFR_t*)&TIFR; 
  }

  //=== Write the interrupt flags. ====================================
  DEFINE_UNION_CAST(TimerFlags8_2int, Atm128_TIFR_t, uint8_t);

  async command void TimerCtrl.setInterruptFlag( Atm128_TIFR_t x ) { 
    TIFR = TimerFlags8_2int(x); 
  }

  //=== Timer 8-bit implementation. ====================================
  async command void Timer.reset() { TIFR = 1 << TOV2; }
  async command void Timer.start() { SET_BIT(TIMSK,TOIE2); }
  async command void Timer.stop()  { CLR_BIT(TIMSK,TOIE2); }
  async command bool Timer.test()  { 
    return (call TimerCtrl.getInterruptFlag()).bits.tov2; 
  }
  async command bool Timer.isOn()  { 
    return (call TimerCtrl.getInterruptMask()).bits.toie2; 
  }
  async command void Compare.reset() { TIFR = 1 << OCF2; }
  async command void Compare.start() { SET_BIT(TIMSK,OCIE2); }
  async command void Compare.stop()  { CLR_BIT(TIMSK,OCIE2); }
  async command bool Compare.test()  { 
    return (call TimerCtrl.getInterruptFlag()).bits.ocf2; 
  }
  async command bool Compare.isOn()  { 
    return (call TimerCtrl.getInterruptMask()).bits.ocie2; 
  }

  //=== Read the compare registers. =====================================
  async command uint8_t Compare.get()   { return OCR2; }

  //=== Write the compare registers. ====================================
  async command void Compare.set(uint8_t t)   { OCR2 = t; }

  //=== Timer interrupts signals ========================================
  default async event void Compare.fired() { }
  AVR_NONATOMIC_HANDLER(SIG_OUTPUT_COMPARE2) {
    signal Compare.fired();
    call ThreadScheduler.interruptPostAmble();
  }
  default async event void Timer.overflow() { }
  AVR_NONATOMIC_HANDLER(SIG_OVERFLOW2) {
    signal Timer.overflow();
    call ThreadScheduler.interruptPostAmble();
  }
}
