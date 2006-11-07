/* $Id: VoltageDeviceP.nc,v 1.3 2006-11-07 19:31:25 scipio Exp $
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

  VoltageP.BatMon -> Pins.PortC6;
  VoltageP.BatMonRef -> Pins.PortC7;
}
