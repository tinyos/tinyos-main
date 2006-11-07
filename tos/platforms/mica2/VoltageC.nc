/* $Id: VoltageC.nc,v 1.3 2006-11-07 19:31:24 scipio Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Voltage sensor.
 * 
 * @author David Gay
 */

#include "hardware.h"

generic configuration VoltageC() {
  provides interface Read<uint16_t>;
}
implementation {
  components new AdcReadClientC(), VoltageDeviceP;

  Read = AdcReadClientC;
  AdcReadClientC.Atm128AdcConfig -> VoltageDeviceP;
  AdcReadClientC.ResourceConfigure -> VoltageDeviceP;
}
