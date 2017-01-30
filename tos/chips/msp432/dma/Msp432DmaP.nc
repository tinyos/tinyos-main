/*
 * Copyright (c) 2016-2017 Eric B. Decker
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * - Neither the name of the copyright holders nor the names of
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
 *
 * @author Eric B. Decker <cire831@gmail.com>
 */

/**
 * Core implementation for the MSP432 DMA hardware.
 */

#include <msp432dma.h>
#include <panic.h>

module Msp432DmaP {
  provides {
    interface Init;
    interface Msp432Dma as Dma[uint8_t chan];
  }
  uses interface Panic;
}
implementation {

  /*
   * m_dma_signal_enable is a bit mask per channel.  If a 1 any dma
   * channel completion interrupt will be signalled through to its
   * end point.
   *
   * The signal_enable will be set when the client calls dma_enable_int
   * and is disabled when dma_disable_int is called.
   */
  uint8_t m_dma_signal_enable;

  /*
   * 8 channels, each control block is 16 bytes * 8 * 2
   * one for the primary, one for the alternate, 256 bytes.
   * The control blocks have to be aligned on a 256 byte
   * boundary.
   */
  dma_cb_t ControlTable[16] __attribute__ ((aligned (0x100)));

  void dma_init(void * table) {
    BITBAND_PERI(DMA_Control->CFG, DMA_CFG_MASTEN_OFS) = 1;
    DMA_Control->CTLBASE = (uint32_t) table;
  }

  command error_t Init.init() {
    dma_init(ControlTable);
    return SUCCESS;
  }


  async command void Dma.dma_start_channel[uint8_t chan] (
        uint32_t trigger, uint32_t length,
        void * dst, void * src, uint32_t control) {

    dma_cb_t *cb;
    uint32_t src_inc, dst_inc;
    uint32_t nm1, mod;

    /*
     * check chan in range
     * chan already enabled ... bad
     * chan has pending interrupt ... bad
     */
    if ((chan >= 8) ||
        (DMA_Control->ENASET & (1 << chan)) ||
        (DMA_Channel->INT0_SRCFLG & (1 << chan))) {
      call Panic.panic(PANIC_DVR, 1, chan, 0, 0, 0);
    }

    dst_inc = (control & UDMA_CHCTL_DSTINC_M);
    src_inc = (control & UDMA_CHCTL_SRCINC_M);
    nm1 = length - 1;
    cb = &ControlTable[chan];
    DMA_Channel->CH_SRCCFG[chan] = trigger;
    cb->control = control | nm1 << 4;
    switch (dst_inc) {
      case UDMA_CHCTL_DSTINC_8:       mod = nm1;      break;
      case UDMA_CHCTL_DSTINC_16:      mod = nm1 << 1; break;
      case UDMA_CHCTL_DSTINC_32:      mod = nm1 << 2; break;
      default:
      case UDMA_CHCTL_DSTINC_NONE:    mod = 0;        break;
    }
    cb->dst_end = (uint32_t) dst + mod;

    switch (src_inc) {
      case UDMA_CHCTL_SRCINC_8:       mod = nm1;      break;
      case UDMA_CHCTL_SRCINC_16:      mod = nm1 << 1; break;
      case UDMA_CHCTL_SRCINC_32:      mod = nm1 << 2; break;
      default:
      case UDMA_CHCTL_SRCINC_NONE:    mod = 0;        break;
    }
    cb->src_end = (uint32_t) src + mod;
    DMA_Control->ENASET = 1 << chan;
  }

  /*
   * dma_set_priority: set priority of this channel
   *
   * pri: 0  set normal priority
   *      >0 set high priority
   */
  async command void Dma.dma_set_priority[uint8_t chan](uint32_t pri) {
    if (pri)
      DMA_Control->PRIOSET = 1 << chan;
    else
      DMA_Control->PRIOCLR = 1 << chan;
  }

  async command bool Dma.dma_complete[uint8_t chan]() {
    return !call Dma.dma_enabled[chan]();
  }


  async command void Dma.dma_stop_channel[uint8_t chan]() {
    DMA_Control->ENACLR = (1 << chan);
    DMA_Channel->INT0_CLRFLG = (1 << chan);
    atomic {
      if (DMA_Channel->INT0_SRCFLG == 0) {
        NVIC_ClearPendingIRQ(DMA_INT0_IRQn);
        if (DMA_Channel->INT0_SRCFLG)
          NVIC_SetPendingIRQ(DMA_INT0_IRQn);
      }
    }
    __DMB();
  }


  async command bool Dma.dma_enabled[uint8_t chan]() {
    if (DMA_Control->ENASET & 1 << chan)
      return TRUE;
    return FALSE;
  }


  async command void Dma.dma_enable_int[uint8_t chan]() {
    if (chan < 8) {
      BITBAND_SRAM(m_dma_signal_enable, chan) = 1;
      NVIC_EnableIRQ(DMA_INT0_IRQn);
    }
  }


  async command void Dma.dma_disable_int[uint8_t chan]() {
    if (chan < 8) {
      BITBAND_SRAM(m_dma_signal_enable, chan) = 0;
      if (m_dma_signal_enable == 0)
        NVIC_DisableIRQ(DMA_INT0_IRQn);
    }
  }


  async command void Dma.dma_clear_int[uint8_t chan]() {
    if (chan < 8) {
      DMA_Channel->INT0_CLRFLG = (1 << chan);
      atomic {
        if (DMA_Channel->INT0_SRCFLG == 0) {
          NVIC_ClearPendingIRQ(DMA_INT0_IRQn);
          if (DMA_Channel->INT0_SRCFLG)
            NVIC_SetPendingIRQ(DMA_INT0_IRQn);
        }
      }
    }
  }


  void DMA_INT0_Handler(void) @C() @hwevent() __attribute__((interrupt)) {
    uint32_t working_flags, which;

    which  = 0;
    working_flags = DMA_Channel->INT0_SRCFLG; /* which channels went? */
    while (working_flags) {
      if (working_flags & 1) {
        /* got one */
        DMA_Channel->INT0_CLRFLG = (1 << which);
        if (m_dma_signal_enable & (1 << which))
          signal Dma.dma_interrupted[which]();
      }
      which++;
      working_flags >>= 1;
    }
    if (DMA_Channel->INT0_SRCFLG == 0) {
      NVIC_ClearPendingIRQ(DMA_INT0_IRQn);
      if (DMA_Channel->INT0_SRCFLG)
        NVIC_SetPendingIRQ(DMA_INT0_IRQn);
    }
  }

  default async event void Dma.dma_interrupted[uint8_t chan]() {
    call Panic.panic(PANIC_DVR, 2, chan, 0, 0, 0);
  }

  async event void Panic.hook() { }
}
