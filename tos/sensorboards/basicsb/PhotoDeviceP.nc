/* $Id: PhotoDeviceP.nc,v 1.3 2006-11-07 19:31:27 scipio Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Internal component for basicsb photodiode. Arbitrates access to the photo
 * diode and automatically turns it on or off based on user requests.
 * 
 * @author David Gay
 */

#include "basicsb.h"

configuration PhotoDeviceP {
  provides {
    interface ResourceConfigure;
    interface Atm128AdcConfig;
  }
}
implementation {
  components PhotoP, MicaBusC;

  ResourceConfigure = PhotoP;
  Atm128AdcConfig = PhotoP;

  PhotoP.PhotoPin -> MicaBusC.PW1;
  PhotoP.PhotoAdc -> MicaBusC.Adc6;
}
