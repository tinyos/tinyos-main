// $Id: AlarmCounterMilliP.nc,v 1.4 2006-12-12 18:23:42 vlahan Exp $
/*
 * Copyright (c) 2005-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Configure hardware timer 0 for use as the mica family's millisecond
 * timer.  This component does not follow the TEP102 HAL guidelines as
 * there is only one compare register for timer 0, which is used to
 * implement HilTimerMilliC. Hence it isn't useful to expose an
 * AlarmMilliC or CounterMillIC component.
 * 
 * @author David Gay <dgay@intel-research.net>
 * @author Martin Turon <mturon@xbow.com>
 */

configuration AlarmCounterMilliP
{
  provides interface Init;
  provides interface Alarm<TMilli, uint32_t> as AlarmMilli32;
  provides interface Counter<TMilli, uint32_t> as CounterMilli32;
}
implementation
{
  components HplAtm128Timer0AsyncC as Timer0, PlatformC,
    new Atm128TimerInitC(uint8_t, ATM128_CLK8_DIVIDE_32) as MilliInit,
    new Atm128AlarmC(TMilli, uint8_t, 2) as MilliAlarm,
    new Atm128CounterC(TMilli, uint8_t) as MilliCounter, 
    new TransformAlarmCounterC(TMilli, uint32_t, TMilli, uint8_t, 0, uint32_t)
      as Transform32;

  // Top-level interface wiring
  AlarmMilli32 = Transform32;
  CounterMilli32 = Transform32;

  // Strap in low-level hardware timer (Timer0Async)
  Init = MilliInit;
  MilliInit.Timer -> Timer0.Timer;
  MilliAlarm.HplAtm128Timer -> Timer0.Timer;
  MilliAlarm.HplAtm128Compare -> Timer0.Compare;
  MilliCounter.Timer -> Timer0.Timer;
  PlatformC.SubInit -> Timer0;

  // Alarm Transform Wiring
  Transform32.AlarmFrom -> MilliAlarm;
  Transform32.CounterFrom -> MilliCounter;
}
