// $Id: OneWireMaster.nc,v 1.1 2008-10-31 17:02:55 sallai Exp $
/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
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
