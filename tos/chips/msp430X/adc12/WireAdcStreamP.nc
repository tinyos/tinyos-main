/* $Id: WireAdcStreamP.nc,v 1.1 2008/04/07 09:41:55 janhauer Exp $
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
 * @author David Gay
 * @author Jan Hauer 
 */

#include "Msp430Adc12.h"

configuration WireAdcStreamP {
  provides interface ReadStream<uint16_t>[uint8_t client];
  uses {
    interface AdcConfigure<const msp430adc12_channel_config_t*>[uint8_t client];
    interface Msp430Adc12SingleChannel[uint8_t client];
    interface Resource[uint8_t client];
  }
}
implementation {
  components AdcStreamP, MainC, new AlarmMilli32C() as Alarm, 
    new ArbitratedReadStreamC(uniqueCount(ADCC_READ_STREAM_SERVICE), uint16_t) as ArbitrateReadStream;

  ReadStream = ArbitrateReadStream;
  AdcConfigure = AdcStreamP;
  Resource = ArbitrateReadStream;

  ArbitrateReadStream.Service -> AdcStreamP;

  AdcStreamP.Init <- MainC;
  Msp430Adc12SingleChannel = AdcStreamP.SingleChannel;
  AdcStreamP.Alarm -> Alarm;
}
