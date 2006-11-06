/*
 * Copyright (c) 2005 Arch Rock Corporation 
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
 *   Neither the name of the Arch Rock Corporation nor the names of its
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
 *
 * @author Kaisen Lin
 * @author Phil Buonadonna
 */

generic configuration HalPXA27xSpiDMAC(uint8_t valSCR,
				       uint8_t valDSS,
				       bool enableRWOT)
{
  provides interface Init;
  provides interface SpiByte;
  provides interface SpiPacket[uint8_t instance];
  provides interface HalPXA27xSSPCntl;

  uses {
    interface HplPXA27xSSP as SSP;
    interface HplPXA27xDMAChnl as RxDMA;
    interface HplPXA27xDMAChnl as TxDMA;
    interface HplPXA27xDMAInfo as SSPRxDMAInfo;
    interface HplPXA27xDMAInfo as SSPTxDMAInfo;
  }
}

implementation {
  components new HalPXA27xSpiDMAM(2, valSCR, valDSS, enableRWOT);
  components HalPXA27xSSPControlP;

  Init = HalPXA27xSpiDMAM;
  SpiByte = HalPXA27xSpiDMAM;
  SpiPacket = HalPXA27xSpiDMAM;
  HalPXA27xSSPCntl = HalPXA27xSSPControlP;

  SSP = HalPXA27xSpiDMAM;
  SSP = HalPXA27xSSPControlP;
  RxDMA = HalPXA27xSpiDMAM;
  TxDMA = HalPXA27xSpiDMAM;
  SSPRxDMAInfo = HalPXA27xSpiDMAM;
  SSPTxDMAInfo = HalPXA27xSpiDMAM;

}
