// $Id: CounterThree16C.nc,v 1.3 2006-11-07 19:31:24 scipio Exp $
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
 * 16-bit microsecond Counter component as per TEP102 HAL guidelines. The
 * mica family microsecond clock is built on hardware timer 3, and actually
 * runs at CPU frequency / 8. You can use the MeasureClockC.cyclesPerJiffy() 
 * command to figure out the exact frequency.
 *
 * @author David Gay <dgay@intel-research.net>
 */

#include <MicaTimer.h>

configuration CounterThree16C
{
  provides interface Counter<TThree, uint16_t>;
}
implementation
{
  components HplAtm128Timer3C as HWTimer, InitThreeP,
    new Atm128CounterC(TThree, uint16_t) as NCounter;
  
  Counter = NCounter;
  NCounter.Timer -> HWTimer;
}
