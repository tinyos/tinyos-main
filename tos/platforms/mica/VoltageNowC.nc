/* $Id: VoltageNowC.nc,v 1.1 2007-05-22 20:59:01 idgay Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Voltage sensor.
 * 
 * @author David Gay
 */

#include "hardware.h"

generic configuration VoltageNowC() {
  provides interface Resource;
  provides interface ReadNow<uint16_t>;
}
implementation {
  components new AdcReadNowClientC(), VoltageP;

  ReadNow = AdcReadNowClientC;
  Resource = AdcReadNowClientC;
  AdcReadNowClientC.Atm128AdcConfig -> VoltageP;
}
