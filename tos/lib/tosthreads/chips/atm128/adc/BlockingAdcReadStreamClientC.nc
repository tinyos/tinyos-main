/* $Id: BlockingAdcReadStreamClientC.nc,v 1.1 2008-06-13 19:33:39 klueska Exp $
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
 * the Atmega128 ADC.  Users of this component must link it to an
 * implementation of Atm128AdcConfig which provides the ADC parameters
 * (channel, etc).
 * 
 * @author David Gay
 * @author Kevin Klues <klueska@cs.stanford.edu>
 */

#include "Adc.h"

generic configuration BlockingAdcReadStreamClientC() {
  provides interface BlockingReadStream<uint16_t>;
  uses {
    interface Atm128AdcConfig;
    interface ResourceConfigure;
  }
}
implementation {
  components BlockingAdcP, Atm128AdcC;

  enum {
    ID = unique(UQ_ADC_READSTREAM),
    HAL_ID = unique(UQ_ATM128ADC_RESOURCE)
  };

  BlockingReadStream = BlockingAdcP.BlockingReadStream[ID];
  Atm128AdcConfig = BlockingAdcP.ConfigReadStream[ID];
  BlockingAdcP.ReadStreamResource[ID] -> Atm128AdcC.Resource[HAL_ID];
  ResourceConfigure = Atm128AdcC.ResourceConfigure[HAL_ID];
}
