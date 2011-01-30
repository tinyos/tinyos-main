/*
 * Copyright (c) 2009 Johns Hopkins University.
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
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author JeongGil Ko
 */

#include "sam3uDmahardware.h"

generic module Sam3uDmaChannelP() {
  provides interface Sam3uDmaChannel as Channel;
  uses interface HplSam3uDmaChannel as DmaChannel;
}

implementation {

  async command error_t Channel.setupTransfer( uint8_t channel,
					       void *src_addr,
					       void *dst_addr,
					       uint16_t btsize,
					       dmac_chunk_t scsize,
					       dmac_chunk_t dcsize,
					       dmac_width_t src_width,
					       dmac_width_t dst_width,
					       dmac_dscr_t src_dscr,
					       dmac_dscr_t dst_dscr,
					       dmac_fc_t fc,
					       dmac_inc_t src_inc,
					       dmac_inc_t dst_inc,
					       uint8_t src_per,
					       uint8_t dst_per,
					       bool srcSwHandshake,
					       bool dstSwHandshake,
					       bool stopOnDone,
					       bool lockIF,
					       bool lockB,
					       dmac_IFL_t lockIFL,
					       dmac_ahbprot_t ahbprot,
					       dmac_fifocfg_t fifocfg)
  {
    call DmaChannel.enable();
    call DmaChannel.disableChannelInterrupt(channel);
    call DmaChannel.setSrcAddr(src_addr);
    call DmaChannel.setDstAddr(dst_addr);
    call DmaChannel.setCtrlA(btsize, scsize, dcsize, src_width, dst_width);
    call DmaChannel.setCtrlB(src_dscr, dst_dscr, fc, src_inc, dst_inc);
    call DmaChannel.setCfg(src_per, dst_per, srcSwHandshake,
			   dstSwHandshake, stopOnDone, lockIF,
			   lockB, lockIFL, ahbprot,
			   fifocfg);
    return SUCCESS;
  }

  async command error_t Channel.startTransfer(uint8_t channel)
  {
    call DmaChannel.enable();
    call DmaChannel.enableChannelInterrupt(channel);
    call DmaChannel.enableChannel(channel);
    return SUCCESS;
  }

  async command error_t Channel.repeatTransfer( void *src_addr, void *dst_addr, uint16_t size, uint8_t channel)
  {
    call DmaChannel.setBtsize(size);
    call DmaChannel.enable();
    call DmaChannel.enableChannelInterrupt(channel);
    call DmaChannel.enableChannel(channel);
    return SUCCESS;
  }

  async command error_t Channel.swTransferRequest(uint8_t channel, bool s2d)
  {
    // Only used for peripheral transmissions and not for memory-memory transfers
    call DmaChannel.enableTransferRequest(channel, s2d);
    return SUCCESS;
  }

  async command error_t Channel.stopTransfer(uint8_t channel)
  {
    if(call DmaChannel.getChannelStatus(channel)){
      call DmaChannel.suspendChannel(channel);
    }
    call DmaChannel.disableChannel(channel);
  }

  async command error_t Channel.resetAll(uint8_t channel)
  {
    call DmaChannel.enable();
    call DmaChannel.disableChannelInterrupt(channel);
    call DmaChannel.setSrcAddr(0);
    call DmaChannel.setDstAddr(0);
    call DmaChannel.setCtrlA(0, 0, 0, 0, 0);
    call DmaChannel.setCtrlB(0, 0, 0, 0, 0);
    call DmaChannel.setCfg(0, 0, 0, 0, 0,
			   0, 0, 0, 1, 0);
    call DmaChannel.disable();
    return SUCCESS;
  }

  async event void DmaChannel.transferDone(error_t success){
    signal Channel.transferDone(success);
  }

  default async event void Channel.transferDone(error_t success){
  }

}
