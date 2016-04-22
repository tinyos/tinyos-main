// $Id: AlarmCounterMilliP.nc,v 1.7 2007-07-06 17:33:22 scipio Exp $
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
#include <Atm128Timer.h>

#include <Atm128Timer.h>

configuration AlarmCounterMilliP
{
  provides interface Init;
  provides interface Alarm<TMilli, uint32_t> as AlarmMilli32;
  provides interface Counter<TMilli, uint32_t> as CounterMilli32;
}
implementation
{
  components new Atm128AlarmAsyncC(TMilli, ATM128_CLK8_DIVIDE_32);

  Init = Atm128AlarmAsyncC;
  AlarmMilli32 = Atm128AlarmAsyncC;
  CounterMilli32 = Atm128AlarmAsyncC;
}
