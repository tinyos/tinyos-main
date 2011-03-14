/* $Id: WireAdcP.nc,v 1.1 2009-09-07 14:12:25 r-studio Exp $
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
    interface M16c60AdcConfig[uint8_t client];
    interface Resource[uint8_t client];
  }
}
implementation {
  components M16c60AdcC, AdcP,
    new ArbitratedReadC(uint16_t) as ArbitrateRead;

  Read = ArbitrateRead;
  ReadNow = AdcP;
  Resource = ArbitrateRead.Resource;
  M16c60AdcConfig = AdcP;	// provide default M16c60AdcConfig interface

  ArbitrateRead.Service -> AdcP.Read;
  AdcP.M16c60AdcSingle -> M16c60AdcC;
}
