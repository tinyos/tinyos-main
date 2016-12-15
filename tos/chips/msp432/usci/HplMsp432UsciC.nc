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
 */

/**
 * Core configuration for any USCI module present on an MSP432 chip.
 *
 * There should be exactly one instance of this configuration for each
 * USCI module; e.g., USCI_A0 or USCI_B3.  Each instance provides
 * access to the USCI registers for its module, and maintains the
 * resource management information required to determine which of the
 * module's modes is currently active.
 *
 * @author: Eric B. Decker <cire831@gmail.com>
 *
 * Loosely based on msp430 x5xx USCI code by Eric B. Decker and Peter
 * Bigot.
 */

#include "msp432usci.h"

generic configuration
  HplMsp432UsciC(uint32_t up, uint32_t irqn, uint8_t _t) {

  provides {
    interface HplMsp432Usci       as Usci;
    interface HplMsp432UsciInt    as UsciInt;
  }
  uses interface HplMsp432UsciInt as RawInterrupt;
}
implementation {

  enum {
    USCI_ID = unique(MSP432_USCI_RESOURCE),
  };

  components new HplMsp432UsciP(up, irqn, USCI_ID, _t) as HplUsciP;
  Usci         = HplUsciP;
  UsciInt      = HplUsciP.Interrupt;
  RawInterrupt = HplUsciP.RawInterrupt;
}
