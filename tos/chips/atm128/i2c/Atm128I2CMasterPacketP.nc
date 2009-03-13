/*
 * Copyright (c) 2006 Stanford University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "Atm128I2C.h"

/**
 * This driver implements an interupt driven I2C Master controller 
 * Hardware Abstraction Layer (HAL) to the ATmega128 
 * two-wire-interface (TWI) hardware subsystem.
 *
 * @author Philip Levis
 *
 * @version $Id: Atm128I2CMasterPacketP.nc,v 1.8 2009-03-13 19:15:35 idgay Exp $
 */

generic module Atm128I2CMasterPacketP() {
  provides interface AsyncStdControl;
  provides interface I2CPacket<TI2CBasicAddr>;
  provides interface Atm128I2C;
  
  uses interface HplAtm128I2CBus as I2C;
  uses interface Leds as ReadDebugLeds;
  uses interface Leds as WriteDebugLeds;
}
implementation {

  enum {
    I2C_OFF          = 0,
    I2C_IDLE         = 1,
    I2C_BUSY         = 2,      
    I2C_ADDR         = 3,
    I2C_DATA         = 4,
    I2C_STARTING     = 5,
    I2C_STOPPING     = 6,
  } atm128_i2c_state_t;

  uint8_t state = I2C_OFF;
  i2c_flags_t packetFlags; 
  uint8_t* packetPtr;
  uint8_t packetLen;
  uint8_t index;
  uint16_t packetAddr;
  bool reading = FALSE;

  void i2c_abort(error_t err) {
    atomic {
      // Cycle the I2C
      call I2C.readCurrent();
      call I2C.enableInterrupt(FALSE);
      call I2C.enable(FALSE);
      call I2C.sendCommand();
      call I2C.readCurrent();
      call I2C.enable(TRUE);
      call I2C.sendCommand();
      state = I2C_IDLE;
      if (reading) {
	signal I2CPacket.readDone(err, packetAddr, packetLen, packetPtr);
      }
      else {
	signal I2CPacket.writeDone(err, packetAddr, packetLen, packetPtr);
      }
    }
  }
  
  async command error_t AsyncStdControl.start() {
    atomic {
      if (state == I2C_OFF) {
	call I2C.init(ATM128_I2C_EXTERNAL_PULLDOWN);
	call I2C.readCurrent();
	call I2C.enable(TRUE);
	call I2C.enableInterrupt(FALSE);
	call I2C.sendCommand();
	state = I2C_IDLE;
	return SUCCESS;
      }
      else {
	return FAIL;
      }
    }
  }

  async command error_t AsyncStdControl.stop() {
    atomic {
      if (state == I2C_IDLE) {
	call I2C.readCurrent();
	call I2C.enable(FALSE);
	call I2C.enableInterrupt(FALSE);
	call I2C.setInterruptPending(FALSE);
	call I2C.sendCommand();
	call I2C.off();
	state = I2C_OFF;
	return SUCCESS;
      }
      else {
	return FAIL;
      }
    }
  }

  async command error_t I2CPacket.read(i2c_flags_t flags, uint16_t addr, uint8_t len, uint8_t* data) {
    atomic {
      if (state == I2C_IDLE) {
	state = I2C_BUSY;
      }
      else if (state == I2C_OFF) {
	return EOFF;
      }
      else {
	return EBUSY;
      }
    }
    /* This follows the procedure described on page 209 of the atmega128L
     * data sheet. It is synchronous (does not handle interrupts).*/
    atomic {
      packetAddr = addr;
      packetPtr = data;
      packetLen = len;
      packetFlags = flags;
      index = 0;
      reading = TRUE;
    }
    /* Clear interrupt pending, send the I2C start command and abort
       if we're not in the start state.*/
    call I2C.readCurrent();
    atomic {
      call I2C.enableInterrupt(TRUE);
      call I2C.setInterruptPending(TRUE);
      call I2C.enableAck(FALSE);
      
      if (flags & I2C_START) {
        call I2C.setStart(TRUE);
        state = I2C_STARTING;
      }
      else if (len > 1 || (len > 0 && flags & I2C_ACK_END)) {
        call I2C.enableAck(TRUE);
        state = I2C_DATA;
      }
      else if (len == 1) { // length is 1
        state = I2C_DATA;
      }
      else if (flags & I2C_STOP) {
        state = I2C_STOPPING;
        call I2C.enableAck(FALSE);
        call I2C.setStop(TRUE);
      }
      call I2C.sendCommand();
    }
    return SUCCESS;
  }

  async command error_t I2CPacket.write(i2c_flags_t flags, uint16_t addr, uint8_t len, uint8_t* data) {
    atomic {
      if (state == I2C_IDLE) {
	state = I2C_BUSY;
      }
      else if (state == I2C_OFF) {
	return EOFF;
      }
      else {
	return EBUSY;
      }
    }
    /* This follows the procedure described on page 209 of the atmega128L
     * data sheet. It is synchronous (does not handle interrupts).*/
    atomic {
      packetAddr = addr;
      packetPtr = data;
      packetLen = len;
      packetFlags = flags;
      index = 0;
      reading = FALSE;
    }
    call I2C.readCurrent();
    atomic {
      call I2C.setInterruptPending(TRUE);
      call I2C.enableAck(TRUE);
      call I2C.enableInterrupt(TRUE);
      
      if (flags & I2C_START) {
        call I2C.setStart(TRUE);
	//	call WriteDebugLeds.led0On();
        state = I2C_STARTING;
      }
      else if (len > 0) {
        state = I2C_DATA;
	call I2C.write(data[index]);
      }
      else if (flags & I2C_STOP) {
        state = I2C_STOPPING;
        call I2C.enableAck(FALSE);
        call I2C.setStop(TRUE);
      }
      else { // A 0-length packet with no start and no stop....
	state = I2C_IDLE;
	return FAIL;
      }
      call I2C.sendCommand();
    }
    return SUCCESS;
  }
  
  /**
   * A command has been sent over the I2C.
   * The diversity of I2C options and modes means that there are a
   * plethora of cases to consider. To simplify reading the code,
   * they're described here and the corresponding statements
   * are only labelled with identifying comments.
   *
   * When reading:
   *  R1) A start condition has been requested. This requires 
   *      sending the start signal. When the interrupt comes in,
   *      send the first byte of the packet. This driver
   *      detects this condition by the START flag being set. 
   *      A successful send of the start clears the local copy of
   *      the flag. The driver does not distinguish between start
   *      and repeated start.
   *  R2) Sending the address byte with the read bit set.
   *  R3) Sending the first byte of a two-byte address with the
   *      read bit set. 
   *  R4) Sending the second byte of a two-byte address.
   *  R5) Reading any byte except the last byte of a packet.
   *  R6) Reading the last byte of the packet, with ACK_END requested.
   *  R7) Reading the last byte of the packet, with ACK_END cleared.
   *  R8) Sending a stop condition.
   */
  async event void I2C.commandComplete() {
    call I2C.readCurrent();
    atomic {
      if (state == I2C_DATA) {
	if (reading == TRUE) {
	  if (index < packetLen) {
	    packetPtr[index] = call I2C.read();
	    if (index == packetLen - 1 &&
                !(packetFlags & I2C_ACK_END)) { 
              call I2C.enableAck(FALSE);
            }
          }
	  else {
	    call I2C.enableInterrupt(FALSE);
	    if (packetFlags & I2C_STOP) {
	      packetFlags &= ~I2C_STOP;
	      call I2C.setStop(TRUE);
	      call I2C.status();
	    }
	    else {
	      call I2C.setInterruptPending(FALSE);
	    }
	    call I2C.sendCommand();
	    state = I2C_IDLE;
	    signal I2CPacket.readDone(SUCCESS, packetAddr, packetLen, packetPtr);
	    return;
	  }
	  index++;
	  call I2C.sendCommand();
	  return;
        }
        else { // Writing
	  if (index < packetLen) {
	    call I2C.write(packetPtr[index]);
	    index++;
	    call I2C.sendCommand();
	  }
	  else {
	    call I2C.enableInterrupt(FALSE);
	    if (packetFlags & I2C_STOP) {
	      packetFlags &= ~I2C_STOP;
	      call I2C.setStop(TRUE);
	      call WriteDebugLeds.led1On();
	    }
	    else {
	      call I2C.setInterruptPending(FALSE);
	    }
	    call I2C.sendCommand();
	    state = I2C_IDLE;
	    call WriteDebugLeds.led2On();
	    signal I2CPacket.writeDone(SUCCESS, packetAddr, packetLen, packetPtr);
	    return;
	  }
	}
      }
      else if (state == I2C_STARTING) {
	packetFlags &= ~I2C_START;
	call I2C.setStart(FALSE);
	if (call I2C.status() != ATM128_I2C_START &&
	    call I2C.status() != ATM128_I2C_RSTART) {
	  if (reading) {
	    //call ReadDebugLeds.set(call I2C.status() >> 4);
	  }
	  //call ReadDebugLeds.led2On();
	  i2c_abort(FAIL);
	  return;
	}
	state = I2C_ADDR;
	call I2C.enableAck(TRUE);
      }
      if (state == I2C_ADDR) {
	if (reading == TRUE) {
	  call I2C.write(((packetAddr & 0x7f) << 1) | ATM128_I2C_SLA_READ);
	}
	else
	  call I2C.write(((packetAddr & 0x7f) << 1) | ATM128_I2C_SLA_WRITE);
	state = I2C_DATA;
	call I2C.sendCommand();
      }
    }
  }

  async command void Atm128I2C.stop() {
    atomic {
      call I2C.readCurrent();
      call I2C.enableInterrupt(FALSE);
      call I2C.setStop(TRUE);
      call I2C.setInterruptPending(TRUE);
      call I2C.sendCommand();
    }
  }
}
