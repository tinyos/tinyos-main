/* $Id: WireAccelP.nc,v 1.1 2007-02-08 17:55:36 idgay Exp $
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

configuration WireAccelP { 
  provides interface Resource[uint8_t client];
}
implementation {
  components AccelP, MicaBusC, new TimerMilliC() as WarmupTimer,
    new RounRobinArbiterC(UQ_ACCEL_RESOURCE) as Arbiter,
    new SplitControlPowerManagerC() as PowerManager;

  Resource = Arbiter;

  PowerManager.ResourceDefaultOwner -> Arbiter;
  PowerManager.ArbiterInfo -> Arbiter;
  PowerManager.SplitControl -> AccelP;

  AccelP.Timer -> WarmupTimer;
  AccelP.AccelPin -> MicaBusC.PW4;
  AccelP.AccelAdcX -> MicaBusC.Adc3;
  AccelP.AccelAdcY -> MicaBusC.Adc4;
}
