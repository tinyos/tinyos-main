// $Id: PlatformSerialC.nc,v 1.5 2007-05-23 22:17:49 idgay Exp $
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

module PlatformSerialC {
  provides interface StdControl;
  provides interface UartByte;
  provides interface UartStream;
}
implementation {
  command error_t StdControl.start() {
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    return SUCCESS;
  }

  async command error_t UartByte.send( uint8_t byte ) {
    return SUCCESS;
  }

  async command bool UartByte.sendAvail() {
    return FALSE;
  }

  async command error_t UartByte.receive( uint8_t* byte, uint8_t timeout ) {
    return SUCCESS;
  }

  async command bool UartByte.receiveAvail() {
    return FALSE;
  }

  async command error_t UartStream.send( uint8_t* buf, uint16_t len ) {
    return SUCCESS;
  }

  async command error_t UartStream.enableReceiveInterrupt() {
    return SUCCESS;
  }

  async command error_t UartStream.disableReceiveInterrupt() {
    return SUCCESS;
  }

  async command error_t UartStream.receive( uint8_t* buf, uint16_t len ) {
    return SUCCESS;
  }
}
