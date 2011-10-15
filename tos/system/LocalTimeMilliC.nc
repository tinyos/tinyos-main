/* $Id: LocalTimeMilliC.nc,v 1.1 2007-05-23 21:58:08 idgay Exp $
 * Copyright (c) 2007 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 *
 */
/**
 * Provide current time via the LocalTime<TMilli> interface.
 *
 * @author David Gay
 */

#include "Timer.h"

configuration LocalTimeMilliC {
  provides interface LocalTime<TMilli>;
}
implementation
{
  components HilTimerMilliC, TimerMilliP;

  LocalTime = HilTimerMilliC;
}
