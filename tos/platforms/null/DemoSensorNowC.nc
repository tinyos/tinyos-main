/* $Id: DemoSensorNowC.nc,v 1.4 2006-12-12 18:23:44 vlahan Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Null platform demo sensor code.
 *
 * @author David Gay
 */
generic module DemoSensorNowC()
{
  provides interface Resource;
  provides interface ReadNow<uint16_t>;
}
implementation
{
  async command error_t Resource.request() {
    return SUCCESS;
  }

  async command error_t Resource.immediateRequest() {
    return SUCCESS;
  }

  async command error_t Resource.release() {
    return SUCCESS;
  }

  async command bool Resource.isOwner() {
    return TRUE;
  }

  async command error_t ReadNow.read() {
    return SUCCESS;
  }
}

