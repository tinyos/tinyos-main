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
 */

/**
 * Control of the MSP432 DMA h/w
 *
 * @author Eric B. Decker <cire831@gmail.com>
 */

#include "msp432dma.h"

interface Msp432Dma {

  async command void dma_start_channel(
        uint32_t trigger, uint32_t length,
        void * dst, void * src, uint32_t control);

  /* priority for the channel.  The msp432 provides for
   * only two, normal and high.  0 is normal, 1 is high.
   */
  async command void dma_set_priority(uint32_t pri);

  async command bool dma_complete();
  async command void dma_stop_channel();
  async command bool dma_enabled();

  /*
   * dma_enable_int: enable dma interrupts for this channel
   *
   * If first channel to be enabled, also turns on the NVIC
   * entry for DMA_INT0.
   *
   * enables the signal from DMA completion.
   *
   * should be called prior to call dma_start_channel to avoid
   * potential race condition.
   */
  async command void dma_enable_int();

  /*
   * dma_disable_int: disable dma interrupts for this channel
   *
   * If last channel enabled, will also turn off NVIC entry for
   * DMA_INT0
   *
   * disables signal from DMA completion
   */
  async command void dma_disable_int();

  /*
   * clears any pending DMA_INT0 interrupt for this channel
   */
  async command void dma_clear_int();


  /*
   * signal from the DMA interrupt handler to the client.
   *
   * only occurs if the client has explicitly asked for dma interrupts
   * via dma_enable_int().
   */
  async event void dma_interrupted();
}
