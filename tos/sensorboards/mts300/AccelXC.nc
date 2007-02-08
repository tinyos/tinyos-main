/* $Id: AccelXC.nc,v 1.1 2007-02-08 17:55:35 idgay Exp $
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

generic configuration AccelXC() {
  provides interface Read<uint16_t>;
}
implementation {
  components AccelReadP;

  Read = AccelReadP.ReadX[unique(UQ_ACCEL_RESOURCE)];
}
