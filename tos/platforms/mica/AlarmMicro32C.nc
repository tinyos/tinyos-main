// $Id: AlarmMicro32C.nc,v 1.4 2006-12-12 18:23:42 vlahan Exp $
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
 * 32-bit microsecond Alarm component as per TEP102 HAL guidelines. The
 * mica family microsecond Alarm is built on hardware timer 3, and actually
 * runs at CPU frequency / 8. You can use the MeasureClockC.cyclesPerJiffy() 
 * command to figure out the exact frequency, or the 
 * MeasureClockC.calibrateMicro() command to convert a number of microseconds
 * to the near-microsecond units used by this component.
 * <p>
 * Upto three of these alarms can be created (one per hardware compare
 * register). Note that creating one of these Alarms consumes a 16-bit
 * microsecond Alarm (see AlarmMicro16C).
 *
 * @author David Gay <dgay@intel-research.net>
 */

#include <MicaTimer.h>

generic configuration AlarmMicro32C()
{
  provides interface Alarm<TMicro, uint32_t>;
}
implementation
{
  components new AlarmThree16C() as Alarm16, CounterMicro32C as Counter32,
    new TransformAlarmC(TMicro, uint32_t, TThree, uint16_t,
			MICA_DIVIDE_THREE_FOR_MICRO_LOG2) as Transform32;

  Alarm = Transform32;
  Transform32.AlarmFrom -> Alarm16;
  Transform32.Counter -> Counter32;
}
