/* $Id: MagYC.nc,v 1.1 2007-03-14 05:38:37 pipeng Exp $
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

generic configuration MagYC()
{
  provides interface Mag;
  provides interface Read<uint16_t>;
}
implementation {
  enum {
    ID = unique(UQ_MAG_RESOURCE)
  };
  
  components MagReadP,MagConfigP, new AdcReadClientC() as AdcY;

  Mag = MagReadP;

  Read = MagReadP.MagY[ID];
  MagReadP.ActualY[ID] -> AdcY;
  AdcY.Atm128AdcConfig -> MagConfigP.ConfigY;
}

