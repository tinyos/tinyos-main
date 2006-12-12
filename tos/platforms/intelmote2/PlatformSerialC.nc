/* $Id: PlatformSerialC.nc,v 1.4 2006-12-12 18:23:42 vlahan Exp $ */
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
 * @author Phil Buonadonna
 *
 */

configuration PlatformSerialC {
  provides interface StdControl;
  provides interface UartByte;
  provides interface UartStream;
}
implementation {

  components new HalPXA27xSerialP(115200); 
  components HplPXA27xSTUARTC;
  components HplPXA27xGPIOC;
  components IM2InitSerialP;
  
  StdControl = HalPXA27xSerialP;
  UartByte = HalPXA27xSerialP;
  UartStream = HalPXA27xSerialP;

  HalPXA27xSerialP.UARTInit -> HplPXA27xSTUARTC.Init;
  HalPXA27xSerialP.UART -> HplPXA27xSTUARTC.STUART;

  IM2InitSerialP.TXD -> HplPXA27xGPIOC.HplPXA27xGPIOPin[STUART_TXD];
  IM2InitSerialP.RXD -> HplPXA27xGPIOC.HplPXA27xGPIOPin[STUART_RXD];

  components PlatformP;
  IM2InitSerialP.Init <- PlatformP.InitL2;
  HalPXA27xSerialP.Init <- PlatformP.InitL3;

  components new HplPXA27xDMAInfoC(19, (uint32_t) &STRBR) as DMAInfoRx;
  components new HplPXA27xDMAInfoC(20, (uint32_t) &STTHR) as DMAInfoTx;
  components HplPXA27xDMAC;
  // how are these channels picked?
  HalPXA27xSerialP.TxDMA -> HplPXA27xDMAC.HplPXA27xDMAChnl[2];
  HalPXA27xSerialP.RxDMA -> HplPXA27xDMAC.HplPXA27xDMAChnl[3];
  DMAInfoRx.HplPXA27xDMAInfo <- HalPXA27xSerialP.UARTRxDMAInfo;
  DMAInfoTx.HplPXA27xDMAInfo <- HalPXA27xSerialP.UARTTxDMAInfo;
}
