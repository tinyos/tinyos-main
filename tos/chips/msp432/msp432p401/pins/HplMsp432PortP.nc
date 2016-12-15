/*
 * Copyright (c) 2016 Eric B. Decker
 * All Rights Reserved.
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
 * - Neither the name of the copyright holders nor the names of
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
 */

/**
 * Low level digital port access for Msp432 chips.
 *
 * Gpio that includes setFunction, Resistor Enable (REN) and
 * Drive Strength (DS).
 *
 * All access to individual bits of port control registers is done via
 * bit band accesses.  These accesses are inherently atomic so do not
 * need to be protected via "atomic".
 *
 * There are some situations below where multiple bits (ie. SELn) are being
 * accessed.  These could be protected by atomic to make sure, but the
 * whole situation (colliding on a single bit) would be most weird.  Don't
 * see it happening.
 */

#include <hardware.h>
#include <msp432_gpio.h>

/*
 * _p is a port pointer from msp432p401r.h, ie. P2 which is defined as
 * ((DIO_PORT_Even_Interruptable_Type*) (DIO_BASE + 0x0000)), which
 * technically is a pointer.  To make this work with generics we have
 * to force it to a uint32_t and then have to cast it to the proper port
 * type.
 *
 * _t is the port type, 0 for even, 1 for odd.
 *
 * NOTE: Even and Odd Ports (see msp432p401r.h) have different structures
 * because of TI stupido interleaved ports to try and get 16 bit ports
 * which no one uses.  That is why we have ODD and EVEN references below.
 * A pain but it works.
 */

