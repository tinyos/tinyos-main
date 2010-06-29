/*
 * Copyright (c) 2000-2004 The Regents of the University  of California.  
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
 * - Neither the name of the University of California nor the names of
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
 * Provides generic methods for manipulating bit vectors.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

#include "BitVecUtils.h"

module BitVecUtilsC {
  provides interface BitVecUtils;
}

implementation {
  command error_t BitVecUtils.indexOf(uint16_t* pResult, uint16_t fromIndex, 
				                               uint8_t* bitVec, uint16_t length) {
    uint16_t i = fromIndex;

    if (length == 0)
      return FAIL;
    
    do {
      if (BITVEC_GET(bitVec, i)) {
        *pResult = i;
        return SUCCESS;
      }
      i = (i+1) % length;
    } while (i != fromIndex);
    
    return FAIL;
  }

  command error_t BitVecUtils.countOnes(uint16_t* pResult, uint8_t* bitVec, uint16_t length) {

    int count = 0;
    int i;

    for ( i = 0; i < length; i++ ) {
      if (BITVEC_GET(bitVec, i))
	count++;
    }

    *pResult = count;

    return SUCCESS;

  }

  command void BitVecUtils.printBitVec(char* buf, uint8_t* bitVec, uint16_t length) {
#ifdef PLATFORM_PC
    uint16_t i;
    
    dbg(DBG_TEMP, "");
    for ( i = 0; i < length; i++ ) {
      sprintf(buf++, "%d", !!BITVEC_GET(bitVec, i));
    }
#endif	  
  }

}
