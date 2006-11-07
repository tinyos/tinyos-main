/* $Id: PhotoStreamC.nc,v 1.3 2006-11-07 19:31:27 scipio Exp $
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

generic configuration PhotoStreamC() {
  provides interface ReadStream<uint16_t>;
}
implementation {
  components PhotoDeviceP, new AdcReadStreamClientC();

  ReadStream = AdcReadStreamClientC;
  AdcReadStreamClientC.Atm128AdcConfig -> PhotoDeviceP;
  AdcReadStreamClientC.ResourceConfigure -> PhotoDeviceP;
}
