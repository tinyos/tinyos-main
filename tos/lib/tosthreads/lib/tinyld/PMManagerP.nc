/*
 * Copyright (c) 2008 Johns Hopkins University.
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
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

module PMManagerP {
  provides {
    interface Init;
    interface PMManager;
  }
  
  uses {
    interface BitArrayUtils;
    interface Leds;
  }
}

implementation {
  uint16_t HOST_ROM_SIZE = 0;   // Set by tos-set-symbol
  uint16_t SEGMENT_SIZE = 512;   // For telosb, the internal flash segment size is 512 bytes
  uint16_t FLASH_ROM_START_ADDR = 0x4000;   // For telosb, the program memory starts at 0x4000
  uint16_t FLASH_ROM_END_ADDR = 0xFDFF;   // Last free byte (the last segment is used for interrupt vector)
  
  uint16_t numFreeSegments = 0;
  uint8_t *segmentBitArray;
  
  command error_t Init.init()
  {
    uint16_t numBytes;
    
    // Adjust FLASH_ROM_START_ADDR to account for the code loaded with PMManager
    if (HOST_ROM_SIZE == 0) {
      // Should not be here at all
      // return FAIL;
    } else {
      FLASH_ROM_START_ADDR += (((HOST_ROM_SIZE - 1) / SEGMENT_SIZE) + 1) * SEGMENT_SIZE;
    }
    
    // Calculates the number of available segments
    numFreeSegments = FLASH_ROM_END_ADDR - FLASH_ROM_START_ADDR + 1;
    numFreeSegments = ((numFreeSegments - 1) / SEGMENT_SIZE) + 1;
    
    // Initializes an bit array to track the status of available segments
    numBytes = ((numFreeSegments - 1) / 8) + 1;
    segmentBitArray = malloc(numBytes);
    call BitArrayUtils.clrArray(segmentBitArray, numBytes);
    
    return SUCCESS;
  }
  
  uint16_t bitIndexToAddress(uint16_t bitIndex)
  {
    return FLASH_ROM_START_ADDR + (bitIndex * SEGMENT_SIZE);
  }

  void eraseSegment(void* addr)
  {
    FCTL2 = FWKEY + FSSEL1 + FN2;
    FCTL3 = FWKEY;
    FCTL1 = FWKEY + ERASE;
    *((uint16_t *)addr) = 0;
    FCTL1 = FWKEY;
    FCTL3 = FWKEY + LOCK;
  }

  command uint16_t PMManager.request(uint16_t size)
  {    
    if (size > 0) {
      uint8_t numSegments = ((size - 1) / SEGMENT_SIZE) + 1;   // Number of segments needed to cover size
      int i;
      
      for (i = (numFreeSegments - 1); i >= 0; i--) {
        if (call BitArrayUtils.getBit(segmentBitArray, i) == FALSE) {
          int j, tempNumSegments = numSegments - 1;
          
          for (j = (i - 1); j >= 0 && tempNumSegments > 0; ) {
            // Checks if there are enough consecutive free segments
            if (call BitArrayUtils.getBit(segmentBitArray, j) == TRUE) {
              break;
            } else {
              j--;
              tempNumSegments--;
            }
          }
          j++;
          if ((i - j + 1) >= numSegments) {
            // There are enough consecutive free segments (starting segment index (j + 1))
            int k;
            for (k = j; k <= i; k++) {
              eraseSegment((void *)bitIndexToAddress(k));   // Erase segment content
              call BitArrayUtils.setBit(segmentBitArray, k);   // Mark segment as occupied
            }
            
            return bitIndexToAddress(j);
          } else {
            i = j;
          }
        }
      }
    }
    
    return 0xFFFF;
  }
  
  command void PMManager.release(uint16_t startingAddr, uint16_t size)
  {
    if ((startingAddr >= FLASH_ROM_START_ADDR && startingAddr <= FLASH_ROM_END_ADDR) &&
        size > 0) {
      uint8_t numSegments = ((size - 1) / SEGMENT_SIZE) + 1;   // Number of segments needed to cover size
      uint8_t startingSegment = (startingAddr - FLASH_ROM_START_ADDR) / SEGMENT_SIZE;
      int i;
      
      for (i = 0; i < numSegments && (i + startingSegment) < numFreeSegments; i++) {
        call BitArrayUtils.clrBit(segmentBitArray, i + startingSegment);   // Mark the segment as free
      }
    }
  }
}
