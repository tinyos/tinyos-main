//$Id: BitVector.nc,v 1.5 2010-06-29 22:07:46 scipio Exp $

/* Copyright (c) 2000-2003 The Regents of the University of California.  
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
 * - Neither the name of the copyright holder nor the names of
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

