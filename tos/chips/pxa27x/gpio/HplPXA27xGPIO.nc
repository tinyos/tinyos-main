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
 * This interface provides direct access to the PXA27x GPIO controller 
 * registers. It is meant as an alternative to the 'per-pin' interface 
 * where the pin abstraction may not be convienient. The event provided is
 * called at every signal of the underlying first-level interrupt component
 * and NOT on a per-pin basis.
 * 
 * Commands in this interface are named according to the following scheme:
 *    set<regname>(uint32_t val);
 *    get<regname>();
 * where <regname> is the register as defined in the PXA27x Developers 
 * Guide: General-Purpose IO Controller.
 *
 * This interface is NOT intended to be parameterized.
 *
 * @author Phil Buonadonna
 */

interface HplPXA27xGPIO
{

  async command void setGPLR0(uint32_t val);
  async command uint32_t getGPLR0();
  async command void setGPLR1(uint32_t val);
  async command uint32_t getGPLR1();
  async command void setGPLR2(uint32_t val);
  async command uint32_t getGPLR2();
  async command void setGPLR3(uint32_t val);
  async command uint32_t getGPLR3();

  async command void setGPDR0(uint32_t val);
  async command uint32_t getGPDR0();
  async command void setGPDR1(uint32_t val);
  async command uint32_t getGPDR1();
  async command void setGPDR2(uint32_t val);
  async command uint32_t getGPDR2();
  async command void setGPDR3(uint32_t val);
  async command uint32_t getGPDR3();

  async command void setGPSR0(uint32_t val);
  async command uint32_t getGPSR0();
  async command void setGPSR1(uint32_t val);
  async command uint32_t getGPSR1();
  async command void setGPSR2(uint32_t val);
  async command uint32_t getGPSR2();
  async command void setGPSR3(uint32_t val);
  async command uint32_t getGPSR3();

  async command void setGPCR0(uint32_t val);
  async command uint32_t getGPCR0();
  async command void setGPCR1(uint32_t val);
  async command uint32_t getGPCR1();
  async command void setGPCR2(uint32_t val);
  async command uint32_t getGPCR2();
  async command void setGPCR3(uint32_t val);
  async command uint32_t getGPCR3();

  async command void setGRER0(uint32_t val);
  async command uint32_t getGRER0();
  async command void setGRER1(uint32_t val);
  async command uint32_t getGRER1();
  async command void setGRER2(uint32_t val);
  async command uint32_t getGRER2();
  async command void setGRER3(uint32_t val);
  async command uint32_t getGRER3();
 
  async command void setGFER0(uint32_t val);
  async command uint32_t getGFER0();
  async command void setGFER1(uint32_t val);
  async command uint32_t getGFER1();
  async command void setGFER2(uint32_t val);
  async command uint32_t getGFER2();
  async command void setGFER3(uint32_t val);
  async command uint32_t getGFER3();
 
  async command void setGEDR0(uint32_t val);
  async command uint32_t getGEDR0();
  async command void setGEDR1(uint32_t val);
  async command uint32_t getGEDR1();
  async command void setGEDR2(uint32_t val);
  async command uint32_t getGEDR2();
  async command void setGEDR3(uint32_t val);
  async command uint32_t getGEDR3();
 
  async command void setGAFR0_L(uint32_t val);
  async command uint32_t getGAFR0_L();
  async command void setGAFR0_U(uint32_t val);
  async command uint32_t getGAFR0_U();
  async command void setGAFR1_L(uint32_t val);
  async command uint32_t getGAFR1_L();
  async command void setGAFR1_U(uint32_t val);
  async command uint32_t getGAFR1_U();
  async command void setGAFR2_L(uint32_t val);
  async command uint32_t getGAFR2_L();
  async command void setGAFR2_U(uint32_t val);
  async command uint32_t getGAFR2_U();
  async command void setGAFR3_L(uint32_t val);
  async command uint32_t getGAFR3_L();
  async command void setGAFR3_U(uint32_t val);
  async command uint32_t getGAFR3_U();
 
  async event void fired();
}
