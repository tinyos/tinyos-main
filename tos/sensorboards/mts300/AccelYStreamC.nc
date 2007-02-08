/* $Id: AccelYStreamC.nc,v 1.1 2007-02-08 17:55:35 idgay Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * AccelXdiode of the basicsb sensor board.
 * 
 * @author David Gay
 */

#include "mts300.h"

generic configuration AccelYStreamC() {
  provides interface ReadStream<uint16_t>;
}
implementation {
  enum {
    ID = unique(UQ_ACCEL_RESOURCE)
  };
  components AccelReadStreamP, AccelConfigP, new AdcReadStreamClientC();

  ReadStream = AccelReadStreamP.ReadStreamY[ID];
  AccelReadStreamP.ActualY[ID] -> AdcReadStreamClientC;
  AdcReadStreamClientC.Atm128AdcConfig -> AccelConfigP.ConfigY;
}