generic module HplMsp432PortP(uint32_t _p, uint8_t _t) {
  provides interface HplMsp432Gpio as Pin[uint8_t pin];
}
implementation {

#define ODD   ((DIO_PORT_Odd_Interruptable_Type*)_p)
#define EVEN ((DIO_PORT_Even_Interruptable_Type*)_p)

  async command void Pin.set[uint8_t pin]()    {
    if (_t) BITBAND_PERI(ODD->OUT,  pin)  = 1;
    else    BITBAND_PERI(EVEN->OUT, pin)  = 1; }

  async command void Pin.clr[uint8_t pin]()    {
    if (_t) BITBAND_PERI(ODD->OUT,  pin)  = 0;
    else    BITBAND_PERI(EVEN->OUT, pin)  = 0; }

  async command void Pin.toggle[uint8_t pin]()            {
    if (_t) atomic { BITBAND_PERI(ODD->OUT,  pin) ^= 1; }
    else    atomic { BITBAND_PERI(EVEN->OUT, pin) ^= 1; } }

  async command bool Pin.get[uint8_t pin]()     {
    if (_t) return BITBAND_PERI(ODD->IN,  pin);
    else    return BITBAND_PERI(EVEN->IN, pin); }

  async command void Pin.makeInput[uint8_t pin]() {
    if (_t) BITBAND_PERI(ODD->DIR,  pin)  = 0;
    else    BITBAND_PERI(EVEN->DIR, pin)  = 0;    }

  async command bool Pin.isInput[uint8_t pin]()   {
    if (_t) return !BITBAND_PERI(ODD->DIR,  pin);
    else    return !BITBAND_PERI(EVEN->DIR, pin); }

  async command void Pin.makeOutput[uint8_t pin]() {
    if (_t) BITBAND_PERI(ODD->DIR,  pin)  = 1;
    else    BITBAND_PERI(EVEN->DIR, pin)  = 1;     }

  async command bool Pin.isOutput[uint8_t pin]() {
    if (_t) return BITBAND_PERI(ODD->DIR,  pin);
    else    return BITBAND_PERI(EVEN->DIR, pin); }

  async command error_t Pin.setFunction[uint8_t pin](uint8_t func) {
    switch(func) {
      case MSP432_GPIO_IO:
        if (_t) {
          BITBAND_PERI(ODD->SEL0, pin)  = 0;
          BITBAND_PERI(ODD->SEL1, pin)  = 0;
        } else {
          BITBAND_PERI(EVEN->SEL0, pin)  = 0;
          BITBAND_PERI(EVEN->SEL1, pin)  = 0;
        }
        break;

      case MSP432_GPIO_MOD:
      case MSP432_GPIO_MOD1:
        if (_t) {
          BITBAND_PERI(ODD->SEL0, pin)  = 1;
          BITBAND_PERI(ODD->SEL1, pin)  = 0;
        } else {
          BITBAND_PERI(EVEN->SEL0, pin)  = 1;
          BITBAND_PERI(EVEN->SEL1, pin)  = 0;
        }
        break;

      case MSP432_GPIO_MOD2:
        if (_t) {
          BITBAND_PERI(ODD->SEL0, pin)  = 0;
          BITBAND_PERI(ODD->SEL1, pin)  = 1;
        } else {
          BITBAND_PERI(EVEN->SEL0, pin)  = 0;
          BITBAND_PERI(EVEN->SEL1, pin)  = 1;
        }
        break;

      case MSP432_GPIO_MOD3:
      case MSP432_GPIO_ANALOG:
        if (_t) {
          BITBAND_PERI(ODD->SEL0, pin)  = 1;
          BITBAND_PERI(ODD->SEL1, pin)  = 1;
        } else {
          BITBAND_PERI(EVEN->SEL0, pin)  = 1;
          BITBAND_PERI(EVEN->SEL1, pin)  = 1;
        }
        break;
    }
    return SUCCESS;
  }


  async command uint8_t Pin.getFunction[uint8_t pin]() {
    uint8_t val;

    val = (_t) ? BITBAND_PERI(ODD->SEL1, pin)  * 2 + BITBAND_PERI(ODD->SEL0, pin)
               : BITBAND_PERI(EVEN->SEL1, pin) * 2 + BITBAND_PERI(EVEN->SEL0, pin);
    return val;
  }


  async command void Pin.setResistorMode[uint8_t pin](uint8_t mode) {
    switch (mode) {
      case MSP432_GPIO_RESISTOR_OFF:
        if (_t) BITBAND_PERI(ODD->REN,  pin)  = 0;
        else    BITBAND_PERI(EVEN->REN,  pin)  = 0;
        return;

      case MSP432_GPIO_RESISTOR_PULLDOWN:
        if (_t) {
          BITBAND_PERI(ODD->REN,  pin)  = 1;
          BITBAND_PERI(ODD->OUT,  pin)  = 0;
        } else {
          BITBAND_PERI(EVEN->REN,  pin)  = 1;
          BITBAND_PERI(EVEN->OUT,  pin)  = 0;
        }
        return;

      case MSP432_GPIO_RESISTOR_PULLUP:
        if (_t) {
          BITBAND_PERI(ODD->REN,  pin)  = 1;
          BITBAND_PERI(ODD->OUT,  pin)  = 1;
        } else {
          BITBAND_PERI(EVEN->REN,  pin)  = 1;
          BITBAND_PERI(EVEN->OUT,  pin)  = 1;
        }
        return;
    }
  }


  async command uint8_t Pin.getResistorMode[uint8_t pin]() {
    uint8_t val;

    val = (_t) ? BITBAND_PERI(ODD->REN,  pin)
               : BITBAND_PERI(EVEN->REN,  pin);
    if (!val)
      return MSP432_GPIO_RESISTOR_OFF;
    val = (_t) ? BITBAND_PERI(ODD->OUT,  pin)
               : BITBAND_PERI(EVEN->OUT,  pin);
    if (val)
      return MSP432_GPIO_RESISTOR_PULLUP;
    return MSP432_GPIO_RESISTOR_PULLDOWN;
  }


  async command void Pin.setDSMode[uint8_t pin](uint8_t mode) {
    switch(mode) {
      case MSP432_GPIO_DS_DEFAULT:
      case MSP432_GPIO_DS_REGULAR:
        if (_t) BITBAND_PERI(ODD->DS, pin)  = 0;
        else    BITBAND_PERI(EVEN->DS, pin)  = 0;
        break;
      case MSP432_GPIO_DS_HIGH:
        if (_t) BITBAND_PERI(ODD->DS, pin)  = 1;
        else    BITBAND_PERI(EVEN->DS, pin)  = 1;
        break;
    }
    return;
  }


  async command uint8_t Pin.getDSMode[uint8_t pin]() {
    uint8_t val;

    val = (_t) ? BITBAND_PERI(ODD->DS, pin)
               : BITBAND_PERI(EVEN->DS, pin);
    if (val)
      return MSP432_GPIO_DS_HIGH;
    else
      return MSP432_GPIO_DS_REGULAR;
  }
}
