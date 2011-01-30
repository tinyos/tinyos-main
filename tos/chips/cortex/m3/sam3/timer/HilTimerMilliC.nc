/**
 * "Copyright (c) 2009 The Regents of the University of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
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
