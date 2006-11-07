// $Id: BlockStorageC.nc,v 1.3 2006-11-07 19:31:26 scipio Exp $
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
 * Dummy implementation to support the null platform.
 */

#include "Storage.h"

generic module BlockStorageC(volume_id_t volid) {
  provides {
    interface BlockWrite;
    interface BlockRead;
  }
}
implementation {
  command error_t BlockWrite.write( storage_addr_t addr, void* buf, uint16_t len ) {
    return SUCCESS;
  }

  command error_t BlockWrite.erase() {
    return SUCCESS;
  }

  command error_t BlockWrite.commit() {
    return SUCCESS;
  }

  command error_t BlockRead.read( storage_addr_t addr, void* buf, uint16_t len ) {
    return SUCCESS;
  }

  command error_t BlockRead.verify() {
    return SUCCESS;
  }

  command error_t BlockRead.computeCrc( storage_addr_t addr, storage_len_t len ) {
    return SUCCESS;
  }
}
