/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * Copyright (c) 2000-2005 The Regents of the University of California.  
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

/**
 * @author Ben Greenstein <ben@cs.ucla.edu>
 * @author Jonathan Hui <jhui@archrock.com>
 * @author Joe Polastre <info@moteiv.com>
 * @version $Revision: 1.5 $ $Date: 2010-06-29 22:07:45 $
 */

#include "Msp430Dma.h"

generic module Msp430DmaChannelP() {

  provides interface Msp430DmaChannel as Channel;
  uses interface HplMsp430DmaChannel as HplChannel;

}

implementation {

  norace dma_channel_state_t gChannelState;
  norace dma_channel_trigger_t gChannelTrigger;
  
  async command void Channel.setupTransferRaw( uint16_t s, uint16_t t, 
					       void* src, void* dest, 
					       int size ) {
    call HplChannel.setStateRaw( s, t, src, dest, size );
  }
  
  async command error_t Channel.setupTransfer( dma_transfer_mode_t transfer_mode, 
					   dma_trigger_t trigger, 
					   dma_level_t level,
					   void *src_addr, 
					   void *dst_addr, 
					   uint16_t size,
					   dma_byte_t src_byte, 
					   dma_byte_t dst_byte,
					   dma_incr_t src_incr, 
					   dma_incr_t dst_incr ) {
    
    gChannelState.request = 0;
    gChannelState.abort = 0;
    gChannelState.interruptEnable = 1;
    gChannelState.interruptFlag = 0;
    gChannelState.enable = 0;          /* don't start an xfer */
    gChannelState.level = level;
    gChannelState.srcByte = src_byte;
    gChannelState.dstByte = dst_byte;
    gChannelState.srcIncrement = src_incr;
    gChannelState.dstIncrement = dst_incr;
    gChannelState.transferMode = transfer_mode;
    
    gChannelTrigger.trigger = trigger;
    
    call HplChannel.setState( gChannelState, gChannelTrigger,
			      src_addr, dst_addr, size );
    
    return SUCCESS;
    
  }
  
  async command error_t Channel.startTransfer() {
    call HplChannel.enableDMA();
    return SUCCESS;
  }
  
  async command error_t Channel.repeatTransfer( void *src_addr, 
						void *dst_addr, 
						uint16_t size ) {
    call HplChannel.setSrc( src_addr );
    call HplChannel.setDst(dst_addr);
    call HplChannel.setSize(size);
    call HplChannel.enableDMA();
    return SUCCESS;
  }
  
  async command error_t Channel.softwareTrigger() {
    if (gChannelTrigger.trigger != DMA_TRIGGER_DMAREQ) 
      return FAIL;
    call HplChannel.triggerDMA();
    return SUCCESS;
  }
  
  async command error_t Channel.stopTransfer() {
    if ( gChannelState.transferMode != DMA_BURST_BLOCK_TRANSFER ||
	 gChannelState.transferMode != DMA_REPEATED_BURST_BLOCK_TRANSFER)
      return FAIL;
    call HplChannel.disableDMA();
    return SUCCESS;
    
  }
  
  async event void HplChannel.transferDone( error_t error ) {
    signal Channel.transferDone( error );
  }

  default async event void Channel.transferDone( error_t error ) {}

}
