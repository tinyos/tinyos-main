/* $Id: HplPXA27xDMACntl.nc,v 1.3 2006-11-07 19:31:10 scipio Exp $ */
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
/*
 *
 * Authors:             Phil Buonadonna
 *
 */


interface HplPXA27xDMACntl
{
  async command void setDRCMR(uint8_t peripheral, uint8_t chnl);
  async command uint8_t getDRCMR(uint8_t peripheral);
  async command void setDALGN(uint32_t val);
  async command uint32_t getDALGN(uint32_t val);
  async command void setDPCSR(uint32_t val);
  async command uint32_t getDPSCR();
  async command void setDRQSR0(uint32_t val);
  async command uint32_t getDRQSR0();
  async command void setDRQSR1(uint32_t val);
  async command uint32_t getDRQSR1();
  async command void setDRQSR2(uint32_t val);
  async command uint32_t getDRQSR2();
  async command uint32_t getDINT();
  async command void setFLYCNFG(uint32_t val);
  async command uint32_t getFLYCNFG();
}
