/* $Id: WireAdcStreamP.nc,v 1.1 2009-09-07 14:12:25 r-studio Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Support component for AdcReadStreamClientC.
 *
 * @author Fan Zhang <fanzha@ltu.se>
 */

#include "Adc.h"

configuration WireAdcStreamP {
  provides interface ReadStream<uint16_t>[uint8_t client];
  uses {
    interface M16c62pAdcConfig[uint8_t client];
    interface Resource[uint8_t client];
  }
}
implementation {
  components M16c62pAdcC, AdcStreamP, PlatformC, MainC,
    new AlarmMicro32C(), 
    new ArbitratedReadStreamC(uniqueCount(UQ_ADC_READSTREAM), uint16_t) as ArbitrateReadStream;

  Resource = ArbitrateReadStream;
  ReadStream = ArbitrateReadStream;
  M16c62pAdcConfig = AdcStreamP;

  ArbitrateReadStream.Service -> AdcStreamP;

  AdcStreamP.Init <- MainC;
  AdcStreamP.M16c62pAdcSingle -> M16c62pAdcC;
  //AdcStreamP.M16c62pCalibrate -> PlatformC;
  AdcStreamP.Alarm -> AlarmMicro32C;
}
