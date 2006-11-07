// $Id: InitThreeP.nc,v 1.3 2006-11-07 19:31:24 scipio Exp $
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
 * Internal mica-family timer component. Sets up hardware timer 3 to run
 * at cpu clock / 8, at boot time. Assumes an ~8MHz CPU clock, replace
 * this component if you are running at a radically different frequency.
 *
 * @author David Gay
 */

#include <MicaTimer.h>

configuration InitThreeP { }
implementation {
  components PlatformC, HplAtm128Timer3C as HWTimer,
    new Atm128TimerInitC(uint16_t, MICA_PRESCALER_THREE) as InitThree;

  PlatformC.SubInit -> InitThree;
  InitThree.Timer -> HWTimer;
}
