/*
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
 * - Neither the name of the Arch Rock Corporation nor the names of
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
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.5 $ $Date: 2008-06-26 04:39:08 $
 */

generic module Msp430UsartShareP() @safe() {
  
  provides interface HplMsp430UsartInterrupts as Interrupts[ uint8_t id ];
  provides interface HplMsp430I2CInterrupts as I2CInterrupts[ uint8_t id ];
  uses interface HplMsp430UsartInterrupts as RawInterrupts;
  uses interface HplMsp430I2CInterrupts as RawI2CInterrupts;
  uses interface ArbiterInfo;
  
}

implementation {
  
  async event void RawInterrupts.txDone() {
    if ( call ArbiterInfo.inUse() )
      signal Interrupts.txDone[ call ArbiterInfo.userId() ]();
  }
  
  async event void RawInterrupts.rxDone( uint8_t data ) {
    if ( call ArbiterInfo.inUse() )
      signal Interrupts.rxDone[ call ArbiterInfo.userId() ]( data );
  }
  
  async event void RawI2CInterrupts.fired() {
    if ( call ArbiterInfo.inUse() )
      signal I2CInterrupts.fired[ call ArbiterInfo.userId() ]();
  }
  
  default async event void Interrupts.txDone[ uint8_t id ]() {}
  default async event void Interrupts.rxDone[ uint8_t id ]( uint8_t data ) {}
  default async event void I2CInterrupts.fired[ uint8_t id ]() {}

}
