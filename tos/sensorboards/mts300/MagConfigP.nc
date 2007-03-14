/* $Id: MagConfigP.nc,v 1.2 2007-03-14 03:25:05 pipeng Exp $
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
 * @author Alif Chen
 */

#include "mts300.h"
#include "I2C.h"

configuration MagConfigP {
  provides {
    interface Mag;
    interface Resource[uint8_t client];
    interface Atm128AdcConfig as ConfigX;
    interface Atm128AdcConfig as ConfigY;
  }
}
implementation {
  components MagP, MicaBusC, new Atm128I2CMasterC() as I2CPot,
		new TimerMilliC() as WarmupTimer,
    new RoundRobinArbiterC(UQ_MAG_RESOURCE) as Arbiter,
    new SplitControlPowerManagerC() as PowerManager;

	Mag = MagP;

  Resource = Arbiter;
  ConfigX = MagP.ConfigX;
  ConfigY = MagP.ConfigY;

  PowerManager.ResourceDefaultOwner -> Arbiter;
  PowerManager.ArbiterInfo -> Arbiter;
  PowerManager.SplitControl -> MagP;

  MagP.I2CPacket -> I2CPot;
  MagP.I2CResource -> I2CPot;

  MagP.Timer -> WarmupTimer;
  MagP.MagPower -> MicaBusC.PW5;
  MagP.MagAdcX -> MicaBusC.Adc6;
  MagP.MagAdcY -> MicaBusC.Adc5;
}
