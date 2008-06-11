/* $Id: HplPXA27xUART.nc,v 1.5 2008-06-11 00:42:13 razvanm Exp $ */
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
 * Interface to access UART peripheral register on the PXA27x. Function 
 * names are based on the common portion of the names outlined in
 * the PXA27x Developers Guide.
 * 
 * @author Phil Buonadonna
 */

interface HplPXA27xUART
{
  async command uint32_t getRBR();
  async command void setTHR(uint32_t val);

  async command void setDLL(uint32_t val);
  async command uint32_t getDLL();

  async command void setDLH(uint32_t val);
  async command uint32_t getDLH();

  async command void setIER(uint32_t val);
  async command uint32_t getIER();

  async command uint32_t getIIR();

  async command void setFCR(uint32_t val);

  async command void setLCR(uint32_t val);
  async command uint32_t getLCR();

  async command void setMCR(uint32_t val);
  async command uint32_t getMCR();

  async command uint32_t getLSR();

  async command uint32_t getMSR();

  async command void setSPR(uint32_t val);
  async command uint32_t getSPR();

  async command void setISR(uint32_t val);
  async command uint32_t getISR();

  async command void setFOR(uint32_t val);
  async command uint32_t getFOR();

  async command void setABR(uint32_t val);
  async command uint32_t getABR();

  async command uint32_t getACR();

  async event void interruptUART();
}
