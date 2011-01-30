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

interface HplSam3uDmaChannel {

  async command error_t setSrcAddr(void* src_addr);
  async command error_t setDstAddr(void* dst_addr);

  async command error_t setCtrlA(uint16_t btsize, dmac_chunk_t scsize, dmac_chunk_t dcsize, dmac_width_t src_width, dmac_width_t dst_width);

  async command uint32_t setBtsize(uint16_t btsize);
  async command error_t setCtrlB(dmac_dscr_t src_dscr, dmac_dscr_t dst_dscr, dmac_fc_t fc, dmac_inc_t src_inc, dmac_inc_t dst_inc);

  async command error_t setCfg(uint8_t src_per, uint8_t dst_per, bool srcSwHandshake,
			 bool dstSwHandshake, bool stopOnDone, bool lockIF,
			 bool lockB, dmac_IFL_t lockIFL, dmac_ahbprot_t ahbprot,
			 dmac_fifocfg_t fifocfg);
  async command void enable();
  async command void disable();
  async command void enableChannel(uint8_t channel);
  async command void disableChannel(uint8_t channel);
  async command void enableChannelInterrupt(uint8_t channel);
  async command void disableChannelInterrupt(uint8_t channel);
  async command void enableTransferRequest(uint8_t channel, bool s2d);
  async command bool getChannelStatus(uint8_t channel);
  async command void suspendChannel(uint8_t channel);

  async event void transferDone(error_t success);

}
