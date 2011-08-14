/**
 * Copyright (c) 2009 DEXMA SENSORS SL
 * Copyright (c) 2005-2006 Arched Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * - Neither the name of the DEXMA SENSORS SL nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * DEXMA SENSORS SL OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * @author Jonathan Hui <jhui@archedrock.com>
 * @author Xavier Orduna <xorduna@dexmatech.com>
 * @version $Revision: 1.4 $ $Date: 2006/12/12 18:23:11 $
 */

configuration Msp430SpiNoDmaB0P {

  provides interface Resource[ uint8_t id ];
  provides interface ResourceConfigure[uint8_t id ];
  provides interface SpiByte;
  provides interface SpiPacket[ uint8_t id ];

  uses interface Resource as UsciResource[ uint8_t id ];
  uses interface Msp430SpiConfigure[ uint8_t id ];
  uses interface HplMsp430UsciInterrupts as UsciInterrupts;

}

implementation {

  components new Msp430SpiNoDmaBP() as SpiP;
  components new Z1UsciP() as Z1UsciP;
  Resource = SpiP.Resource;
  ResourceConfigure = SpiP.ResourceConfigure;
  Msp430SpiConfigure = SpiP.Msp430SpiConfigure;
  SpiP.Msp430SpiConfigure -> Z1UsciP.Msp430SpiConfigure;
  SpiByte = SpiP.SpiByte;
  SpiPacket = SpiP.SpiPacket;
  UsciResource = SpiP.UsciResource;
  UsciInterrupts = SpiP.UsciInterrupts;

  components HplMsp430UsciB0C as UsciC;
  SpiP.Usci -> UsciC;

  components LedsC as Leds;
  SpiP.Leds -> Leds;

}
