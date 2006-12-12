// $Id: HplAt45dbIOC.nc,v 1.4 2006-12-12 18:23:43 vlahan Exp $
/*
 * Copyright (c) 2005-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Low-level access functions for the AT45DB flash on the mica2 and micaz.
 *
 * @author David Gay
 */

configuration HplAt45dbIOC {
  provides {
    interface Resource;
    interface SpiByte as FlashSpi;
    interface HplAt45dbByte;
  }
}
implementation {
  // Wire up byte I/O to At45db
  components HplAt45dbIOP, HplAtm128GeneralIOC as Pins, PlatformC;
  components new NoArbiterC();

  Resource = NoArbiterC;
  FlashSpi = HplAt45dbIOP;
  HplAt45dbByte = HplAt45dbIOP;

  PlatformC.SubInit -> HplAt45dbIOP;
  HplAt45dbIOP.Select -> Pins.PortE5;
  HplAt45dbIOP.Clk -> Pins.PortA3;
  HplAt45dbIOP.In -> Pins.PortA6;
  HplAt45dbIOP.Out -> Pins.PortA7;
}
