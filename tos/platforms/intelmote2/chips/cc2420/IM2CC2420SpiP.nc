/* $Id: IM2CC2420SpiP.nc,v 1.5 2008-05-27 17:48:16 kusy Exp $ */
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
configuration IM2CC2420SpiP 
{
  
  provides interface Init;
  provides interface Resource[uint8_t id];
  provides interface SpiByte;
  provides interface SpiPacket[uint8_t instance];

}

implementation 
{

  components new SimpleFcfsArbiterC("CC2420SpiClient") as FcfsArbiterC;
  //components new HalPXA27xSpiDMAC(1,0x7,FALSE) as HalPXA27xSpiM; // 6.5 Mbps, 8bit width
  components new HalPXA27xSpiPioC(1,0x7,FALSE) as HalPXA27xSpiM; // 6.5 Mbps, 8bit width
  components IM2CC2420InitSpiP;
  components HplPXA27xSSP3C;
  components HplPXA27xDMAC;
  components HplPXA27xGPIOC;
  components PlatformP;

  Init = IM2CC2420InitSpiP;
  Init = HalPXA27xSpiM.Init;

  SpiByte = HalPXA27xSpiM;
  SpiPacket = HalPXA27xSpiM;
  Resource = FcfsArbiterC;

  IM2CC2420InitSpiP.SCLK -> HplPXA27xGPIOC.HplPXA27xGPIOPin[SSP3_SCLK];
  IM2CC2420InitSpiP.TXD -> HplPXA27xGPIOC.HplPXA27xGPIOPin[SSP3_TXD];
  IM2CC2420InitSpiP.RXD -> HplPXA27xGPIOC.HplPXA27xGPIOPin[SSP3_RXD];

  //HalPXA27xSpiM.RxDMA -> HplPXA27xDMAC.HplPXA27xDMAChnl[0];
  //HalPXA27xSpiM.TxDMA -> HplPXA27xDMAC.HplPXA27xDMAChnl[1];
  //HalPXA27xSpiM.SSPRxDMAInfo -> HplPXA27xSSP3C.SSPRxDMAInfo;
  //HalPXA27xSpiM.SSPTxDMAInfo -> HplPXA27xSSP3C.SSPTxDMAInfo;

  HalPXA27xSpiM.SSP -> HplPXA27xSSP3C.HplPXA27xSSP;
  
}
