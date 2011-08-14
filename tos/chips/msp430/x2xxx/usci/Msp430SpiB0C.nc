/*
 * Copyright (c) 2010-2011 Eric B. Decker
 * Copyright (c) 2009 DEXMA SENSORS SL
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 * SpiB0: SPI/USCI_B0.  Defaults to no DMA, sw SPI implementation.
 * To utilize the DMA, via Msp430SpiB0DmaP define ENABLE_SPIB0_DMA.
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @author Mark Hays
 * @author Xavier Orduna <xorduna@dexmatech.com>
 * @author Eric B. Decker <cire831@gmail.com>
 */

#include "msp430usci.h"

generic configuration Msp430SpiB0C() {
  provides {
    interface Resource;
    interface ResourceRequested;
    interface SpiByte;
    interface SpiPacket;
  }
  uses interface Msp430SpiConfigure;
}

implementation {

  enum {
    CLIENT_ID = unique(MSP430_SPI0_BUS),
  };

#ifdef ENABLE_SPIB0_DMA
#warning "Enabling SPI DMA on USCIB0"
  components Msp430SpiDmaB0P as SpiP;
#else
  components Msp430SpiNoDmaB0P as SpiP;
#endif

  Resource = SpiP.Resource[CLIENT_ID];
  SpiByte = SpiP.SpiByte;
  SpiPacket = SpiP.SpiPacket[CLIENT_ID];
  Msp430SpiConfigure = SpiP.Msp430SpiConfigure[CLIENT_ID];

  components new Msp430UsciB0C() as UsciC;
  ResourceRequested = UsciC;
  SpiP.ResourceConfigure[CLIENT_ID] <- UsciC.ResourceConfigure;
  SpiP.UsciResource[CLIENT_ID] -> UsciC.Resource;
  SpiP.UsciInterrupts -> UsciC.HplMsp430UsciInterrupts;
}
