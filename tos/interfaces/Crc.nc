/*                                                                      
 *
 * Copyright (c) 2000-2007 The Regents of the University of
 * California.  All rights reserved.
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
 *
 */

/**
 * Compute the CRC-16 value of a byte array.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @author David Moss
 */
interface Crc {

  /**
   * Compute the CRC-16 value of a byte array.
   *
   * @param   'void* COUNT(len) buf' A pointer to the buffer over which to compute CRC.
   * @param   len The length of the buffer over which to compute CRC.
   * @return  The CRC-16 value.
   */
  async command uint16_t crc16(void* buf, uint8_t len);
  
  /**
   * Compute a generic CRC-16 using a given seed.  Used to compute CRC's
   * of discontinuous data.
   * 
   * @param startCrc An initial CRC value to begin with
   * @param 'void* COUNT(len) buf' A pointer to a buffer of data
   * @param len The length of the buffer
   * @return The CRC-16 value.
   */
  async command uint16_t seededCrc16(uint16_t startCrc, void *buf, uint8_t len);
  
}
