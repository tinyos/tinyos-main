/*
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
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
