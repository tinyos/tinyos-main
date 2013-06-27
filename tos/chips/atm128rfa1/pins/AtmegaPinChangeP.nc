/*
 * Copyright (c) 2011, University of Szeged
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
 * Author: Andras Biro, Miklos Maroti
 */

/*
 * This module provides emulated edge triggered GpioInterrupt using a
 * shared pin change interrupt. Note, that this emulation cannot be
 * perfect, as if one is wating for a rising edge and gets an ON quickly
 * followed by a OFF signal, then the fired event will miss this and
 * will not report anything. This emulation works only for external
 * components that hold their interrupt line long enough (e.g. they
 * need to be manually cleared via SPI or I2C).
 *
 * Also note, that the actual filtering logic is done in the fired
 * event and we cannot rule out spontaneous interrupts (e.g. by a
 * pin change interrupt in an uninteresting direction), therefore we
 * do no clear the interrupt flag when enabling the pin change
 * interrupt and save on code size.
 */
generic module AtmegaPinChangeP(){
  uses interface HplAtmegaPinChange;
  provides interface GpioInterrupt[uint8_t pin];
}
implementation{
  uint8_t isFalling;

  /* Enables the interrupt */
  async command error_t GpioInterrupt.enableRisingEdge[uint8_t pin](){
    atomic{
      isFalling &= ~(1<<pin);
      call HplAtmegaPinChange.setMask(call HplAtmegaPinChange.getMask() | (1<<pin));
      call HplAtmegaPinChange.enable();
    }
    return SUCCESS;
  }

  async command error_t GpioInterrupt.enableFallingEdge[uint8_t pin](){
    atomic {
      isFalling |= 1<<pin;
      call HplAtmegaPinChange.setMask(call HplAtmegaPinChange.getMask() | (1<<pin));
      call HplAtmegaPinChange.enable();
    }
    return SUCCESS;
  }

  /* Disables the interrupt */
  async command error_t GpioInterrupt.disable[uint8_t pin](){
    atomic {
      uint8_t mask = call HplAtmegaPinChange.getMask() & ~(1<<pin);
      call HplAtmegaPinChange.setMask(mask);
      if(mask==0)
        call HplAtmegaPinChange.disable();
    }
    return SUCCESS;
  }

  /* Signalled when any of the enabled pins changed */
  async event void HplAtmegaPinChange.fired(){
    uint8_t pins=call HplAtmegaPinChange.getMask() & ( call HplAtmegaPinChange.getPins() ^ isFalling );

    /*
     * Load the pins into memory and call the fired event in separate if
     * statements so the compiler can eliminate calls to unconnected interfaces
     */
    if( pins & (1<<0) )
      signal GpioInterrupt.fired[0]();
    if( pins & (1<<1) )
      signal GpioInterrupt.fired[1]();
    if( pins & (1<<2) )
      signal GpioInterrupt.fired[2]();
    if( pins & (1<<3) )
      signal GpioInterrupt.fired[3]();
    if( pins & (1<<4) )
      signal GpioInterrupt.fired[4]();
    if( pins & (1<<5) )
      signal GpioInterrupt.fired[5]();
    if( pins & (1<<6) )
      signal GpioInterrupt.fired[6]();
    if( pins & (1<<7) )
      signal GpioInterrupt.fired[7]();
  }

  default async event void GpioInterrupt.fired[uint8_t pin]() {}
}
