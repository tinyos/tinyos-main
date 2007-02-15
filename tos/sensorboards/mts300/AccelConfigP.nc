/* $Id: AccelConfigP.nc,v 1.2 2007-02-15 10:28:46 pipeng Exp $
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

#include "mts300.h"

configuration AccelConfigP {
  provides {
    interface Init;
    interface StdControl;

    interface Atm128AdcConfig as ConfigX;
    interface Atm128AdcConfig as ConfigY;
    interface ResourceConfigure as ResourceX;
    interface ResourceConfigure as ResourceY;
  }
}
implementation {
  components AccelP, MicaBusC;

	Init = AccelP;
	StdControl = AccelP;

  ConfigX = AccelP.ConfigX;
  ConfigY = AccelP.ConfigY;
  ResourceX = AccelP.ResourceX;
  ResourceY = AccelP.ResourceY;

  AccelP.AccelPower -> MicaBusC.PW4;
  AccelP.AccelAdcX -> MicaBusC.Adc3;
  AccelP.AccelAdcY -> MicaBusC.Adc4;
}
