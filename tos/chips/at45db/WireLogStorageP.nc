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
 * Private component of the AT45DB implementation of the log storage
 * abstraction.
 *
 * @author: David Gay <dgay@acm.org>
 */

configuration WireLogStorageP { }
implementation {
  components LogStorageP, At45dbC;

  LogStorageP.At45db -> At45dbC;
}
