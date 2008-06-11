/* $Id: MagXC.nc,v 1.2 2008-06-11 00:42:14 razvanm Exp $
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

generic configuration MagXC()
{
  provides interface Mag;
  provides interface Read<uint16_t>;
}
implementation {
  enum {
    ID = unique(UQ_MAG_RESOURCE)
  };
  
  components MagReadP,MagConfigP, new AdcReadClientC() as AdcX;

  Mag = MagReadP;

  Read = MagReadP.MagX[ID];
  MagReadP.ActualX[ID] -> AdcX;
  AdcX.Atm128AdcConfig -> MagConfigP.ConfigX;
}

