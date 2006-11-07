// $Id: LogStorageC.nc,v 1.3 2006-11-07 19:30:43 scipio Exp $
/*
 * Copyright (c) 2005-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Implementation of the log storage abstraction from TEP103 for the
 * Atmel AT45DB serial data flash.
 *
 * @param volid Volume to use for log storage
 * @param circular TRUE if you want a circular log, FALSE for a linear log
 *
 * @author David Gay
 */

#include "Storage.h"

generic configuration LogStorageC(volume_id_t volid, bool circular) {
  provides {
    interface LogWrite;
    interface LogRead;
  }
}
implementation {
  enum {
    LOG_ID = unique(UQ_LOG_STORAGE),
    INTF_ID = LOG_ID << 1 | circular,
    RESOURCE_ID = unique(UQ_AT45DB)
  };
    
  components LogStorageP, WireLogStorageP, At45dbStorageManagerC, At45dbC;

  LogWrite = LogStorageP.LogWrite[INTF_ID];
  LogRead = LogStorageP.LogRead[INTF_ID];

  LogStorageP.At45dbVolume[LOG_ID] -> At45dbStorageManagerC.At45dbVolume[volid];
  LogStorageP.Resource[LOG_ID] -> At45dbC.Resource[RESOURCE_ID];
}
