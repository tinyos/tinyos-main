/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * Copyright (c) 2000-2005 The Regents of the University of California.  
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
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

/**
 * @author Ben Greenstein <ben@cs.ucla.edu>
 * @author Jonathan Hui <jhui@archrock.com>
 * @author Joe Polastre <info@moteiv.com>
 * @version $Revision: 1.8 $ $Date: 2010-06-29 22:07:45 $
 */

module HplMsp430DmaP {

  provides interface HplMsp430DmaControl as DmaControl;
  provides interface HplMsp430DmaInterrupt as Interrupt;

}

implementation {

  MSP430REG_NORACE( DMACTL0 );
  MSP430REG_NORACE( DMACTL1 );

  // X1 family share the same interrupt vector with DAC, X2 family has its own

  #if defined(DACDMA_VECTOR)
    #define XX_DMA_VECTOR_XX DACDMA_VECTOR
  #elif defined(DMA_VECTOR)
    #define XX_DMA_VECTOR_XX DMA_VECTOR
  #else
    #error "DMA VECTOR not defined for cpu selected"
  #endif

  TOSH_SIGNAL( XX_DMA_VECTOR_XX ) {
    signal Interrupt.fired();
  }

  async command void DmaControl.setOnFetch(){
    DMACTL1 |= DMAONFETCH;
  }

  async command void DmaControl.clearOnFetch(){
    DMACTL1 &= ~DMAONFETCH;
  }

  async command void DmaControl.setRoundRobin(){
    DMACTL1 |= ROUNDROBIN;
  }
  async command void DmaControl.clearRoundRobin(){
    DMACTL1 &= ~ROUNDROBIN;
  }

  async command void DmaControl.setENNMI(){
    DMACTL1 |= ENNMI;
  }

  async command void DmaControl.clearENNMI(){
    DMACTL1 &= ~ENNMI;
  }

  async command void DmaControl.setState(dma_state_t s){
    DMACTL1 = *(int*)&s;
  }

  async command dma_state_t DmaControl.getState(){
    dma_state_t s;
    s = *(dma_state_t*)&DMACTL1;
    return s;
  }

  async command void DmaControl.reset(){
    DMACTL0 = 0;
    DMACTL1 = 0;
  }

}

