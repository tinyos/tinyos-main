/*
 * Copyright (c) 2010-2011 Eric B. Decker
 * Copyright (c) 2009 DEXMA SENSORS SL
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
 * An HPL abstraction for USCI A/B shared vector interrupt on the MSP430X.
 *
 * @author Xavier Orduna <xorduna@dexmatech.com>
 * @author Eric B. Decker <cire831@gmail.com>
 */

#include "msp430usci.h"

module HplMsp430UsciAB0RawInterruptsP @safe() {
  provides interface HplMsp430UsciRawInterrupts as UsciA;
  provides interface HplMsp430UsciRawInterrupts as UsciB;
}

implementation{

  TOSH_SIGNAL(USCIAB0RX_VECTOR) {
    uint8_t temp;
    if (IFG2 & UCA0RXIFG){
	    temp = UCA0RXBUF;
    	signal UsciA.rxDone(temp);
    }
    if (IFG2 & UCB0RXIFG){
	    temp = UCB0RXBUF;
    	signal UsciB.rxDone(temp);
    }
  }
  
  TOSH_SIGNAL(USCIAB0TX_VECTOR) {
    if ((IFG2 & UCA0TXIFG) | (IFG2 & UCA0RXIFG)){
    	signal UsciA.txDone();
    }
    if ((IFG2 & UCB0TXIFG) | (IFG2 & UCB0RXIFG)){
    	signal UsciB.txDone();
    }
  }


  /* default handlers */
  default async event void UsciA.txDone(){
  	return;
  }
  
  default async event void UsciA.rxDone(uint8_t temp){
  	return;
  }

  default async event void UsciB.txDone(){
  	return;
  }
  
  default async event void UsciB.rxDone(uint8_t temp){
  	return;
  }
  
}
