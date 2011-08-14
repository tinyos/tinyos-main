/**
 * Copyright (c) 2009-2010 DEXMA SENSORS SL
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * @author Jonathan Hui <jhui@archedrock.com>
 * @author Vlado Handziski <handzisk@tkn.tu-berlin.de>
 * @author Eric B. Decker <cire831@gmail.com>
 * @author Xavier Orduna <xorduna@dexmatech.com>
 * @version $Revision: 1.5 $ $Date: 2008/05/21 22:11:57 $
 */

configuration Msp430Uart0P {

  provides interface Resource[ uint8_t id ];
  provides interface ResourceConfigure[ uint8_t id ];
  provides interface UartStream[ uint8_t id ];
  provides interface UartByte[ uint8_t id ];

  uses interface Resource as UsciResource[ uint8_t id ];
  uses interface Msp430UartConfigure[ uint8_t id ];
  uses interface HplMsp430UsciInterrupts as UsciInterrupts[ uint8_t id ];
}

implementation {
  components new Msp430UartP() as UartP;
  Resource = UartP.Resource;
  ResourceConfigure = UartP.ResourceConfigure;
  Msp430UartConfigure = UartP.Msp430UartConfigure;
  UartStream = UartP.UartStream;
  UartByte = UartP.UartByte;
  UsciResource = UartP.UsciResource;
  UsciInterrupts = UartP.UsciInterrupts;

  components HplMsp430UsciA0C as UsciC;
  UartP.Usci -> UsciC;

  components Counter32khz16C as CounterC;
  UartP.Counter -> CounterC;

  components LedsC as Leds;
  UartP.Leds -> Leds;

}
