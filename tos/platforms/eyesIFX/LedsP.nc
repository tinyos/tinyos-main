// $Id: LedsP.nc,v 1.6 2010-06-29 22:07:53 scipio Exp $

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
 * The implementation of the standard LED mote abstraction.
 *
 * @author Joe Polastre
 * @author Philip Levis
 * @date   March 21, 2005
 */

module LedsP {
  provides {
    interface Init;
    interface Leds;
  }
  uses {
    interface GeneralIO as Led0;
    interface GeneralIO as Led1;
    interface GeneralIO as Led2;
  }
}
implementation {
  
#ifndef dbg
#define dbg(n,msg)
#endif  

  command error_t Init.init() {
    atomic {
      dbg(DBG_BOOT, "LEDS: initialized.\n");
      call Led0.makeOutput();
      call Led1.makeOutput();
      call Led2.makeOutput();
      call Led0.clr();
      call Led1.clr();
      call Led2.clr();
    }
    return SUCCESS;
  }

  async command void Leds.led0On() {
    dbg(DBG_LED, "LEDS: Led 0 on.\n");
    call Led0.set();
  }

  async command void Leds.led0Off() {
    dbg(DBG_LED, "LEDS: Led 0 off.\n");
    call Led0.clr();
  }

  async command void Leds.led0Toggle() {
    call Led0.toggle();
    // this should be removed by dead code elimination when compiled for
    // the physical motes
    if (call Led0.get())
      dbg(DBG_LED, "LEDS: Led 0 off.\n");
    else
      dbg(DBG_LED, "LEDS: Led 0 on.\n");
  }

  async command void Leds.led1On() {
    dbg(DBG_LED, "LEDS: Led 1 on.\n");
    call Led1.set();
  }

  async command void Leds.led1Off() {
    dbg(DBG_LED, "LEDS: Led 1 off.\n");
    call Led1.clr();
  }

  async command void Leds.led1Toggle() {
    call Led1.toggle();
    if (call Led1.get())
      dbg(DBG_LED, "LEDS: Led 1 off.\n");
    else
      dbg(DBG_LED, "LEDS: Led 1 on.\n");
  }

  async command void Leds.led2On() {
    dbg(DBG_LED, "LEDS: Led 2 on.\n");
    call Led2.set();
  }

  async command void Leds.led2Off() {
    dbg(DBG_LED, "LEDS: Led 2 off.\n");
    call Led2.clr();
  }

  async command void Leds.led2Toggle() {
    call Led2.toggle();
    if (call Led2.get())
      dbg(DBG_LED, "LEDS: Led 2 off.\n");
    else
      dbg(DBG_LED, "LEDS: Led 2 on.\n");
  }

  async command uint8_t Leds.get() {
    uint8_t rval;
    atomic {
      rval = 0;
      if (call Led0.get()) {
        rval |= LEDS_LED0;
      }
      if (call Led1.get()) {
        rval |= LEDS_LED1;
      }
      if (call Led2.get()) {
        rval |= LEDS_LED2;
      }
    return rval;
  }
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
    }
  }
}
