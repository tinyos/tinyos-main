/// $Id: HplAtm128I2CBusP.nc,v 1.5 2010-06-29 22:07:43 scipio Exp $

/*
 *  Copyright (c) 2004-2005 Crossbow Technology, Inc.
 *  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#define F_CPU       7372800

#include "Atm128I2C.h"

/**
 * This driver implements direct I2C register access and a blocking master
 * controller for the ATmega128 via a Hardware Platform Layer (HPL) to its  
 * two-wire-interface (TWI) hardware subsystem.
 *
 * @author Martin Turon <mturon@xbow.com>
 * @author Philip Levis
 *
 * @version $Id: HplAtm128I2CBusP.nc,v 1.5 2010-06-29 22:07:43 scipio Exp $
 */
module HplAtm128I2CBusP {
  provides interface HplAtm128I2CBus as I2C;

  uses {
    interface GeneralIO as I2CClk;
    interface GeneralIO as I2CData;
  }
}
implementation {
  uint8_t current;
  
  async command void I2C.init(bool hasExternalPulldown) {
    // Set the internal pullup resisters
    if (hasExternalPulldown) {
      //call I2CClk.makeOutput();
      //call I2CData.makeOutput();
      call I2CClk.set();
      call I2CData.set();
    }
    call I2CClk.makeInput();
    call I2CData.makeInput();
    TWSR = 0;                             // set prescaler == 0
    TWBR = (F_CPU / 50000UL - 16) / 2;   // set I2C baud rate
    //TWBR = 50;
    TWAR = 0;
    TWCR = 0;
  }

  async command void I2C.off() {
    call I2CClk.clr();
    call I2CData.clr();
  }
  
  async command uint8_t I2C.status() {
    return TWSR & 0xf8;
  }

  async command void I2C.sendCommand() {
    atomic TWCR = current;
  }

  async command void I2C.readCurrent() {
    atomic current = TWCR;
  }
  
  /** Send START symbol and begin I2C bus transaction. */
  async command void I2C.setStart(bool on) {
    if (on) {
      atomic SET_BIT(current, TWSTA);
    }
    else {
      atomic CLR_BIT(current, TWSTA);
    }
  }
  async command bool I2C.hasStart() {
    return READ_BIT(current, TWSTA);
  }

  async command void I2C.setStop(bool on) {
    if (on) {
      atomic SET_BIT(current, TWSTO);
    }
    else {
      atomic CLR_BIT(current, TWSTO);
    }
  }
  async command bool I2C.hasStop() {
    return READ_BIT(current, TWSTO);
  }
  
  /** Write a byte to an I2C slave device. */
  async command void I2C.write(uint8_t data) {
    TWDR = data;
  }

  async command uint8_t I2C.read() {
    return TWDR;
  }

  async command void I2C.enableAck(bool enable) {
    if (enable) {
      atomic SET_BIT(current, TWEA);
    }
    else {
      atomic CLR_BIT(current, TWEA);
    }
  }
  
  async command bool I2C.hasAcks() {
    return READ_BIT(current, TWEA);
  }
  
  async command void I2C.enableInterrupt(bool enable) {
    if (enable) {
      atomic SET_BIT(current, TWIE);
    }
    else {
      atomic CLR_BIT(current, TWIE);
    }
  }

  async command bool I2C.isInterruptEnabled() {
    return READ_BIT(current, TWIE);
  }
  
  async command bool I2C.isRealInterruptPending() {
    return READ_BIT(TWCR, TWINT);
  }

  async command bool I2C.isInterruptPending() {
    return READ_BIT(current, TWINT);
  }

  async command void I2C.setInterruptPending(bool on) {
    if (on) {
      atomic SET_BIT(current, TWINT);
    }
    else {
      atomic CLR_BIT(current, TWINT);
    }
  }
  
  async command void I2C.enable(bool enable) {
    if (enable) {
      atomic SET_BIT(current, TWEN);
    }
    else {
      atomic CLR_BIT(current, TWEN);
    }
  }

  async command bool I2C.isEnabled() {
    return READ_BIT(current, TWEN);
  }

  async command bool I2C.hasWriteCollided() {
    return READ_BIT(current, TWWC);
  }

  default async event void I2C.commandComplete() { }
  AVR_ATOMIC_HANDLER(SIG_2WIRE_SERIAL) {
    signal I2C.commandComplete();
  }
}
