/* 
 * Copyright (c) 2006, Ecole Polytechnique Federale de Lausanne (EPFL),
 * Switzerland.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Ecole Polytechnique Federale de Lausanne (EPFL) 
 *   nor the names of its contributors may be used to 
 *   endorse or promote products derived from this software without 
 *   specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ========================================================================
 */

/*
 * mm74hc595 driver internals.
 * 
 * @author Henri Dubois-Ferriere
 *
 */
 

module MM74HC595ImplP
{
  provides interface Init @atleastonce();
  provides async command void set(uint8_t pin);
  provides async command bool get(uint8_t pin);
  provides async command void clr(uint8_t pin);
  provides async command void toggle(uint8_t pin);
  uses interface GeneralIO as Ser;
  uses interface GeneralIO as Rck;
  uses interface GeneralIO as Sck;
  uses interface BusyWait<TMicro, uint16_t>;
}

implementation
{
  enum {
    npins = 8
  };

  uint8_t state;

  void writeState() {
    uint8_t i, s;    
    atomic s = state;

    call Rck.clr();
    for (i = 0; i < npins; i++) {
      call Sck.clr();
      if (s & 0x80) {
	call Ser.set();
      } else {
	call Ser.clr();
      }
      call Sck.set();
      s <<= 1;
    }
    call Rck.set();
    call Sck.clr();
    call Ser.clr();
    call Rck.clr();
  }


  command error_t Init.init() {
    state  = 0;

    call Ser.makeOutput();
    call Sck.makeOutput();
    call Rck.makeOutput();

    call Sck.clr();
    call Rck.clr();
    call Ser.clr();
    writeState();
    return SUCCESS;
  }


  async command void set(uint8_t pin) {
    atomic {
      state |= (1 << pin);
      writeState();
    }
  }

  async command bool get(uint8_t pin) {
    atomic return (state >> pin) & 1;
  }

  async command void clr(uint8_t pin) {
    atomic {
      state &=  ~(1 << pin);
      writeState();
    }
  }

  async command void toggle(uint8_t pin) {
    if (call get(pin))
      call clr(pin);
    else
      call set(pin);
  }
}  
