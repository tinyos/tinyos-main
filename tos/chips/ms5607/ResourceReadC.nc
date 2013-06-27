/* $Id: ArbitratedReadC.nc,v 1.6 2008-06-26 04:39:14 regehr Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Implement arbitrated access to a Read interface, based on an
 * underlying arbitrated Resource interface.
 *
 * Note that this code does not deal with unexpected events: it assumes
 * that all events it receives are in response to commands that it
 * made. See tos/chips/atm128/adc for an example of using ArbitratedReadC 
 * in a safe way.
 *
 * @param width_t Width of the underlying Read interface.
 *
 * @author David Gay
 */

generic module ResourceReadC(typedef width_t) @safe() {
  provides interface Read<width_t>;
  uses {
    interface Read<width_t> as Service;
    interface Resource;
  }
}
implementation {
  command error_t Read.read() {
    return call Resource.request();
  }

  event void Resource.granted() {
    call Service.read();
  }

  event void Service.readDone(error_t result, width_t data) {
    call Resource.release();
    signal Read.readDone(result, data);
  }

  default async command error_t Resource.request() { 
    return FAIL; 
  }
  default async command error_t Resource.release() { return FAIL; }
  default event void Read.readDone(error_t result, width_t data) { }
  default command error_t Service.read() {
    return SUCCESS;
  }
}

