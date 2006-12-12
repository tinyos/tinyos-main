// $Id: AlarmOne16C.nc,v 1.4 2006-12-12 18:23:42 vlahan Exp $
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
 * 16-bit 32kHz Alarm component as per TEP102 HAL guidelines. The mica
 * family 32kHz Alarm is built on hardware timer 1, and actually runs at
 * CPU frequency / 256. You can use the MeasureClockC.cyclesPerJiffy()
 * command to figure out the exact frequency.
 * <p>
 * Assumes an ~8MHz CPU clock, replace this component if you are running at
 * a radically different frequency.
 * <p>
 * Upto three of these alarms can be created (one per hardware compare
 * register).
 *
 * @author David Gay <dgay@intel-research.net>
 */

#include <MicaTimer.h>

generic configuration AlarmOne16C()
{
  provides interface Alarm<TOne, uint16_t>;
}
implementation
{
  components HplAtm128Timer1C as HWTimer, InitOneP,
    new Atm128AlarmC(TOne, uint16_t, 3) as NAlarm;
  
  enum {
    COMPARE_ID = unique(UQ_TIMER1_COMPARE)
  };

  Alarm = NAlarm;

  NAlarm.HplAtm128Timer -> HWTimer.Timer;
  NAlarm.HplAtm128Compare -> HWTimer.Compare[COMPARE_ID];
}
