/* $Id: TempStreamC.nc,v 1.2 2006-07-12 17:03:15 scipio Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Thermistor of the basicsb sensor board.
 * 
 * @author David Gay
 */

#include "basicsb.h"

generic configuration TempStreamC() {
  provides interface ReadStream<uint16_t>;
}
implementation {
  components TempDeviceP, new AdcReadStreamClientC();

  ReadStream = AdcReadStreamClientC;
  AdcReadStreamClientC.Atm128AdcConfig -> TempDeviceP;
  AdcReadStreamClientC.ResourceConfigure -> TempDeviceP;
}
