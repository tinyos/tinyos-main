/* $Id: ArbitratedReadC.nc,v 1.5 2006-12-12 18:23:47 vlahan Exp $
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
generic module ArbitratedReadC(typedef width_t) {
  provides interface Read<width_t>[uint8_t client];
  uses {
    interface Read<width_t> as Service[uint8_t client];
    interface Resource[uint8_t client];
  }
}
implementation {
  command error_t Read.read[uint8_t client]() {
    return call Resource.request[client]();
  }

  event void Resource.granted[uint8_t client]() {
    call Service.read[client]();
  }

  event void Service.readDone[uint8_t client](error_t result, width_t data) {
    call Resource.release[client]();
    signal Read.readDone[client](result, data);
  }

  default async command error_t Resource.request[uint8_t client]() { 
    return FAIL; 
  }
  default async command error_t Resource.release[uint8_t client]() { return FAIL; }
  default event void Read.readDone[uint8_t client](error_t result, width_t data) { }
  default command error_t Service.read[uint8_t client]() {
    return SUCCESS;
  }
}
