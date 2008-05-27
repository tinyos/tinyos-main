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

module dmaArrayM{
    provides interface dmaArray;
}

implementation
{
	  async command uint32_t dmaArray.array_getBaseIndex(DescArray *DAPtr)
	  {
	    uint32_t addr = (uint32_t) (&DAPtr->data[0]);
	    return DescArray_BYTE_ALLIGNMENT - (addr % DescArray_BYTE_ALLIGNMENT);
	  }
	  
	  async command DMADescriptor_t* dmaArray.array_get(DescArray *DAPtr, uint8_t descIndex)
	  {
	    uint32_t baseIndex = call dmaArray.array_getBaseIndex(DAPtr);
	    return (DMADescriptor_t*)&DAPtr->data[baseIndex + descIndex*sizeof(DMADescriptor_t)];
	  }

    command void dmaArray.init(DescArray *DAPtr, 
    														uint32_t num_bytes, 
    														uint32_t sourceAddr, 
    														void *buf)
    {
        uint8_t i = 0;
        DMADescriptor_t* descPtr = NULL;
        //was: uint32_t bytesLeftToSchedule = nbrBytesToTransfer;
        uint32_t bytesLeftToSchedule = num_bytes;
        uint32_t image_data = (uint32_t) buf;

        for (i = 0; bytesLeftToSchedule > 0; ++i) {
            descPtr = call dmaArray.array_get(DAPtr, i);

            call dmaArray.setSourceAddr(descPtr, sourceAddr);
            //was: call dmaArray.setTargetAddr(descPtr, &image.data[ i*(MAX_DESC_TRANSFER/4) ]);
            call dmaArray.setTargetAddr(descPtr, image_data + i*MAX_DESC_TRANSFER ); 
            call dmaArray.enableSourceAddrIncrement(descPtr, FALSE);
            call dmaArray.enableTargetAddrIncrement(descPtr, TRUE);
            call dmaArray.enableSourceFlowControl(descPtr, TRUE);
            call dmaArray.enableTargetFlowControl(descPtr, FALSE);
            call dmaArray.setMaxBurstSize(descPtr, 3);      // burst size: can be 8, 16, or 32 bytes
            call dmaArray.setTransferWidth(descPtr, 3);     // peripheral width for DMA transactions from CIF is always 8-bytes, regardless of DCMD[WIDTH]
            
            if (bytesLeftToSchedule >= MAX_DESC_TRANSFER) {
                call dmaArray.setTransferLength(descPtr, MAX_DESC_TRANSFER);  // 16*8 *2 =256 bytes // must be an integer multiple of 8-bytes
                bytesLeftToSchedule -= MAX_DESC_TRANSFER;
            }
            else {
                call dmaArray.setTransferLength(descPtr, bytesLeftToSchedule);
                bytesLeftToSchedule = 0;
            }

            // continue running the next descriptor
            descPtr->DDADR = (uint32_t)call dmaArray.array_get(DAPtr, i+1);
        }

        // Set the stop bit for the last descriptor
        descPtr->DDADR |= DDADR_STOP;
    }

    command void dmaArray.setSourceAddr(DMADescriptor_t* descPtr, uint32_t val)
    {
        atomic{ descPtr->DSADR = val; }
    }

    command void dmaArray.setTargetAddr(DMADescriptor_t* descPtr, uint32_t val)
    {
        atomic{ descPtr->DTADR = val; }
    }
    
    command void dmaArray.enableSourceAddrIncrement(DMADescriptor_t* descPtr, bool enable)
    {
        atomic{ descPtr->DCMD = (enable == TRUE) ? descPtr->DCMD | DCMD_INCSRCADDR : descPtr->DCMD & ~DCMD_INCSRCADDR; }
    }

    command void dmaArray.enableTargetAddrIncrement(DMADescriptor_t* descPtr, bool enable)
    {
        atomic{ descPtr->DCMD = (enable == TRUE) ? descPtr->DCMD | DCMD_INCTRGADDR : descPtr->DCMD & ~DCMD_INCTRGADDR; }
    }

    command void dmaArray.enableSourceFlowControl(DMADescriptor_t* descPtr, bool enable)
    {
        atomic{descPtr->DCMD = (enable == TRUE) ? descPtr->DCMD | DCMD_FLOWSRC : descPtr->DCMD & ~DCMD_FLOWSRC;}
    }
  
    command void dmaArray.enableTargetFlowControl(DMADescriptor_t* descPtr, bool enable)
    {
        atomic{descPtr->DCMD = (enable == TRUE) ? descPtr->DCMD | DCMD_FLOWTRG : descPtr->DCMD & ~DCMD_FLOWTRG;}
    } 
  
    command void dmaArray.setMaxBurstSize(DMADescriptor_t* descPtr, DMAMaxBurstSize_t size)
    {
				if(size >= DMA_BURST_SIZE_8BYTES && size <= DMA_BURST_SIZE_32BYTES){
        //if(size >= DMA_BURST_SIZE_8BYTES && size <= DMA_BURST_SIZE_32BYTES){
            atomic{
              //clear it out since otherwise |'ing doesn't work so well
              descPtr->DCMD &= ~DCMD_MAXSIZE;  
              descPtr->DCMD |= DCMD_SIZE(size); 
            }
        }        
    }
  
    command void dmaArray.setTransferLength(DMADescriptor_t* descPtr, uint16_t length)
    {
        uint16_t currentLength;
        currentLength = (length < MAX_DESC_TRANSFER) ? length : MAX_DESC_TRANSFER;
				//was: currentLength = (length<8192) ? length: 8190;
        atomic{
            descPtr->DCMD &= ~DCMD_MAXLEN; 
            descPtr->DCMD |= DCMD_LEN(currentLength); 
        }
    }
  
    command void dmaArray.setTransferWidth(DMADescriptor_t* descPtr, DMATransferWidth_t width)
    {
        atomic{
          //clear it out since otherwise |'ing doesn't work so well
          descPtr->DCMD &= ~DCMD_MAXWIDTH; 
          descPtr->DCMD |= DCMD_WIDTH(width);
      }        
    }

}
