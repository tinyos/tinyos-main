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
 * @author Mark Hays
 * @version $Revision: 1.6 $ $Date: 2008-06-23 20:25:15 $
 */

generic module HplMsp430DmaXP( uint16_t DMAxCTL_addr,
			       uint16_t DMAxSA_addr,
			       uint16_t DMAxDA_addr,
			       uint16_t DMAxSZ_addr,
			       uint16_t DMAxTSEL_mask,
			       uint16_t DMAxTSEL_shift ) @safe() {
  
  provides interface HplMsp430DmaChannel as DMA;
  uses interface HplMsp430DmaInterrupt as Interrupt;

}

implementation {

  MSP430REG_NORACE( DMACTL0 );

#define DMAxCTL (*(volatile TYPE_DMA0CTL*)DMAxCTL_addr)
#define DMAxSA (*(volatile TYPE_DMA0SA*)DMAxSA_addr)
#define DMAxDA (*(volatile TYPE_DMA0DA*)DMAxDA_addr)
#define DMAxSZ (*(volatile TYPE_DMA0SZ*)DMAxSZ_addr)

  async event void Interrupt.fired() {
    error_t error = ( DMAxCTL & DMAABORT ) ? FAIL : SUCCESS;
    if ( DMAxCTL & DMAIFG ) {
      DMAxCTL &= ~DMAIFG;
      DMAxCTL &= ~DMAABORT;
      signal DMA.transferDone( error );
    }
  }

  async error_t command DMA.setTrigger( dma_trigger_t trigger ) {

    if ( DMAxCTL & DMAEN )
      return FAIL;

    DMACTL0 = ( ( DMACTL0 & ~DMAxTSEL_mask ) |
		( ( trigger << DMAxTSEL_shift ) & DMAxTSEL_mask ) );

    return SUCCESS;

  }

  async command void DMA.clearTrigger() {
    DMACTL0 &= ~DMAxTSEL_mask;
  }

  async command void DMA.setSingleMode() {
    DMAxCTL &= ~( DMADT0 | DMADT1 | DMADT2 );
    DMAxCTL |= DMA_SINGLE_TRANSFER;
  }

  async command void DMA.setBlockMode() {
    DMAxCTL &= ~( DMADT0 | DMADT1 | DMADT2 );
    DMAxCTL |= DMA_BLOCK_TRANSFER;
  }

  async command void DMA.setBurstMode() {
    DMAxCTL &= ~( DMADT0 | DMADT1 | DMADT2 );
    DMAxCTL |= DMA_BURST_BLOCK_TRANSFER;
  }

  async command void DMA.setRepeatedSingleMode() {
    DMAxCTL &= ~( DMADT0 | DMADT1 | DMADT2 );
    DMAxCTL |= DMA_REPEATED_SINGLE_TRANSFER;
  }

  async command void DMA.setRepeatedBlockMode() {
    DMAxCTL &= ~( DMADT0 | DMADT1 | DMADT2 );
    DMAxCTL |= DMA_REPEATED_BLOCK_TRANSFER;
  }

  async command void DMA.setRepeatedBurstMode() {
    DMAxCTL &= ~( DMADT0 | DMADT1 | DMADT2 );
    DMAxCTL |= DMA_REPEATED_BURST_BLOCK_TRANSFER;
  }

  async command void DMA.setSrcNoIncrement() {
    DMAxCTL &= ~( DMASRCINCR0 | DMASRCINCR1 );
    DMAxCTL |= DMA_ADDRESS_UNCHANGED;
  }

  async command void DMA.setSrcDecrement() {
    DMAxCTL &= ~( DMASRCINCR0 | DMASRCINCR1 );
    DMAxCTL |= DMA_ADDRESS_DECREMENTED;
  }

  async command void DMA.setSrcIncrement() {
    DMAxCTL &= ~( DMASRCINCR0 | DMASRCINCR1 );
    DMAxCTL |= DMA_ADDRESS_INCREMENTED;
  }

  async command void DMA.setDstNoIncrement() {
    DMAxCTL &= ~( DMADSTINCR0 | DMADSTINCR1 );
    DMAxCTL |= DMA_ADDRESS_UNCHANGED;
  }          

  async command void DMA.setDstDecrement() {
    DMAxCTL &= ~( DMADSTINCR0 | DMADSTINCR1 );
    DMAxCTL |= DMA_ADDRESS_DECREMENTED;
  }

  async command void DMA.setDstIncrement() {
    DMAxCTL &= ~( DMADSTINCR0 | DMADSTINCR1 );
    DMAxCTL |= DMA_ADDRESS_INCREMENTED;
  }

  async command void DMA.setWordToWord() {
    DMAxCTL &= ~(DMASRCBYTE | DMADSTBYTE);
    DMAxCTL |= DMASWDW;
  }

  async command void DMA.setByteToWord() {
    DMAxCTL &= ~(DMASRCBYTE | DMADSTBYTE);
    DMAxCTL |= DMASBDW;
  }

  async command void DMA.setWordToByte() {
    DMAxCTL &= ~(DMASRCBYTE | DMADSTBYTE);
    DMAxCTL |= DMASWDB;
  }

  async command void DMA.setByteToByte() {
    DMAxCTL &= ~(DMASRCBYTE | DMADSTBYTE);
    DMAxCTL |= DMASBDB;
  }

  async command void DMA.setEdgeSensitive() {
    DMAxCTL &= ~DMALEVEL;
  }

  async command void DMA.setLevelSensitive() {
    DMAxCTL |= DMALEVEL;
  }

  async command void DMA.enableDMA() { 
    DMAxCTL |= DMAEN; 
  }

  async command void DMA.disableDMA() { 
    DMAxCTL &= ~DMAEN; 
  }

  async command void DMA.enableInterrupt() {
    DMAxCTL |= DMAIE;
  }

  async command void DMA.disableInterrupt() {
    DMAxCTL &= ~DMAIE;
  }

  async command bool DMA.interruptPending() {
    return !!( DMAxCTL & DMAIFG );
  }

  async command bool DMA.aborted() {
    return !!( DMAxCTL & DMAABORT );
  }
  
  async command void DMA.triggerDMA() { 
    DMAxCTL |= DMAREQ; 
  }
  
  async command void DMA.setSrc( void *saddr ) {
    DMAxSA = (uint16_t)saddr;
  }
  
  async command void DMA.setDst( void *daddr ) {
    DMAxDA = (uint16_t)daddr;
  }
  
  async command void DMA.setSize( uint16_t sz ) {
    DMAxSZ = sz;
  }

  async command void DMA.setState( dma_channel_state_t s, 
				   dma_channel_trigger_t t, 
				   void* src, void* dest, 
				   uint16_t size ) {
    call DMA.setStateRaw( *(uint16_t*)&s, *(uint16_t*)&t,
			  src, dest, size);
  }

  async command void DMA.setStateRaw( uint16_t s, uint16_t t, 
				      void* src, void* dest, 
				      uint16_t size ) {
    DMAxSA = (uint16_t)src;
    DMAxDA = (uint16_t)dest;
    DMAxSZ = size;
    call DMA.setTrigger((dma_trigger_t) t);
    DMAxCTL = s;
  }

  async command dma_channel_state_t DMA.getState() {
    dma_channel_state_t s = *(dma_channel_state_t*) &DMAxCTL;
    return s;
  }

  async command void* DMA.getSource() {
    return (void*)DMAxSA;
  }

  async command void* DMA.getDestination() {
    return (void*)DMAxDA;
  }

  async command uint16_t DMA.getSize() {
    return DMAxSZ;
  }

  async command dma_channel_trigger_t DMA.getTrigger() {
    dma_channel_trigger_t t;
    t.trigger = ( DMACTL0 & DMAxTSEL_mask ) >> DMAxTSEL_shift;
    return t;
  }

  async command void DMA.reset() {
    DMAxCTL = 0;
    DMAxSA = 0;
    DMAxDA = 0;
    DMAxSZ = 0;
  }
}

