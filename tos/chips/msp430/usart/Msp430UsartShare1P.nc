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

/**
 * @author Vlado Handziski <handzisk@tkn.tu-berlin.de>
 * @author Jonathan Hui <jhui@archedrock.com>
 * @version $Revision: 1.6 $ $Date: 2008-05-21 22:11:57 $
 */

configuration Msp430UsartShare1P {

  provides interface HplMsp430UsartInterrupts as Interrupts[ uint8_t id ];
  provides interface Resource[ uint8_t id ];
  provides interface ResourceRequested[ uint8_t id ];
  provides interface ArbiterInfo;

  uses interface ResourceConfigure[ uint8_t id ];
}

implementation {

  components new Msp430UsartShareP() as UsartShareP;
  Interrupts = UsartShareP;
  UsartShareP.RawInterrupts -> UsartC;

  components new FcfsArbiterC( MSP430_HPLUSART1_RESOURCE ) as ArbiterC;
  Resource = ArbiterC;
  ResourceRequested = ArbiterC;
  ResourceConfigure = ArbiterC;
  ArbiterInfo = ArbiterC;
  UsartShareP.ArbiterInfo -> ArbiterC;

  components new AsyncStdControlPowerManagerC() as PowerManagerC;
  PowerManagerC.ResourceDefaultOwner -> ArbiterC;
	
  components HplMsp430Usart1C as UsartC;
  PowerManagerC.AsyncStdControl -> UsartC;
}
