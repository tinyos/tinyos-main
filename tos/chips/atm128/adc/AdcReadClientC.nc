/* $Id: AdcReadClientC.nc,v 1.4 2006-12-12 18:23:03 vlahan Exp $
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
 * Atmega128 ADC.  Users of this component must link it to an
 * implementation of Atm128AdcConfig which provides the ADC parameters
 * (channel, etc).
 * 
 * @author David Gay
 */

#include "Adc.h"

generic configuration AdcReadClientC() {
  provides interface Read<uint16_t>;
  uses {
    interface Atm128AdcConfig;
    interface ResourceConfigure;
  }
}
implementation {
  components WireAdcP, Atm128AdcC;

  enum {
    ID = unique(UQ_ADC_READ),
    HAL_ID = unique(UQ_ATM128ADC_RESOURCE)
  };

  Read = WireAdcP.Read[ID];
  Atm128AdcConfig = WireAdcP.Atm128AdcConfig[ID];
  WireAdcP.Resource[ID] -> Atm128AdcC.Resource[HAL_ID];
  ResourceConfigure = Atm128AdcC.ResourceConfigure[HAL_ID];
}
