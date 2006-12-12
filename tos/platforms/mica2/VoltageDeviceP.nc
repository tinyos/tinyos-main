/* $Id: VoltageDeviceP.nc,v 1.4 2006-12-12 18:23:43 vlahan Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Internal component for voltage sensor. Arbitrates access to the voltage
 * sensor and automatically turns it on or off based on user requests.
 * 
 * @author David Gay
 */

#include "hardware.h"

configuration VoltageDeviceP {
  provides {
    interface Atm128AdcConfig;
    interface ResourceConfigure;
  }
}
implementation {
  components VoltageP, HplAtm128GeneralIOC as Pins;

  Atm128AdcConfig = VoltageP;
  ResourceConfigure = VoltageP;

  VoltageP.BatMon -> Pins.PortA5;
}
