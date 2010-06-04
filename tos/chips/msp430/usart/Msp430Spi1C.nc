/**
 * Copyright (c) 2005-2006 Arched Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arched Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/*
 * Copyright (c) 2010, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Janos Sallai
 */ 

/**
 * An implementation of the SPI on USART0 for the MSP430. The current
 * implementation defaults not using the DMA and performing the SPI
 * transfers in software. To utilize the DMA, use Msp430SpiDma0P in
 * place of Msp430SpiNoDma0P.
 *
 * @author Jonathan Hui <jhui@archedrock.com>
 * @author Mark Hays
 * @version $Revision: 1.8 $ $Date: 2010-06-04 22:31:21 $
 */

#include "msp430usart.h"

generic configuration Msp430Spi1C() {

  provides interface Resource;
  provides interface ResourceRequested;
  provides interface SpiByte;
#ifndef ENABLE_SPI1_DMA
  provides interface FastSpiByte;
#endif  
  provides interface SpiPacket;

  uses interface Msp430SpiConfigure;
}

implementation {

  enum {
    CLIENT_ID = unique( MSP430_SPI1_BUS ),
  };

#ifdef ENABLE_SPI1_DMA
#warning "Enabling SPI DMA on USART1"
  components Msp430SpiDma1P as SpiP;
#else
  components Msp430SpiNoDma1P as SpiP;
#endif

  Resource = SpiP.Resource[ CLIENT_ID ];
  SpiByte = SpiP.SpiByte;
#ifndef ENABLE_SPI1_DMA
  FastSpiByte = SpiP.FastSpiByte;
#endif  
  SpiPacket = SpiP.SpiPacket[ CLIENT_ID ];
  Msp430SpiConfigure = SpiP.Msp430SpiConfigure[ CLIENT_ID ];

  components new Msp430Usart1C() as UsartC;
  ResourceRequested = UsartC;
  SpiP.ResourceConfigure[ CLIENT_ID ] <- UsartC.ResourceConfigure;
  SpiP.UsartResource[ CLIENT_ID ] -> UsartC.Resource;
  SpiP.UsartInterrupts -> UsartC.HplMsp430UsartInterrupts;

}
