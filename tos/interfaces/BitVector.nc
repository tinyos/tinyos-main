//$Id: BitVector.nc,v 1.3 2006-11-07 19:31:17 scipio Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
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
 * Interface to a bit vector.
 *
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 */

interface BitVector
{
  /**
   * Clear all bits in the vector.
   */
  async command void clearAll();

  /**
   * Set all bits in the vector.
   */
  async command void setAll();

  /**
   * Read a bit from the vector.
   * @param bitnum Bit to read.
   * @return Bit value.
   */
  async command bool get(uint16_t bitnum);

  /**
   * Set a bit in the vector.
   * @param bitnum Bit to set.
   */
  async command void set(uint16_t bitnum);

  /**
   * Set a bit in the vector.
   * @param bitnum Bit to clear.
   */
  async command void clear(uint16_t bitnum);

  /**
   * Toggle a bit in the vector.
   * @param bitnum Bit to toggle.
   */
  async command void toggle(uint16_t bitnum);

  /**
   * Write a bit in the vector.
   * @param bitnum Bit to clear.
   * @param value New bit value.
   */
  async command void assign(uint16_t bitnum, bool value);

  /**
   * Return bit vector length.
   * @return Bit vector length.
   */
  async command uint16_t size();
}

