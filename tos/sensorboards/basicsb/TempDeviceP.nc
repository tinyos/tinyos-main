/* $Id: TempDeviceP.nc,v 1.4 2006-12-12 18:23:45 vlahan Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Internal component for basicsb tempdiode. Arbitrates access to the temp
 * diode and automatically turns it on or off based on user requests.
 * 
 * @author David Gay
 */

#include "basicsb.h"

configuration TempDeviceP {
  provides {
    interface ResourceConfigure;
    interface Atm128AdcConfig;
  }
}
implementation {
  components TempP, MicaBusC;

  ResourceConfigure = TempP;
  Atm128AdcConfig = TempP;

  TempP.TempPin -> MicaBusC.PW2;
  TempP.TempAdc -> MicaBusC.Adc5;
}
