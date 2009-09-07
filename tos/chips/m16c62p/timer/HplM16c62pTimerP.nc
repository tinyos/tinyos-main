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
 * Implementation of a generic HplM16c62pTimer interface.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */
generic module HplM16c62pTimerP (uint16_t timer_addr,
                                 uint16_t interrupt_addr,
                                 uint16_t start_addr,
                                 uint8_t start_bit)
{
  provides interface HplM16c62pTimer as Timer;

  uses interface HplM16c62pTimerInterrupt as IrqSignal;
  uses interface StopModeControl;
}
implementation
{
#define timer (*TCAST(volatile uint16_t* ONE, timer_addr))
#define start (*TCAST(volatile uint8_t* ONE, start_addr))
#define interrupt (*TCAST(volatile uint8_t* ONE, interrupt_addr))

  bool allow_stop_mode = false;

  async command uint16_t Timer.get() { return timer; }
  
  async command void Timer.set( uint16_t t )
  {
    // If the timer is on it must be turned off, else the value will
    // only be written to the reload register.
    atomic
    {
      if(call Timer.isOn())
      {
        call Timer.off();
        timer = t;
        call Timer.on();
      }
      else
      {
        timer = t;
      }
    }
  }

  // When the timer is turned on in one-shot mode on TimerA
  // the timer also needs an trigger event to start counting.
  async command void Timer.on()
  { 
    atomic if (!allow_stop_mode)
    {
      call StopModeControl.allowStopMode(false);
    }
    SET_BIT(start, start_bit); 
  }
  
  async command void Timer.off()
  { 
    CLR_BIT(start, start_bit);
    atomic if (!allow_stop_mode)
    {
      call StopModeControl.allowStopMode(true);
    }
  }
  
  async command bool Timer.isOn() { return READ_BIT(start, start_bit); }
  async command void Timer.clearInterrupt() { clear_interrupt(interrupt_addr); }
  async command void Timer.enableInterrupt() { SET_BIT(interrupt, 0); }
  async command void Timer.disableInterrupt() { CLR_BIT(interrupt, 0); }
  async command bool Timer.testInterrupt() { return READ_BIT(interrupt, 3); }
  async command bool Timer.isInterruptOn() { return READ_BIT(interrupt, 0); }

  async command void Timer.allowStopMode(bool allow)
  {
    allow_stop_mode = allow;
  }
 
  // Forward the timer interrupt event.  
  async event void IrqSignal.fired() { signal Timer.fired(); }

  default async event void Timer.fired() { } 
}
