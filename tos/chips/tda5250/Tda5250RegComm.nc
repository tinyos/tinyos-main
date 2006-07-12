/*
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 */

/**
 * Interface for writing and reading bytes to and from the Tda5250 Radio
 * registers.
 *
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 */
interface Tda5250RegComm {
 /**
   * Transmit a byte of data to a given register.
   *
   * @param address The address of the register to write to.
   * @param data The 8-bit data value to write to the register.
   *
   * @return always SUCCESS.
   */
  async command error_t writeByte(uint8_t address, uint8_t data);

 /**
   * Transmit a word of data to a given register.
   *
   * @param address The address of the register to write to.
   * @param data The 16-bit data value to write to the register.
   *
   * @return always SUCCESS.
   */
  async command error_t writeWord(uint8_t address, uint16_t data);

 /**
   * Read a byte of data from a given register.
   *
   * @param address The address of the register to read from.
   *
   * @return The 16-bit data value read from the register.
   */
  async command uint8_t readByte(uint8_t address);
}

