/* $Id: WireAdcP.nc,v 1.3 2006-11-07 19:30:44 scipio Exp $
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
  components Atm128AdcC, AdcP,
    new ArbitratedReadC(uint16_t) as ArbitrateRead;

  Read = ArbitrateRead;
  ReadNow = AdcP;
  Resource = ArbitrateRead.Resource;
  Atm128AdcConfig = AdcP;

  ArbitrateRead.Service -> AdcP.Read;
  AdcP.Atm128AdcSingle -> Atm128AdcC;
}
