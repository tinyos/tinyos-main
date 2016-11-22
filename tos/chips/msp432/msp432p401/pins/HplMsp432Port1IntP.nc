/*
 * Copyright (c) 2016 Eric B. Decker
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
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
 * @author Eric B. Decker <cire831@gmail.com>
 *
 * Interface to Port interrupt mechanism on the MSP432 processor.
 *
 * The interrupt vector hook is called PORT<n>_Handler.  The actual vector
 * table includes this hook as a weak alias.  We reinstantiate it in this
 * module.  The weak alias is defined in the platform file
 * tos/platform/<platform>/vectors.c
 *
 * On entry to the handler, P<n>->IV will indicate the highest priority pin
 * interrupt for the port.  Reading or writing (we read) IV will clear the
 * pending interrupt.
 */

#include <hardware.h>
#include <msp432_gpio.h>

module HplMsp432Port1IntP {
  provides interface HplMsp432PortInt as Int[uint8_t pin];
}

implementation {

#define PORT P1

  void PORT1_Handler() @C() @spontaneous() __attribute__((interrupt)) {
    uint8_t n;

    // call McuSleep.irq_preamble();
    n = PORT->IV;
    switch(n) {
      default:
      case 0:   { break; }
      case 2:   { signal Int[0].fired(); break; }
      case 4:   { signal Int[1].fired(); break; }
      case 6:   { signal Int[2].fired(); break; }
      case 8:   { signal Int[3].fired(); break; }
      case 10:  { signal Int[4].fired(); break; }
      case 12:  { signal Int[5].fired(); break; }
      case 14:  { signal Int[6].fired(); break; }
      case 16:  { signal Int[7].fired(); break; }
    }
    // call McuSleep.irq_postamble();

  }

//  default async event void Int[uint8_t pin].fired() {}

  async command void Int.enable     [uint8_t pin]() {        BITBAND_PERI(PORT->IE,  pin) = 1; }
  async command void Int.disable    [uint8_t pin]() {        BITBAND_PERI(PORT->IE,  pin) = 0; }
  async command void Int.clear      [uint8_t pin]() {        BITBAND_PERI(PORT->IFG, pin) = 0; }
  async command void Int.getValue   [uint8_t pin]() { return BITBAND_PERI(PORT->IN,  pin);     }
  async command void Int.edgeRising [uint8_t pin]() {        BITBAND_PERI(PORT->IES, pin) = 0; }
  async command void Int.edgeFalling[uint8_t pin]() {        BITBAND_PERI(PORT->IES, pin) = 1; }
}
