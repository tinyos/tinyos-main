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
 * @author Xavier Orduna <xorduna@dexmatech.com>
 * @version $Revision: 1.5 $ $Date: 2008/05/21 22:11:57 $
 */

configuration Msp430UsciShareB1P {

  provides interface HplMsp430UsciInterrupts as Interrupts[ uint8_t id ];
  provides interface Resource[ uint8_t id ];
  provides interface ResourceRequested[ uint8_t id ];
  provides interface ArbiterInfo;

  uses interface ResourceConfigure[ uint8_t id ];
}

implementation {

  components new Msp430UsciShareP() as UsciShareP;
  Interrupts = UsciShareP;
  
  components new FcfsArbiterC( MSP430_HPLUSCIB1_RESOURCE ) as ArbiterC;
  Resource = ArbiterC;
  ResourceRequested = ArbiterC;
  ResourceConfigure = ArbiterC;
  ArbiterInfo = ArbiterC;
  UsciShareP.ArbiterInfo -> ArbiterC;

  components HplMsp430UsciB1C as HplUsciC;
  UsciShareP.RawInterrupts -> HplUsciC;

}
