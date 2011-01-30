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

interface Sam3uDmaChannel {

  async command error_t setupTransfer( uint8_t channel,
				       void *src_addr, /* Source Address */
				       void *dst_addr, /* Destination Address */
				       uint16_t btsize, /* Size of buffer transfer */
				       dmac_chunk_t scsize, /* Source chunk transfer size -- details in header file */
				       dmac_chunk_t dcsize, /* Destination chunk transfer size -- details in header file */
				       dmac_width_t src_width, /* details in header file */
				       dmac_width_t dst_width, /* details in header file */
				       dmac_dscr_t src_dscr, /* Source address descripter method */
				       dmac_dscr_t dst_dscr, /* Destination address descripter method */
				       dmac_fc_t fc, /* Flow Controller -- deatils in header file */
				       dmac_inc_t src_inc, /* Source addressing mode */
				       dmac_inc_t dst_inc, /* Source addressing mode */ 
				       uint8_t src_per, /* Handshake peripheral, for HW handshakes -- 4 bits */
				       uint8_t dst_per, /* Handshake peripheral, for HW handshakes -- 4 bits */
				       bool srcSwHandshake, /* select sw handshake for source */
				       bool dstSwHandshake, /* select sw handshake for destination */
				       bool stopOnDone, /* DMAC disable upon done signal */
				       bool lockIF, /* Interface lock capability */
				       bool lockB, /* AHB Bus lock capability */
				       dmac_IFL_t lockIFL, /* Master interface locked by channel for chunk/buffer trasfer -- details in header file */
				       dmac_ahbprot_t ahbprot, /* Additional info on bus access -- deatils in header file */
				       dmac_fifocfg_t fifocfg /* Configure FIFO -- Details in header file */ 
				       );

  async command error_t startTransfer(uint8_t channel); /* set enable bit */

  async command error_t repeatTransfer( void *src_addr, void *dst_addr, 
					uint16_t size, uint8_t channel); /* repeat trasfer with the previous settings */

  async command error_t swTransferRequest(uint8_t channel, bool s2d); /* set source or destination tranfer request for channel */

  async command error_t stopTransfer(uint8_t channel); /* Perform all fuctions needed to disable/stop transfer*/

  async command error_t resetAll(uint8_t channel);

  async event void transferDone(error_t success);

}
