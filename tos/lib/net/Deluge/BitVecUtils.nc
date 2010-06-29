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

interface BitVecUtils {
  /**
   * Locates the index of the first '1' bit in a bit vector.
   *
   * @param result     the location of the '1' bit
   * @param fromIndex  the index to start search for '1' bit
   * @param bitVec     the bit vector
   * @param length     the length of the bit vector in bits
   * @return           <code>SUCCESS</code> if a '1' bit was found;
   *                   <code>FAIL</code> otherwise.
   */
  command error_t indexOf(uint16_t* pResult, uint16_t fromIndex, 
			   uint8_t* bitVec, uint16_t length);

  /**
   * Counts the number of '1' bits in a bit vector.
   *
   * @param result  the number of '1' bits
   * @param bitVec  the bit vector
   * @param length  the length of the bit vector in bits
   * @return        <code>SUCCESS</code> if the operation completed successfully;
   *                <code>FAIL</code> otherwise.
   */
  command error_t countOnes(uint16_t* pResult, uint8_t* bitVec, 
			     uint16_t length);

  /**
   * Generates an ASCII representation of the bit vector.
   *
   * @param buf     the character array to place the ASCII string
   * @param bitVec  the bit vector
   * @param length  the length of the bit vector in bits
   */
  command void printBitVec(char* buf, uint8_t* bitVec, uint16_t length);
}
