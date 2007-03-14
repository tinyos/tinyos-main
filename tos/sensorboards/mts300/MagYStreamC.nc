/* $Id: MagYStreamC.nc,v 1.1 2007-03-14 05:38:37 pipeng Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * @author Alif Chen
 */

#include "mts300.h"

generic configuration MagYStreamC() {
  provides interface ReadStream<uint16_t>;
  provides interface Mag;
}
implementation {
  enum {
    ID = unique(UQ_ACCEL_RESOURCE)
  };
  components MagReadStreamP, MagConfigP, new AdcReadStreamClientC();

  Mag = MagReadStreamP;

  ReadStream = MagReadStreamP.ReadStreamY[ID];
  MagReadStreamP.ActualY[ID] -> AdcReadStreamClientC;
  AdcReadStreamClientC.Atm128AdcConfig -> MagConfigP.ConfigY;
}
