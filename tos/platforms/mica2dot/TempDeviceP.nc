/* $Id: TempDeviceP.nc,v 1.2 2006-07-12 17:02:55 scipio Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Internal component for temp sensor. Arbitrates access to the temp
 * sensor and automatically turns it on or off based on user requests.
 *
 * @author David Gay
 */

#include "hardware.h"

configuration TempDeviceP {
  provides {
    interface Atm128AdcConfig;
    interface ResourceConfigure;
  }
}
implementation {
  components TempP, HplAtm128GeneralIOC as Pins;

  Atm128AdcConfig = TempP;
  ResourceConfigure = TempP;

  TempP.BatMon -> Pins.PortC6;
  TempP.BatMonRef -> Pins.PortC7;
}
