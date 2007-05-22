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
