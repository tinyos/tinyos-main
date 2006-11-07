/* $Id: NoInitC.nc,v 1.3 2006-11-07 19:31:28 scipio Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * A do-nothing Init implementation. Useful for implementing components whose
 * specification has an Init, but whose implementation doesn't need one.
 *
 * @author David Gay <david.e.gay@intel.com>
 */
module NoInitC 
{
  provides interface Init;
}
implementation
{
  command error_t Init.init() {
    return SUCCESS;
  }
}
