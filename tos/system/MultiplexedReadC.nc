/* $Id: MultiplexedReadC.nc,v 1.1 2007-02-08 17:49:05 idgay Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Multiplex access to a single Read interface for a parameterised
 * Read interface whose access is controlled by an arbiter.
 *
 * @param width_t Width of the underlying Read interface.
 *
 * @author David Gay
 */
generic module MultiplexedReadC(typedef width_t) {
  provides interface Read<width_t>[uint8_t client];
  uses {
    interface Read<width_t> as Service;
    interface Resource[uint8_t client];
    interface ArbiterInfo;
  }
}
implementation {
  command error_t Read.read[uint8_t client]() {
    return call Resource.request[client]();
  }

  event void Resource.granted[uint8_t client]() {
    call Service.read();
  }

  event void Service.readDone(error_t result, width_t data) {
    uint8_t client = call ArbiterInfo.userId();

    call Resource.release[client]();
    signal Read.readDone[client](result, data);
  }

  default async command error_t Resource.request[uint8_t client]() { 
    return FAIL; 
  }
  default async command error_t Resource.release[uint8_t client]() { return FAIL; }
  default event void Read.readDone[uint8_t client](error_t result, width_t data) { }
}
