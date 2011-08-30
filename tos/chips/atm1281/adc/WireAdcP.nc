/* $Id: WireAdcP.nc,v 1.4 2006-12-12 18:23:03 vlahan Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Support component for AdcReadClientC and AdcReadNowClientC.
 *
 * @author David Gay
 * @author Janos Sallai <janos.sallai@vanderbilt.edu>
 */

configuration WireAdcP {
  provides {
    interface Read<uint16_t>[uint8_t client]; 
    interface ReadNow<uint16_t>[uint8_t client];
  }
  uses {
    interface Atm128AdcConfig[uint8_t client];
    interface Resource[uint8_t client];
  }
}
implementation {
  components Atm128AdcC, AdcP, BusyWaitMicroC,
    new ArbitratedReadC(uint16_t) as ArbitrateRead;

  Read = ArbitrateRead;
  ReadNow = AdcP;
  Resource = ArbitrateRead.Resource;
  Atm128AdcConfig = AdcP;

  ArbitrateRead.Service -> AdcP.Read;
  AdcP.Atm128AdcSingle -> Atm128AdcC;
  AdcP.BusyWait -> BusyWaitMicroC;
}
