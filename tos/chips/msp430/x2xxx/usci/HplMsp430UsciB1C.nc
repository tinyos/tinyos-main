/*
 * Copyright (c) 2011 Eric B. Decker
 * Copyright (c) 2009 DEXMA SENSORS SL
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * Copyright (c) 2000-2005 The Regents of the University  of California.
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

/*
 * An HPL abstraction of USCIB1 on the MSP430.
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @author Joe Polastre
 * @author Xavier Orduna <xorduna@dexmatech.com>
 * @author Eric B. Decker <cire831@gmail.com>
 */

#include "msp430usci.h"

configuration HplMsp430UsciB1C {
  provides {
    interface HplMsp430UsciB;
    interface HplMsp430UsciInterrupts;
  }
}

implementation {
  components HplMsp430UsciB1P as HplUsciP;
  HplMsp430UsciB = HplUsciP;
  HplMsp430UsciInterrupts = HplUsciP;

  components HplMsp430GeneralIOC as GIO;
  HplUsciP.SIMO -> GIO.UCB1SIMO;
  HplUsciP.SOMI -> GIO.UCB1SOMI;
  HplUsciP.UCLK -> GIO.UCB1CLK;
  HplUsciP.USDA -> GIO.UCB1SDA;
  HplUsciP.USCL -> GIO.UCB1SCL;

  components HplMsp430UsciAB1RawInterruptsP as UsciRawInterrupts;
  HplUsciP.UsciRawInterrupts -> UsciRawInterrupts.UsciB;
}
