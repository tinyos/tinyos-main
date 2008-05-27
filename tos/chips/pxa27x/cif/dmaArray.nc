/*
 * Copyright (c) 2005 Yale University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials provided
 *    with the distribution.
 * 3. All advertising materials mentioning features or use of this
 *    software must display the following acknowledgement:
 *       This product includes software developed by the Embedded Networks
 *       and Applications Lab (ENALAB) at Yale University.
 * 4. Neither the name of the University nor that of the Laboratory
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY YALE UNIVERSITY AND CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS
 * OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
 * USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 * OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 */ 
 /**
 * @brief dma array operations
 * @author Andrew Barton-Sweeney (abs@cs.yale.edu)
 * @author Thiago Teixeira
 */
 /**                                         
 * Modified and ported to tinyos-2.x.
 * 
 * @author Brano Kusy (branislav.kusy@gmail.com)
 * @version October 25, 2007
 */
#include "DMA.h"

interface dmaArray{
	async command uint32_t array_getBaseIndex(DescArray *DAPtr);
	async command DMADescriptor_t* array_get(DescArray *DAPtr, uint8_t descIndex);
	command void init(DescArray *DAPtr, uint32_t num_bytes, uint32_t sourceAddr, void *buf);
	command void setSourceAddr(DMADescriptor_t* descPtr, uint32_t val);
	command void setTargetAddr(DMADescriptor_t* descPtr, uint32_t val);
	command void enableSourceAddrIncrement(DMADescriptor_t* descPtr, bool enable);
	command void enableTargetAddrIncrement(DMADescriptor_t* descPtr, bool enable);
	command void enableSourceFlowControl(DMADescriptor_t* descPtr, bool enable);
	command void enableTargetFlowControl(DMADescriptor_t* descPtr, bool enable);
	command void setMaxBurstSize(DMADescriptor_t* descPtr, DMAMaxBurstSize_t size);
	command void setTransferLength(DMADescriptor_t* descPtr, uint16_t length);
	command void setTransferWidth(DMADescriptor_t* descPtr, DMATransferWidth_t width);
}
