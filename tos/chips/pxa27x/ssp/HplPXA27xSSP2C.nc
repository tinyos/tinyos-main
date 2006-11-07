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

configuration HplPXA27xSSP2C 
{
  provides {
    interface HplPXA27xSSP;
    interface HplPXA27xDMAInfo as SSPRxDMAReg;
    interface HplPXA27xDMAInfo as SSPTxDMAReg;
  }
}

implementation
{
  components HplPXA27xSSPP;
  components HplPXA27xInterruptM;
  components PlatformP;

  HplPXA27xSSP = HplPXA27xSSPP.HplPXA27xSSP[2];
  components new HplPXA27xDMAInfoC(15, (uint32_t)&SSDR_2) as SSPRxDMA;
  components new HplPXA27xDMAInfoC(16, (uint32_t)&SSDR_2) as SSPTxDMA;
  SSPRxDMAReg = SSPRxDMA;
  SSPTxDMAReg = SSPTxDMA;

  HplPXA27xSSPP.Init[2] <- PlatformP.InitL1;

  HplPXA27xSSPP.SSP2Irq -> HplPXA27xInterrupM.PXA27xIrq[PPID_SSP2];
}
