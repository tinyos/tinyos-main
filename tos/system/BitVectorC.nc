//$Id: BitVectorC.nc,v 1.6 2010-06-29 22:07:56 scipio Exp $

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
 * Generic bit vector implementation. Note that if you use this bit vector
 * from interrupt code, you must use appropriate <code>atomic</code>
 * statements to ensure atomicity.
 *
 * @param max_bits Bit vector length.
 *
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 */

generic module BitVectorC(uint16_t max_bits)
{
  provides interface Init;
  provides interface BitVector;
}
implementation
{
  typedef uint8_t int_type;

  enum
  {
    ELEMENT_SIZE = 8*sizeof(int_type),
    ARRAY_SIZE = (max_bits + ELEMENT_SIZE-1) / ELEMENT_SIZE,
  };

  int_type m_bits[ ARRAY_SIZE ];

  uint16_t getIndex(uint16_t bitnum)
  {
    return bitnum / ELEMENT_SIZE;
  }

  uint16_t getMask(uint16_t bitnum)
  {
    return 1 << (bitnum % ELEMENT_SIZE);
  }

  command error_t Init.init()
  {
    call BitVector.clearAll();
    return SUCCESS;
  }

  async command void BitVector.clearAll()
  {
    memset(m_bits, 0, sizeof(m_bits));
  }

  async command void BitVector.setAll()
  {
    memset(m_bits, 255, sizeof(m_bits));
  }

  async command bool BitVector.get(uint16_t bitnum)
  {
    atomic {return (m_bits[getIndex(bitnum)] & getMask(bitnum)) ? TRUE : FALSE;}
  }

  async command void BitVector.set(uint16_t bitnum)
  {
    atomic {m_bits[getIndex(bitnum)] |= getMask(bitnum);}
  }

  async command void BitVector.clear(uint16_t bitnum)
  {
    atomic {m_bits[getIndex(bitnum)] &= ~getMask(bitnum);}
  }

  async command void BitVector.toggle(uint16_t bitnum)
  {
    atomic {m_bits[getIndex(bitnum)] ^= getMask(bitnum);}
  }

  async command void BitVector.assign(uint16_t bitnum, bool value)
  {
    if(value)
      call BitVector.set(bitnum);
    else
      call BitVector.clear(bitnum);
  }

  async command uint16_t BitVector.size()
  {
    return max_bits;
  }
}

