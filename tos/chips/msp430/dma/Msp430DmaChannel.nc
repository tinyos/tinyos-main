/*
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
 * @author Joe Polastre <info@moteiv.com>
 * @version $Revision: 1.5 $ $Date: 2010-06-29 22:07:45 $
 */

#include "Msp430Dma.h"

interface Msp430DmaChannel {

  /**
   * Setup a transfer using explicit argument (most robust and simple
   * mechanism and recommended for novice users)
   *
   * See MSP430DMA.h for parameter options
   */
  async command error_t setupTransfer( dma_transfer_mode_t transfer_mode, 
				       dma_trigger_t trigger, 
				       dma_level_t level,
				       void *src_addr, 
				       void *dst_addr, 
				       uint16_t size,
				       dma_byte_t src_byte, 
				       dma_byte_t dst_byte,
				       dma_incr_t src_incr, 
				       dma_incr_t dst_incr );
  
  /**
   * Raw interface for setting up a DMA transfer.  This function is
   * intended to provide as much raw performance as possible but
   * sacrifices type checking in the process.  Recommended ONLY for
   * advanced users that have very intricate knowledge of the MSP430
   * DMA module described in the user's guide.
   *
   * @param state The control register value, as specified by 
   *              dma_control_state_t in MSP430DMA.h
   * @param trigger The trigger for the DMA transfer.  Should be one
   *                of the options from dma_trigger_t in MSP430DMA.h
   * @param src Pointer to the source address
   * @param dest Pointer to the destination address
   * @param size Size of the DMA transfer
   *
   * See MSP430DMA.h for parameter options
   */
  async command void setupTransferRaw( uint16_t state, uint16_t trigger,
				       void* src, void* dest, int size );

  /**
   * Enable the DMA module.  Equivalent to setting the DMA enable bit.
   * This function does not force a transfer.
   */
  async command error_t startTransfer();

  /**
   * Repeat a DMA transfer using previous settings but new pointers
   * and transfer size.  Automatically starts the transfer (sets the
   * enable bit).
   */
  async command error_t repeatTransfer( void *src_addr, void *dst_addr, 
					uint16_t size );

  /**
   * Trigger a DMA transfer using software
   */
  async command error_t softwareTrigger();

  /**
   * Stop a DMA transfer in progress
   */
  async command error_t stopTransfer();

  /**
   * Notification that the transfer has completed
   */
  async event void transferDone(error_t success);

}
