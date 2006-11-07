/* $Id: HplPXA27xDMAC.nc,v 1.3 2006-11-07 19:31:10 scipio Exp $ */
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
configuration HplPXA27xDMAC
{
  provides {
    interface HplPXA27xDMACntl;
    interface HplPXA27xDMAChnl[uint8_t chnl];
  }
}
implementation
{
  components HplPXA27xDMAM;
  components HplPXA27xInterruptM;
  components PlatformP;
  
  HplPXA27xDMACntl = HplPXA27xDMAM;

  HplPXA27xDMAChnl[0] = HplPXA27xDMAM.HplPXA27xDMAChnl[0];
  HplPXA27xDMAChnl[1] = HplPXA27xDMAM.HplPXA27xDMAChnl[1];
  HplPXA27xDMAChnl[2] = HplPXA27xDMAM.HplPXA27xDMAChnl[2];
  HplPXA27xDMAChnl[3] = HplPXA27xDMAM.HplPXA27xDMAChnl[3];
  HplPXA27xDMAChnl[4] = HplPXA27xDMAM.HplPXA27xDMAChnl[4];
  HplPXA27xDMAChnl[5] = HplPXA27xDMAM.HplPXA27xDMAChnl[5];
  HplPXA27xDMAChnl[6] = HplPXA27xDMAM.HplPXA27xDMAChnl[6];
  HplPXA27xDMAChnl[7] = HplPXA27xDMAM.HplPXA27xDMAChnl[7];
  HplPXA27xDMAChnl[8] = HplPXA27xDMAM.HplPXA27xDMAChnl[8];
  HplPXA27xDMAChnl[9] = HplPXA27xDMAM.HplPXA27xDMAChnl[9];
  HplPXA27xDMAChnl[10] = HplPXA27xDMAM.HplPXA27xDMAChnl[10];
  HplPXA27xDMAChnl[11] = HplPXA27xDMAM.HplPXA27xDMAChnl[11];
  HplPXA27xDMAChnl[12] = HplPXA27xDMAM.HplPXA27xDMAChnl[12];
  HplPXA27xDMAChnl[13] = HplPXA27xDMAM.HplPXA27xDMAChnl[13];
  HplPXA27xDMAChnl[14] = HplPXA27xDMAM.HplPXA27xDMAChnl[14];
  HplPXA27xDMAChnl[15] = HplPXA27xDMAM.HplPXA27xDMAChnl[15];
  HplPXA27xDMAChnl[16] = HplPXA27xDMAM.HplPXA27xDMAChnl[16];
  HplPXA27xDMAChnl[17] = HplPXA27xDMAM.HplPXA27xDMAChnl[17];
  HplPXA27xDMAChnl[18] = HplPXA27xDMAM.HplPXA27xDMAChnl[18];
  HplPXA27xDMAChnl[19] = HplPXA27xDMAM.HplPXA27xDMAChnl[19];
  HplPXA27xDMAChnl[20] = HplPXA27xDMAM.HplPXA27xDMAChnl[20];
  HplPXA27xDMAChnl[21] = HplPXA27xDMAM.HplPXA27xDMAChnl[21];
  HplPXA27xDMAChnl[22] = HplPXA27xDMAM.HplPXA27xDMAChnl[22];
  HplPXA27xDMAChnl[23] = HplPXA27xDMAM.HplPXA27xDMAChnl[23];
  HplPXA27xDMAChnl[24] = HplPXA27xDMAM.HplPXA27xDMAChnl[24];
  HplPXA27xDMAChnl[25] = HplPXA27xDMAM.HplPXA27xDMAChnl[25];
  HplPXA27xDMAChnl[26] = HplPXA27xDMAM.HplPXA27xDMAChnl[26];
  HplPXA27xDMAChnl[27] = HplPXA27xDMAM.HplPXA27xDMAChnl[27];
  HplPXA27xDMAChnl[28] = HplPXA27xDMAM.HplPXA27xDMAChnl[28];
  HplPXA27xDMAChnl[29] = HplPXA27xDMAM.HplPXA27xDMAChnl[29];
  HplPXA27xDMAChnl[30] = HplPXA27xDMAM.HplPXA27xDMAChnl[30];
  HplPXA27xDMAChnl[31] = HplPXA27xDMAM.HplPXA27xDMAChnl[31];

  HplPXA27xDMAM.Init <- PlatformP.InitL1;

  HplPXA27xDMAM.DMAIrq -> HplPXA27xInterruptM.PXA27xIrq[PPID_DMAC];
 
}
