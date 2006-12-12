// $Id: AlarmThree16C.nc,v 1.4 2006-12-12 18:23:42 vlahan Exp $
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
 * 16-bit microsecond Alarm component as per TEP102 HAL guidelines. The
 * mica family microsecond Alarm is built on hardware timer 3, and actually
 * runs at CPU frequency / 8. You can use the MeasureClockC.cyclesPerJiffy() 
 * command to figure out the exact frequency, or the 
 * MeasureClockC.calibrateMicro() command to convert a number of microseconds
 * to the near-microsecond units used by this component.
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

generic configuration AlarmThree16C()
{
  provides interface Alarm<TThree, uint16_t>;
}
implementation
{
  components HplAtm128Timer3C as HWTimer, InitThreeP,
    new Atm128AlarmC(TThree, uint16_t, 100) as NAlarm;
  
  enum {
    COMPARE_ID = unique(UQ_TIMER3_COMPARE)
  };

  Alarm = NAlarm;

  NAlarm.HplAtm128Timer -> HWTimer.Timer;
  NAlarm.HplAtm128Compare -> HWTimer.Compare[COMPARE_ID];
}
