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
 *
 * Port/bit mapping.  We implement a single dispatch point, Int[portpin]
 * where portpin is (port)*16+bit.  This lets us minimize how much
 * code is generated to map all the ports and bits.  For example, Port2.3 is
 * 0x23 which is pretty easy to understand.
 */

#include <hardware.h>
#include <msp432_gpio.h>

module HplMsp432PortIntP {
  provides interface HplMsp432PortInt as Int[uint8_t portpin];
}

implementation {

#define PORTINT_ENTRY(x)                        \
    uint8_t portmod = (x >> 4) - 1;             \
    uint8_t portbit = x & 0xf;                  \
    uint8_t _t = !(portmod & 1);                \
    uint32_t _p;                                \
                                                \
    if (portmod > 5 || portbit > 7) _p = 0;     \
    else _p = port2base[portmod];


#define ODD   ((DIO_PORT_Odd_Interruptable_Type*)_p)
#define EVEN ((DIO_PORT_Even_Interruptable_Type*)_p)

  const uint32_t port2base[6] = {
    (uint32_t) P1,
    (uint32_t) P2,
    (uint32_t) P3,
    (uint32_t) P4,
    (uint32_t) P5,
    (uint32_t) P6,
  };

  void port_handler(uint8_t port_id, uint8_t n) {
    // call McuSleep.irq_preamble();
    switch(n) {
      default:
      case 0:   { break; }
      case 2:   { signal Int.fired[0+port_id](); break; }
      case 4:   { signal Int.fired[1+port_id](); break; }
      case 6:   { signal Int.fired[2+port_id](); break; }
      case 8:   { signal Int.fired[3+port_id](); break; }
      case 10:  { signal Int.fired[4+port_id](); break; }
      case 12:  { signal Int.fired[5+port_id](); break; }
      case 14:  { signal Int.fired[6+port_id](); break; }
      case 16:  { signal Int.fired[7+port_id](); break; }
    }
    // call McuSleep.irq_postamble();
  }

  default async event void Int.fired[uint8_t portpin]() {__bkpt(1);}


  async command void Int.enable[uint8_t portpin]() {
    PORTINT_ENTRY(portpin);
    if (!_p) return;
    if (_t) BITBAND_PERI(ODD->IE,  portbit)  = 1;
    else    BITBAND_PERI(EVEN->IE, portbit)  = 1;
  }

  async command void Int.disable[uint8_t portpin]() {
    PORTINT_ENTRY(portpin);
    if (!_p) return;
    if (_t) BITBAND_PERI(ODD->IE,  portbit)  = 0;
    else    BITBAND_PERI(EVEN->IE, portbit)  = 0;
  }

  async command void Int.clear[uint8_t portpin]() {
    PORTINT_ENTRY(portpin);
    if (!_p) return;
    if (_t) BITBAND_PERI(ODD->IFG,  portbit)  = 0;
    else    BITBAND_PERI(EVEN->IFG, portbit)  = 0;
  }

  async command bool Int.getValue[uint8_t portpin]() {
    PORTINT_ENTRY(portpin);
    if (!_p) return 0;
    if (_t) return BITBAND_PERI(ODD->IN,  portbit);
    else    return BITBAND_PERI(EVEN->IN, portbit);
  }

  async command void Int.edgeRising[uint8_t portpin]() {
    PORTINT_ENTRY(portpin);
    if (!_p) return;
    if (_t) BITBAND_PERI(ODD->IES,  portbit)  = 0;
    else    BITBAND_PERI(EVEN->IES, portbit)  = 0;
  }

  async command void Int.edgeFalling[uint8_t portpin]() {
    PORTINT_ENTRY(portpin);
    if (!_p) return;
    if (_t) BITBAND_PERI(ODD->IES,  portbit)  = 1;
    else    BITBAND_PERI(EVEN->IES, portbit)  = 1;
  }


  void PORT1_Handler() @C() @spontaneous() __attribute__((interrupt)) {
    uint8_t n = P1-> IV;
    port_handler(0x10, n);
  }

  void PORT2_Handler() @C() @spontaneous() __attribute__((interrupt)) {
    uint8_t n = P2-> IV;
    port_handler(0x20, n);
  }

  void PORT3_Handler() @C() @spontaneous() __attribute__((interrupt)) {
    uint8_t n = P3-> IV;
    port_handler(0x30, n);
  }

  void PORT4_Handler() @C() @spontaneous() __attribute__((interrupt)) {
    uint8_t n = P4-> IV;
    port_handler(0x40, n);
  }

  void PORT5_Handler() @C() @spontaneous() __attribute__((interrupt)) {
    uint8_t n = P5-> IV;
    port_handler(0x50, n);
  }

  void PORT6_Handler() @C() @spontaneous() __attribute__((interrupt)) {
    uint8_t n = P6-> IV;
    port_handler(0x60, n);
  }
}
