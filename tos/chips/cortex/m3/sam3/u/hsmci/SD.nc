/*
 * Copyright (c) 2006, Intel Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * Interface for communciating with an SD card via a standard sd card slot.
 *
 * @author Steve Ayer
 * @author Konrad Lorincz
 * @date May 2006
 */                      

interface SD {
  /**
   * Returns the card size in bytes.
   *
   * @return the card size in bytes.
   */
  command uint32_t readCardSize();

  /**
   * Reads 512 bytes from the SD at sector and copies it to bufferPtr
   *
   * @param sector the sector on the SD card (in multiples of 512 bytes).
   * @param bufferPtr pointer to where the SD will copy the data to.  Must be 512 bytes.
   * @return <code>SUCCESS<code> if it was read successfully; <code>FAIL<code> otherwise
   */
  command error_t readBlock(const uint32_t sector, uint8_t * buffer);

  /**
   * Writes 512 bytes from the bufferPtr to the SD card
   *
   * @param sector the sector on the SD card (in multiples of 512 bytes
   *                       where to write the data to).
   * @param bufferPtr pointer to data to be added.  Must be 512 bytes.
   * @return <code>SUCCESS<code> if it was written successfully; <code>FAIL<code> otherwise
   */
  command error_t writeBlock(const uint32_t sector, uint8_t * buffer);

  /**
   * the device has control over the sd card
   */
  async event void available();     

  /**
   * the device has lost control of the sd and should cease 
   * attempts to talk to the card
   */
  async event void unavailable();
}
