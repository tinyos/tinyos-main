/* $Id: AdcReadClientC.nc,v 1.1 2009-09-07 14:12:25 r-studio Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Provide, as per TEP101, arbitrated access via a Read interface to the
 * M16c60 ADC.  Users of this component must link it to an
 * implementation of M16c60AdcConfig which provides the ADC parameters
 * (channel, etc).
 * 
 * @author Fan Zhang <fanzha@ltu.se>
 */

#include "Adc.h"

generic configuration AdcReadClientC() {
  provides interface Read<uint16_t>;
  uses {
    interface M16c60AdcConfig;
    interface ResourceConfigure;
  }
}
implementation {
  components WireAdcP, M16c60AdcC;

  enum {
    ID = unique(UQ_ADC_READ),
    HAL_ID = unique(UQ_M16c60ADC_RESOURCE)
  };

  Read = WireAdcP.Read[ID];
  M16c60AdcConfig = WireAdcP.M16c60AdcConfig[ID];
  WireAdcP.Resource[ID] -> M16c60AdcC.Resource[HAL_ID];
  ResourceConfigure = M16c60AdcC.ResourceConfigure[HAL_ID];
}
