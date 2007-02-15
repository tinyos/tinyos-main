/* $Id: MagConfigP.nc,v 1.1 2007-02-15 10:33:37 pipeng Exp $
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
#include "I2C.h"

configuration MagConfigP {
  provides {
    interface Init;
    interface StdControl;
    interface Mag;

    interface Atm128AdcConfig as ConfigX;
    interface Atm128AdcConfig as ConfigY;
    interface ResourceConfigure as ResourceX;
    interface ResourceConfigure as ResourceY;
  }
}
implementation {
  components MagP, MicaBusC, new Atm128I2CMasterC() as I2CPot;

	Init = MagP;
	StdControl = MagP;
	Mag = MagP;

  ConfigX = MagP.ConfigX;
  ConfigY = MagP.ConfigY;
  ResourceX = MagP.ResourceX;
  ResourceY = MagP.ResourceY;

  MagP.I2CPacket -> I2CPot;
  MagP.Resource -> I2CPot;

  MagP.MagPower -> MicaBusC.PW5;
  MagP.MagAdcX -> MicaBusC.Adc6;
  MagP.MagAdcY -> MicaBusC.Adc5;
}
