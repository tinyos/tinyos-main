/// $Id: HplAtm128I2CBus.nc,v 1.5 2010-06-29 22:07:43 scipio Exp $

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

#include "Atm128I2C.h"

/**
 * This driver implements direct I2C register access and a blocking master
 * controller for the ATmega128 via a Hardware Platform Layer (HPL) to its  
 * two-wire-interface (TWI) hardware subsystem.
 *
 * @author Martin Turon <mturon@xbow.com>
 * @author Philip Levis
 *
 * @version  $Id: HplAtm128I2CBus.nc,v 1.5 2010-06-29 22:07:43 scipio Exp $
 */
interface HplAtm128I2CBus {

  async command void init(bool hasExternalPulldown);
  async command void off();
  
  async command uint8_t status();

  async command void readCurrent();
  async command void sendCommand();
  async event void commandComplete();

  
  // Transaction interface
  async command void setStart(bool on);
  async command bool hasStart();
  async command void setStop(bool on);   
  async command bool hasStop();
  async command void enableAck(bool enable);
  async command bool hasAcks();
  
  async command void enableInterrupt(bool enable);
  async command bool isInterruptEnabled();

  // Examines actual register. Included so that code which needs
  // to spin in TWINT does not have to read out cached copies.
  async command bool isRealInterruptPending();

  // Operates on cached copy (from readCurrent)
  async command bool isInterruptPending(); 
  
  // NOTE: writing a 1 in the interrupt pending bit (TWINT) of the
  // atm128 I2C control register (TWCR) will *clear* the bit if it
  // is set. This is how you tell the I2C to take the next action,
  // as when the bit is cleared it starts the next operation.
  async command void setInterruptPending(bool on);

  async command void enable(bool on);
  async command bool isEnabled();
  async command bool hasWriteCollided();
  
  // Data interface to TWDR
  async command void write(uint8_t data);
  async command uint8_t read();
  
  

}
