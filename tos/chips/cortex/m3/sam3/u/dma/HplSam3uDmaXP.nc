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

generic module HplSam3uDmaXP(uint8_t DMACHANNEL) {

  provides interface HplSam3uDmaChannel as Dma;
  uses interface HplSam3uDmaInterrupt as Interrupt;
  uses interface Leds;
}

implementation {

  uint32_t CHANNEL_OFFSET = 0x3C + (DMACHANNEL * 0x28);

  async event void Interrupt.fired(){
    // Disable channel and send signal up
    call Dma.disableChannel(DMACHANNEL);
    call Dma.disableChannelInterrupt(DMACHANNEL);
    call Dma.disable();
    signal Dma.transferDone(SUCCESS);
  }

  async command error_t Dma.setSrcAddr(void* src_addr){
    volatile dmac_saddrx_t *SADDRX = (volatile dmac_saddrx_t *)(0x400B0000 + CHANNEL_OFFSET);
    dmac_saddrx_t saddrxx;
    saddrxx.bits.saddrx = (uint32_t) src_addr;
    *SADDRX = saddrxx;
    return SUCCESS;
  }

  async command error_t Dma.setDstAddr(void* dst_addr){
    volatile dmac_daddrx_t *DADDRX = (volatile dmac_daddrx_t *)(0x400B0004 + CHANNEL_OFFSET);
    dmac_daddrx_t daddrxx;
    daddrxx.bits.daddrx = (uint32_t) dst_addr;
    *DADDRX = daddrxx;
    return SUCCESS;
  }

  async command error_t Dma.setCtrlA(uint16_t btsize, dmac_chunk_t scsize, dmac_chunk_t dcsize, dmac_width_t src_width, dmac_width_t dst_width){
    volatile dmac_ctrlax_t *CTRLAX = (volatile dmac_ctrlax_t *)(0x400B000C + CHANNEL_OFFSET);
    dmac_ctrlax_t ctrlax = *CTRLAX;
    ctrlax.bits.btsize = btsize;
    ctrlax.bits.scsize = scsize;
    ctrlax.bits.dcsize = dcsize;
    ctrlax.bits.src_width = src_width;
    ctrlax.bits.dst_width = dst_width;
    *CTRLAX = ctrlax;
    return SUCCESS;
  }

  async command error_t Dma.setCtrlB(dmac_dscr_t src_dscr, dmac_dscr_t dst_dscr, dmac_fc_t fc, dmac_inc_t src_inc, dmac_inc_t dst_inc){
    volatile dmac_ctrlbx_t *CTRLBX = (volatile dmac_ctrlbx_t *)(0x400B0010 + CHANNEL_OFFSET);
    dmac_ctrlbx_t ctrlbx = *CTRLBX;
    ctrlbx.bits.src_dscr = src_dscr;
    ctrlbx.bits.dst_dscr = dst_dscr;
    ctrlbx.bits.fc = fc;
    ctrlbx.bits.src_incr = src_inc;
    ctrlbx.bits.dst_incr = dst_inc;
    *CTRLBX = ctrlbx;
    return SUCCESS;
  }

  async command uint32_t Dma.setBtsize(uint16_t btsize){
    volatile dmac_ctrlax_t *CTRLAX = (volatile dmac_ctrlax_t *)(0x400B000C + CHANNEL_OFFSET);
    dmac_ctrlax_t ctrlax = *CTRLAX;
    ctrlax.bits.btsize = btsize;
    *CTRLAX = ctrlax;
    return (0x400B000C + CHANNEL_OFFSET);
  }

  async command error_t Dma.setCfg(uint8_t src_per, uint8_t dst_per, bool srcSwHandshake,
		  bool dstSwHandshake, bool stopOnDone, bool lockIF,
		  bool lockB, dmac_IFL_t lockIFL, dmac_ahbprot_t ahbprot,
		  dmac_fifocfg_t fifocfg){
    volatile dmac_cfgx_t *CFGX = (volatile dmac_cfgx_t *)(0x400B0014 + CHANNEL_OFFSET);
    dmac_cfgx_t cfgx = *CFGX;
    cfgx.bits.src_per = src_per;
    cfgx.bits.dst_per = dst_per;
    cfgx.bits.src_h2sel = !srcSwHandshake;
    cfgx.bits.dst_h2sel = !dstSwHandshake;
    cfgx.bits.sod = stopOnDone;
    cfgx.bits.lock_if = lockIF;
    cfgx.bits.lock_b = lockB;
    cfgx.bits.lock_if_l = lockIFL;
    cfgx.bits.ahb_prot = ahbprot;
    cfgx.bits.fifocfg = fifocfg;
    *CFGX = cfgx;
    return SUCCESS;
  }

  async command void Dma.enable(){
    volatile dmac_en_t *EN = (volatile dmac_en_t *) 0x400B0004;
    dmac_en_t en = *EN;
    en.bits.enable = 1;
    *EN = en;
  }

  async command void Dma.disable(){
    volatile dmac_en_t *EN = (volatile dmac_en_t *) 0x400B0004;
    dmac_en_t en = *EN;
    en.bits.enable = 0;
    *EN = en;
  }

  async command void Dma.enableChannel(uint8_t channel){
    volatile dmac_cher_t *CHER = (volatile dmac_cher_t *) 0x400B0028;
    dmac_cher_t cher;

    switch(DMACHANNEL){
    case 0:
      cher.bits.ena0 = 1;
      break;
    case 1:
      cher.bits.ena1 = 1;
      break;
    case 2:
      cher.bits.ena2 = 1;
      break;
    case 3:
      cher.bits.ena3 = 1;
      break;
    default:
      cher.bits.ena0 = 1;
      break;
    }
    *CHER = cher;
  }

  async command void Dma.disableChannel(uint8_t channel){
    volatile dmac_chdr_t *CHDR = (volatile dmac_chdr_t *) 0x400B002C;
    dmac_chdr_t chdr;

    switch(DMACHANNEL){
    case 0:
      chdr.bits.dis0 = 1;
      break;
    case 1:
      chdr.bits.dis1 = 1;
      break;
    case 2:
      chdr.bits.dis2 = 1;
      break;
    case 3:
      chdr.bits.dis3 = 1;
      break;
    default:
      chdr.bits.dis0 = 1;
      break;
    }
    *CHDR = chdr;
  }


  async command void Dma.enableTransferRequest(uint8_t channel, bool s2d){
    volatile dmac_sreq_t *SREQ = (volatile dmac_sreq_t *) 0x400B0008;
    dmac_sreq_t sreq = *SREQ;
    volatile dmac_last_t *LAST = (volatile dmac_last_t *) 0x400B0010;
    dmac_last_t last = *LAST;
    volatile dmac_creq_t *CREQ = (volatile dmac_creq_t *) 0x400B000C;
    dmac_creq_t creq = *CREQ;

    switch(DMACHANNEL){
    case 0:
      if(s2d){
	last.bits.slast0 = 1;
	sreq.bits.ssreq0 = 1;
      }else{
	last.bits.dlast0 = 1;
	sreq.bits.dsreq0 = 1;
      }
      break;
    case 1:
      if(s2d){
	sreq.bits.ssreq1 = 1;
	last.bits.slast1 = 1;
      }else{
	sreq.bits.dsreq1 = 1;
	last.bits.dlast1 = 1;
      }
      break;
    case 2:
      if(s2d){
	sreq.bits.ssreq2dash = 1;
	last.bits.slast2 = 1;
      }else{
	sreq.bits.dsreq2dash = 1;
	last.bits.dlast2 = 1;
      }
      break;
    case 3:
      if(s2d){
	sreq.bits.ssreq3 = 1;
	last.bits.slast3 = 1;
      }else{
	sreq.bits.dsreq3 = 1;
	last.bits.slast3 = 1;
      }
      break;
    default:
      if(s2d){
	sreq.bits.ssreq0 = 1;
	last.bits.slast0 = 1;
      }else{
	sreq.bits.dsreq0 = 1;
	last.bits.dlast0 = 1;
      }
      break;
    }
    *LAST = last;
    *CREQ = creq;
    *SREQ = sreq;
  }


  async command void Dma.enableChannelInterrupt(uint8_t channel){
    volatile dmac_ebcier_t *EBCIER = (volatile dmac_ebcier_t *) 0x400B0018;
    dmac_ebcier_t ebcier;// = *EBCIER;
    switch(DMACHANNEL){
    case 0:    
      ebcier.bits.btc0 = 1;
      //ebcier.bits.err0 = 1;
      break;
    case 1:    
      ebcier.bits.btc1 = 1;
      //ebcier.bits.err1 = 1;
      break;
    case 2:    
      ebcier.bits.btc2 = 1;
      //ebcier.bits.err2 = 1;
      break;
    case 3:    
      ebcier.bits.btc3 = 1;
      //ebcier.bits.err3 = 1;
      break;
    }
    *EBCIER = ebcier;
  }


  async command void Dma.disableChannelInterrupt(uint8_t channel){
    volatile dmac_ebcidr_t *EBCIDR = (volatile dmac_ebcidr_t *) 0x400B001C;
    dmac_ebcidr_t ebcidr;// = *EBCIER;
    switch(DMACHANNEL){
    case 0:
      ebcidr.bits.btc0 = 1;
      //ebcier.bits.err0 = 1;
      break;
    case 1:
      ebcidr.bits.btc1 = 1;
      //ebcier.bits.err1 = 1;
      break;
    case 2:
      ebcidr.bits.btc2 = 1;
      //ebcier.bits.err2 = 1;
      break;
    case 3:
      ebcidr.bits.btc3 = 1;
      //ebcier.bits.err3 = 1;
      break;
    }
    *EBCIDR = ebcidr;
  }

  async command bool Dma.getChannelStatus(uint8_t channel){
    volatile dmac_chsr_t *CHSR = (volatile dmac_chsr_t *) 0x400B0030;

    switch(DMACHANNEL){
    case 0:
      return CHSR->bits.ena0;
    case 1:
      return CHSR->bits.ena1;
    case 2:
      return CHSR->bits.ena2;
    case 3:
      return CHSR->bits.ena3;
    default:
      return CHSR->bits.ena0;
    }
  }

  async command void Dma.suspendChannel(uint8_t channel){
    volatile dmac_cher_t *CHER = (volatile dmac_cher_t *) 0x400B0028;
    dmac_cher_t cher;

    switch(DMACHANNEL){
    case 0:
      cher.bits.susp0 = 1;
      break;
    case 1:
      cher.bits.susp1 = 1;
      break;
    case 2:
      cher.bits.susp2 = 1;
      break;
    case 3:
      cher.bits.susp3 = 1;
      break;
    default:
      cher.bits.susp0 = 1;
      break;
    }
    *CHER = cher;
  }
}
