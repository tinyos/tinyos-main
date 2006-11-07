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
 * Provides an interface for USART0 on the MSP430.
 *
 * @author Jonathan Hui <jhui@archedrock.com>
 * @version $Revision: 1.3 $ $Date: 2006-11-07 19:31:09 $
 */

generic configuration Msp430Usart0C() {

  provides interface Resource;
  provides interface ArbiterInfo;
  provides interface HplMsp430Usart;
  provides interface HplMsp430UsartInterrupts;
  provides interface HplMsp430I2CInterrupts;
#ifdef __msp430_have_usart0_with_i2c
  provides interface HplMsp430I2C;
#endif  

  uses interface ResourceConfigure;
  
}

implementation {

  enum {
    CLIENT_ID = unique( MSP430_HPLUSART0_RESOURCE ),
  };

  components Msp430UsartShare0P as UsartShareP;

  Resource = UsartShareP.Resource[ CLIENT_ID ];
  ResourceConfigure = UsartShareP.ResourceConfigure[ CLIENT_ID ];
  ArbiterInfo = UsartShareP.ArbiterInfo;
  HplMsp430UsartInterrupts = UsartShareP.Interrupts[ CLIENT_ID ];
  HplMsp430I2CInterrupts = UsartShareP.I2CInterrupts[ CLIENT_ID ];
  
  components HplMsp430Usart0C as HplUsartC;
  HplMsp430Usart = HplUsartC;
  
#ifdef __msp430_have_usart0_with_i2c
  components HplMsp430I2C0C as HplI2CC;
  HplMsp430I2C = HplI2CC;
#endif
  
}
