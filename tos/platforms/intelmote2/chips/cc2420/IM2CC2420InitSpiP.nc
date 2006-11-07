/* $Id: IM2CC2420InitSpiP.nc,v 1.3 2006-11-07 19:31:24 scipio Exp $ */
/*
 * Copyright (c) 2005 Arched Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arched Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/**
 *
 * @author Phil Buonadonna
 */
module IM2CC2420InitSpiP 
{
  
  provides interface Init;
  uses {
    interface HplPXA27xGPIOPin as SCLK;
    interface HplPXA27xGPIOPin as TXD;
    interface HplPXA27xGPIOPin as RXD;
  }
}

implementation 
{
  command error_t Init.init() {
    call SCLK.setGAFRpin(SSP3_SCLK_ALTFN);
    call SCLK.setGPDRbit(TRUE);
    call TXD.setGAFRpin(SSP3_TXD_ALTFN);
    call TXD.setGPDRbit(TRUE);
    call RXD.setGAFRpin(SSP3_RXD_ALTFN);
    call RXD.setGPDRbit(FALSE);

    return SUCCESS;
  }
  async event void SCLK.interruptGPIOPin() { return;} 
  async event void TXD.interruptGPIOPin() { return;} 
  async event void RXD.interruptGPIOPin() { return;} 

}
