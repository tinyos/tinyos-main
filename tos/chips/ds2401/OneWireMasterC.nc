// $Id: OneWireMasterC.nc,v 1.2 2010-06-29 22:07:45 scipio Exp $
/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
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
 *
 * Author: Janos Sallai
 */

/**
 * This module is the implementation of an 1-wire bus master.
 *
 */
module OneWireMasterC {
  uses interface GeneralIO as Pin;
  uses interface BusyWait<TMicro, uint16_t> as BusyWaitMicro;
  provides interface OneWireMaster as OneWire;

}
implementation {

  async command void OneWire.idle() {
    call Pin.makeInput();
    call Pin.set(); // start sourcing current
  }

  async command void OneWire.init() {
    call OneWire.idle();
    call BusyWaitMicro.wait(500); // wait at least 500us after bootup
  }

  async command void OneWire.release() {
    call Pin.makeInput();
    call Pin.clr(); // stop sourcing current
  }

  async command error_t OneWire.reset() {
    bool clientPresent;

    // it is assumed that the bus is in idle state here

    // transmit reset pulse
    call Pin.makeOutput(); // output low
    call Pin.clr();
    call BusyWaitMicro.wait(500); // must be at least 480us
    call OneWire.idle(); // input with pullup set

    // test for present pulse
    call BusyWaitMicro.wait(80); // presence pulse is sent 18-60us after reset
    clientPresent = call Pin.get(); // test for presence pulse
    call BusyWaitMicro.wait(400); // presence pulse is 60-240us long

    if (clientPresent == 0) {
      return SUCCESS;
    } else {
      return EOFF;
    }
  }

  async command void OneWire.writeOne() {
    call Pin.makeOutput(); // output low
    call Pin.clr();
    call BusyWaitMicro.wait(8); // must be 1-15us
    call OneWire.idle(); // input with pullup set
    call BusyWaitMicro.wait(72); // low time plus idle time must 60-120us
  }

  async command void OneWire.writeZero() {
    call Pin.makeOutput(); // output low
    call Pin.clr();
    call BusyWaitMicro.wait(72); // must be 60-120us
    call OneWire.idle(); // input with pullup set
    call BusyWaitMicro.wait(8); // low time plus idle time must 60-120us
  }

  async command void OneWire.writeByte(uint8_t b) {
    uint8_t i;

    // send out bits, LSB first
    for(i=0;i<8;i++) {
      if(b & 0x01) {
        call OneWire.writeOne();
      } else {
        call OneWire.writeZero();
      }
      b >>= 1;
    }
  }

  async command bool OneWire.readBit() {
    bool b;
    call Pin.makeOutput(); // output low
    call Pin.clr();
    call BusyWaitMicro.wait(1);
    call OneWire.idle(); // input with pullup set
    call BusyWaitMicro.wait(8); // must be 1-15us
    b = call Pin.get(); // read pin
    call BusyWaitMicro.wait(71); // timeslot length must be 60-120us
    return b;
  }

  async command uint8_t OneWire.readByte() {
    uint8_t i,b=0;

    // read bits, LSB first
    for(i=0;i<8;i++) {
      b >>= 1;
      b |= call OneWire.readBit() << 7;
    }
    return b;
  }

}
