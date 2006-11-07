// $Id: HplAt45dbIOC.nc,v 1.3 2006-11-07 19:31:24 scipio Exp $
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
  components HplAt45dbIOP, HplAtm128GeneralIOC as Pins, HplAtm128InterruptC, PlatformC;
  components BusyWaitMicroC;
  components new NoArbiterC();

  Resource = NoArbiterC;
  FlashSpi = HplAt45dbIOP;
  HplAt45dbByte = HplAt45dbIOP;

  PlatformC.SubInit -> HplAt45dbIOP;
  HplAt45dbIOP.Select -> Pins.PortA3;
  HplAt45dbIOP.Clk -> Pins.PortD5;
  HplAt45dbIOP.In -> Pins.PortD2;
  HplAt45dbIOP.Out -> Pins.PortD3;
  HplAt45dbIOP.InInterrupt -> HplAtm128InterruptC.Int2;
  HplAt45dbIOP.BusyWait -> BusyWaitMicroC;
}
