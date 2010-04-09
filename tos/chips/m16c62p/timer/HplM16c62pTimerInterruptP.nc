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
 * All timer interrupt vector handlers.
 * These are wired in HplM16c62pTimerC.
 *
 * @author Henrik Makitaavola <henrik.makitaavola@gmail.com>
 */

#include "m16c62p_printf.h"

module HplM16c62pTimerInterruptP
{
  provides interface HplM16c62pTimerInterrupt as TimerA0;
  provides interface HplM16c62pTimerInterrupt as TimerA1;
  provides interface HplM16c62pTimerInterrupt as TimerA2;
  provides interface HplM16c62pTimerInterrupt as TimerA3;
  provides interface HplM16c62pTimerInterrupt as TimerA4;
  provides interface HplM16c62pTimerInterrupt as TimerB0;
  provides interface HplM16c62pTimerInterrupt as TimerB1;
  provides interface HplM16c62pTimerInterrupt as TimerB2;
  provides interface HplM16c62pTimerInterrupt as TimerB3;
  provides interface HplM16c62pTimerInterrupt as TimerB4;
  provides interface HplM16c62pTimerInterrupt as TimerB5;
#ifdef THREADS
  uses interface PlatformInterrupt;
#define POST_AMBLE() call PlatformInterrupt.postAmble()
#else 
#define POST_AMBLE()
#endif 
}
implementation
{
  default async event void TimerA0.fired() { } 
  M16C_INTERRUPT_HANDLER(M16C_TMRA0)
  {
    signal TimerA0.fired();
    POST_AMBLE();
  }

  default async event void TimerA1.fired() { } 
  M16C_INTERRUPT_HANDLER(M16C_TMRA1)
  {
    signal TimerA1.fired();
    POST_AMBLE();
  }

  default async event void TimerA2.fired() { } 
  M16C_INTERRUPT_HANDLER(M16C_TMRA2)
  {
    signal TimerA2.fired();
    POST_AMBLE();
  }

  default async event void TimerA3.fired() { } 
  M16C_INTERRUPT_HANDLER(M16C_TMRA3)
  {
    signal TimerA3.fired();
    POST_AMBLE();
  }

  default async event void TimerA4.fired() { } 
  M16C_INTERRUPT_HANDLER(M16C_TMRA4)
  {
    signal TimerA4.fired();
    POST_AMBLE();
  }

  default async event void TimerB0.fired() { } 
  M16C_INTERRUPT_HANDLER(M16C_TMRB0)
  {
    signal TimerB0.fired();
    POST_AMBLE();
  }

  default async event void TimerB1.fired() { } 
  M16C_INTERRUPT_HANDLER(M16C_TMRB1)
  {
    signal TimerB1.fired();
    POST_AMBLE();
  }

  default async event void TimerB2.fired() { } 
  M16C_INTERRUPT_HANDLER(M16C_TMRB2)
  {
    signal TimerB2.fired();
    POST_AMBLE();
  }

  default async event void TimerB3.fired() { } 
  M16C_INTERRUPT_HANDLER(M16C_TMRB3)
  {
    signal TimerB3.fired();
    POST_AMBLE();
  }

  default async event void TimerB4.fired() { } 
  M16C_INTERRUPT_HANDLER(M16C_TMRB4)
  {
    signal TimerB4.fired();
    POST_AMBLE();
  }

  default async event void TimerB5.fired() { } 
  M16C_INTERRUPT_HANDLER(M16C_TMRB5)
  {
    signal TimerB5.fired();
    POST_AMBLE();
  }

}
