// $Id: BlockStorageC.nc,v 1.3 2006-11-07 19:30:43 scipio Exp $
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
 * Implementation of the block storage abstraction from TEP103 for the
 * Atmel AT45DB serial data flash.
 *
 * @param volid Volume to use for block storage
 *
 * @author David Gay
 */

#include "Storage.h"

generic configuration BlockStorageC(volume_id_t volid) {
  provides {
    interface BlockWrite;
    interface BlockRead;
  }
}
implementation {
  enum {
    BLOCK_ID = unique(UQ_BLOCK_STORAGE) + uniqueCount(UQ_CONFIG_STORAGE),
    RESOURCE_ID = unique(UQ_AT45DB)
  };
    
  components BlockStorageP, WireBlockStorageP, At45dbStorageManagerC, At45dbC;

  BlockWrite = BlockStorageP.BlockWrite[BLOCK_ID];
  BlockRead = BlockStorageP.BlockRead[BLOCK_ID];

  BlockStorageP.At45dbVolume[BLOCK_ID] -> At45dbStorageManagerC.At45dbVolume[volid];
  BlockStorageP.Resource[BLOCK_ID] -> At45dbC.Resource[RESOURCE_ID];
}
