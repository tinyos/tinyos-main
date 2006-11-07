// $Id: HALAT45DBC.nc,v 1.1 2005/01/22 00:26:31 idgay Exp 
/*									tab:4
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * HAL for Atmel's AT45DB family of serial dataflash chips. Access to the HAL
 * is controlled by a parameterised Resource interface - client ids are 
 * obtained with unique(UQ_AT45DB).
 *
 * @author David Gay
 */

#include "At45db.h"

configuration At45dbC
{
  provides {
    interface At45db;
    interface Resource[uint8_t client];
    interface ResourceController;
    interface ArbiterInfo;
  }
}
implementation
{
  components At45dbP, HplAt45dbC, MainC, BusyWaitMicroC;
  components new FcfsArbiterC(UQ_AT45DB) as Arbiter;

  At45db = At45dbP;
  Resource = Arbiter;
  ResourceController = Arbiter;
  ArbiterInfo = Arbiter;

  MainC.SoftwareInit -> At45dbP;
  At45dbP.HplAt45db -> HplAt45dbC;
  At45dbP.BusyWait -> BusyWaitMicroC;
}
