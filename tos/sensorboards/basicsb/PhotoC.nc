/* $Id: PhotoC.nc,v 1.4 2006-12-12 18:23:45 vlahan Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Photodiode of the basicsb sensor board.
 * 
 * @author David Gay
 */

#include "basicsb.h"

generic configuration PhotoC() {
  provides interface Read<uint16_t>;
}
implementation {
  components new AdcReadClientC(), PhotoDeviceP;

  Read = AdcReadClientC;
  AdcReadClientC.Atm128AdcConfig -> PhotoDeviceP;
  AdcReadClientC.ResourceConfigure -> PhotoDeviceP;
}
