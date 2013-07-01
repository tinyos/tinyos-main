// $Id: LedsP.nc,v 1.2 2010-11-18 21:57:02 andrasbiro Exp $

/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * - Neither the name of the University of California nor the names of
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

/**
 * The implementation of the standard 3 LED mote abstraction.
 *
 * @author Joe Polastre
 * @author Philip Levis
 *
 * @date   March 21, 2005
 */

module LedsP @safe() {
  provides {
    interface Init;
    interface Leds;
  }
  uses {
    interface GeneralIO as Led0;
    interface GeneralIO as Led1;
    interface GeneralIO as Led2;
    interface GeneralIO as Led3;
  }
}
implementation {
  command error_t Init.init() {
    atomic {
      dbg("Init", "LEDS: initialized.\n");
      
      call Led0.makeOutput();
      call Led1.makeOutput();
      call Led2.makeOutput();
      call Led3.makeOutput();
      call Led0.set();
      call Led1.set();
      call Led2.set();
      call Led3.set();
    }
    return SUCCESS;
  }

  /* Note: the call is inside the dbg, as it's typically a read of a volatile
     location, so can't be deadcode eliminated */
#define DBGLED(n) \
  dbg("LedsC", "LEDS: Led" #n " %s.\n", call Led ## n .get() ? "off" : "on");

  async command void Leds.led0On() {
    call Led0.clr();
    DBGLED(0);
  }

  async command void Leds.led0Off() {
    call Led0.set();
    DBGLED(0);
  }

  async command void Leds.led0Toggle() {
    call Led0.toggle();
    DBGLED(0);
  }

  async command void Leds.led1On() {
    call Led1.clr();
    DBGLED(1);
  }

  async command void Leds.led1Off() {
    call Led1.set();
    DBGLED(1);
  }

  async command void Leds.led1Toggle() {
    call Led1.toggle();
    DBGLED(1);
  }

  async command void Leds.led2On() {
    call Led2.clr();
    DBGLED(2);
  }

  async command void Leds.led2Off() {
    call Led2.set();
    DBGLED(2);
  }

  async command void Leds.led2Toggle() {
    call Led2.toggle();
    DBGLED(2);
  }

  async command void Leds.led3On() {
    call Led3.clr();
    DBGLED(2);
  }

  async command void Leds.led3Off() {
    call Led3.set();
    DBGLED(3);
  }

  async command void Leds.led3Toggle() {
    call Led3.toggle();
    DBGLED(3);
  }

  async command void Leds.led4On() {
  }

  async command void Leds.led4Off() {
  }

  async command void Leds.led4Toggle() {
  }

  async command uint8_t Leds.get() {
    uint8_t rval;
    atomic {
      rval = 0;
      if (! call Led0.get()) {
	rval |= LEDS_LED0;
      }
      if (! call Led1.get()) {
	rval |= LEDS_LED1;
      }
      if (! call Led2.get()) {
	rval |= LEDS_LED2;
      }
      if (! call Led3.get()) {
	rval |= LEDS_LED3;
      }
    }
    return rval;
  }

  async command void Leds.set(uint8_t val) {
    atomic {
      if (val & LEDS_LED0) {
	call Leds.led0On();
      }
      else {
	call Leds.led0Off();
      }
      if (val & LEDS_LED1) {
	call Leds.led1On();
      }
      else {
	call Leds.led1Off();
      }
      if (val & LEDS_LED2) {
	call Leds.led2On();
      }
      else {
	call Leds.led2Off();
      }
      if (val & LEDS_LED3) {
	call Leds.led3On();
      }
      else {
	call Leds.led3Off();
      }

    }
  }
}
