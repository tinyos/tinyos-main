/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/*
 * "Copyright (c) 2000-2005 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * @author Ben Greenstein <ben@cs.ucla.edu>
 * @author Jonathan Hui <jhui@archrock.com>
 * @author Joe Polastre <info@moteiv.com>
 * @version $Revision: 1.5 $ $Date: 2008-04-17 22:38:34 $
 */

module HplMsp430DmaP {

  provides interface HplMsp430DmaControl as DmaControl;
  provides interface HplMsp430DmaInterrupt as Interrupt;
  uses interface HplMsp430InterruptSig as SIGNAL_DACDMA_VECTOR;
}

implementation {

  MSP430REG_NORACE( DMACTL0 );
  MSP430REG_NORACE( DMACTL1 );

  inline async event void SIGNAL_DACDMA_VECTOR.fired {
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

