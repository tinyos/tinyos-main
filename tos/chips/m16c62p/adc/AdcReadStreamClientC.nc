/* $Id: AdcReadStreamClientC.nc,v 1.1 2009-09-07 14:12:25 r-studio Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Provide, as per TEP101, arbitrated access via a ReadStream interface to
 * the M16c62p ADC.  Users of this component must link it to an
 * implementation of M16c62pAdcConfig which provides the ADC parameters
 * (channel, etc).
 * 
 * @author Fan Zhang <fanzha@ltu.se>
 */

#include "Adc.h"

generic configuration AdcReadStreamClientC() {
  provides interface ReadStream<uint16_t>;
  uses {
    interface M16c62pAdcConfig;
    interface ResourceConfigure;
  }
}
implementation {
  components WireAdcStreamP, M16c62pAdcC;

  enum {
    ID = unique(UQ_ADC_READSTREAM),
    HAL_ID = unique(UQ_M16c62pADC_RESOURCE)
  };

  ReadStream = WireAdcStreamP.ReadStream[ID];
  M16c62pAdcConfig = WireAdcStreamP.M16c62pAdcConfig[ID];
  WireAdcStreamP.Resource[ID] -> M16c62pAdcC.Resource[HAL_ID];
  ResourceConfigure = M16c62pAdcC.ResourceConfigure[HAL_ID];
}
