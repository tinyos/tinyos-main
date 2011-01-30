/**
 * Copyright (c) 2009 The Regents of the University of California.
 * All rights reserved.
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
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/** 
 * @author Thomas Schmid
 *
 */

#include "Timer.h"

configuration HilTimerMilliC
{
  provides 
  {
      interface Init;
      interface Timer<TMilli> as TimerMilli[ uint8_t num ];
      interface LocalTime<TMilli>;
  }
}

implementation
{
  components new VirtualizeTimerC(TMilli,uniqueCount(UQ_TIMER_MILLI)) as VirtTimersMilli32;
  components new AlarmToTimerC(TMilli) as AlarmToTimerMilli32;
  components new AlarmMilliC() as AlarmMilli32;
  components HalSam3RttC;

  Init = HalSam3RttC;
  TimerMilli = VirtTimersMilli32.Timer;
  LocalTime = HalSam3RttC;
  
  VirtTimersMilli32.TimerFrom -> AlarmToTimerMilli32.Timer;
  AlarmToTimerMilli32.Alarm -> AlarmMilli32.Alarm;
}
