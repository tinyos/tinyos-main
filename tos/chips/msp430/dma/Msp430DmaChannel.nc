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
 * @author Joe Polastre <info@moteiv.com>
 * @version $Revision: 1.4 $ $Date: 2006-12-12 18:23:07 $
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
