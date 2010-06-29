// $Id: OneWireMaster.nc,v 1.2 2010-06-29 22:07:45 scipio Exp $
/*
 * Copyright (c) 2007, Vanderbilt University
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
 * Author: Janos Sallai
 */

/**
 * Interface to interact with 1-wire bus devices, as a master on the 1-wire
 * bus.
 */
interface OneWireMaster {
  /**
   * Initialize bus (pin is input with pullup).
   */
  async command void idle();
  /**
   * Initialize bus, start sourcing current (pin is input with pullup).
   */
  async command void init();
  /**
   * Release bus, stop sourcing current (pin is three-stated input).
   */
  async command void release();
  /**
   * Generate reset signal.
   * @returns SUCCESS if a client is present, an error_t error value otherwise.
   */
  async command error_t reset();
  /**
   * Write bit 1 to the bus.
   */
  async command void writeOne();
  /**
   * Write bit 0 to the bus.
   */
  async command void writeZero();
  /**
   * Write 8 bits to the bus, LSB first.
   * @param b the byte to write.
   */
  async command void writeByte(uint8_t b);
  /**
   * Read a bit from the bus.
   */
  async command bool readBit();
  /**
   * Read 8 bits from the bus, LSB first.
   * @returns the byte read.
   */
  async command uint8_t readByte();
}
