/* $Id: AccelXC.nc,v 1.3 2007-03-14 04:57:35 pipeng Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Acceldiode of the basicsb sensor board.
 * 
 * @author David Gay
 */

#include "mts300.h"

generic configuration AccelXC()
{
  provides interface Read<uint16_t>;
}
implementation {
  enum {
    ID = unique(UQ_ACCEL_RESOURCE)
  };
  
  components AccelReadP,AccelConfigP, new AdcReadClientC() as AdcX;

  Read = AccelReadP.ReadX[ID];
  AccelReadP.ActualX[ID] -> AdcX;
  AdcX.Atm128AdcConfig -> AccelConfigP.ConfigX;
}

