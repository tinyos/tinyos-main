/* $Id: TempC.nc,v 1.1 2007-08-21 04:44:09 klueska Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Photodiode of the mda100 sensor board.
 * 
 * @author David Gay
 */

#include "mda100.h"

generic configuration TempC() {
  provides interface Read<uint16_t>;
}
implementation {
  components ArbitratedTempDeviceP;

  Read = ArbitratedTempDeviceP.Read[unique(UQ_MDA100_TEMP_RESOURCE)];
}
