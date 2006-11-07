/* $Id: DemoSensorC.nc,v 1.3 2006-11-07 19:31:26 scipio Exp $
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
generic module DemoSensorC()
{
  provides interface Read<uint16_t>;
  provides interface ReadStream<uint16_t>;
}
implementation
{
  command error_t Read.read() {
    return SUCCESS;
  }

  command error_t ReadStream.postBuffer(uint16_t *buf, uint16_t count) {
    return SUCCESS;
  }

   command error_t ReadStream.read(uint32_t usPeriod) {
     return SUCCESS;
  }
}

