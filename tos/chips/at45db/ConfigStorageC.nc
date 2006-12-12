// $Id: ConfigStorageC.nc,v 1.4 2006-12-12 18:23:02 vlahan Exp $
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
 * Implementation of the config storage abstraction from TEP103 for the
 * Atmel AT45DB serial data flash.
 *
 * @param volid Volume to use for config storage
 *
 * @author David Gay
 */

#include "Storage.h"

generic configuration ConfigStorageC(volume_id_t volid) {
  provides {
    interface Mount;
    interface ConfigStorage;
  }
}
implementation {
  enum {
    CONFIG_ID = unique(UQ_CONFIG_STORAGE),
    RESOURCE_ID = unique(UQ_AT45DB)
  };
    
  components ConfigStorageP, WireConfigStorageP, At45dbStorageManagerC, At45dbC;
  components BlockStorageP, WireBlockStorageP;

  Mount = ConfigStorageP.Mount[CONFIG_ID];
  ConfigStorage = ConfigStorageP.ConfigStorage[CONFIG_ID];

  BlockStorageP.At45dbVolume[CONFIG_ID] -> At45dbStorageManagerC.At45dbVolume[volid];
  BlockStorageP.Resource[CONFIG_ID] -> At45dbC.Resource[RESOURCE_ID];
}
