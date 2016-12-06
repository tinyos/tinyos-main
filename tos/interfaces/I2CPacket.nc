/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.
 * Copyright (c) 2012, Eric B. Decker
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
 */

/**
 * I2C Packet/buffer interface for sending data over the I2C bus.
 * The address, length, and buffer must be specified.  The I2C bus then
 * has control of that buffer and returns it when the operation has
 * completed.  The I2CPacket interface supports master-mode communication
 * and provides for multiple repeated STARTs and multiple reads/writes 
 * within the same START transaction.
 *
 * The interface is typed according to the address size supported by 
 * the master hardware.  Masters capable of supporting extended (10-bit)
 * I2C addressing MUST export both types (although there is no particular
 * reason why).  Applications should use the smallest address size to
 * ensure best portability.  Typical I2C chips only support 7 bit addresses.
 *
 * @param addr_size A type indicating the slave address size. Supported
 * values are TI2C10Bit (aka TI2CExtdAddr) and TI2C7Bit (aka TI2CBasicAddr).
 *
 * There is a significant amount of code that uses TI2CBasicAddr so
 * transitioning to TI2C7Bit is problematic.   At some point if we want
 * to spend the effort moving to TI2C7Bit would be reasonable.   In the
 * meantime just use TI2CBasicAddr keeping in mind that it really means
 * TI2C7Bit which hopefully you'll agree is a better more understandable
 * name.
 *
 * flags control how the driver handles the bus.
 *
 * A single transaction is specified with I2C_START and I2C_STOP.
 *
 * A repeated transaction is started with I2C_START. Repeated calls
 * to I2CPacket can be made, with the last call specifing I2C_STOP.
 * For correct operation, one must understand exactly how the h/w
 * behaves across these calls.  Double buffered h/w greatly impacts
 * how these multiple transactions function.
 *
 * The bus can be turned around by specifing another I2C_START in the
 * call without an intervening I2C_STOP.   I2C_STOP can be specified
 * on the same transaction of the final transaction.
 *
 * for example:  reading a register.
 *
 * Note: I2CPacket is split phase so has significant overhead and
 * the following code needs to be implemented using split phase
 * techniques.  I2CReg is a single phase, busy wait implementation.
 *
 * uint8_t reg_buf[1] = <register>;
 * uint8_t reg_data[2];
 * call I2CPacket.write(I2C_START, DEV_ADDR, 1, reg_buf);
 *        <-- I2CPacket.writeDone(...);
 * call I2CPacket.read(I2C_RESTART | I2C_STOP, DEV_ADDR, 2, reg_data);
 *        <-- I2CPacket.readDone(...);
 *
 * because there is no intervening I2C_STOP between the two calls, the
 * second call (read) will turn the bus around without releasing
 * arbitration.
 *
 * Normally, the bus is checked for busy prior to starting a transaction.
 * RESTART is needed to abort this check because the bus can very easily
 * be in a busy state left over from the previous transaction.
 *
 * @author Joe Polastre
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * @author Jonathan Hui <jhui@archrock.com>
 * @author Phil Levis <pal@cs.stanford.edu>
 * @author Eric B. Decker <cire831@gmail.com>
 */

#include <I2C.h>

interface I2CPacket<addr_size> {
  /**
   * Perform an I2C read operation
   *
   * @param flags Flags that may be logical ORed and defined by:
   *    I2C_START   - The START condition is transmitted at the beginning 
   *                   of the packet if set.
   *    I2C_STOP    - The STOP condition is transmitted at the end of the 
   *                   packet if set.
   *    I2C_ACK_END - ACK the last byte if set. Otherwise NACK last byte. This
   *                   flag cannot be used with the I2C_STOP flag.
   *    I2C_RESTART - restarting an I2C transaction (turn bus around).
   * @param addr The slave device address. Only used if I2C_START is set.
   * @param length Length, in bytes, to be read
   * @param 'uint8_t* COUNT(length) data' A point to a data buffer to read into
   *
   * @return SUCCESS if bus available and request accepted. 
   */
  async command error_t read(i2c_flags_t flags, uint16_t addr, uint8_t length, uint8_t* data);

  /**
   * Perform an I2C write operation
   *
   * @param flags Flags that may be logical ORed and defined by:
   *    I2C_START   - The START condition is transmitted at the beginning 
   *                   of the packet if set.
   *    I2C_STOP    - The STOP condition is transmitted at the end of the 
   *                   packet if set.
   *    I2C_RESTART - restarting an I2C transaction (turn bus around).
   * @param addr The slave device address. Only used if I2C_START is set.
   * @param length Length, in bytes, to be read
   * @param 'uint8_t* COUNT(length) data' A point to a data buffer to read into
   *
   * @return SUCCESS if bus available and request accepted. 
   */
  async command error_t write(i2c_flags_t flags, uint16_t addr, uint8_t length, uint8_t* data);

  /**
   * Notification that the read operation has completed
   *
   * @param addr The slave device address
   * @param length Length, in bytes, read
   * @param 'uint8_t* COUNT(length) data' Pointer to the received data buffer
   * @param success SUCCESS if transfer completed without error.
   */
  async event void readDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data);

  /**
   * Notification that the write operation has completed
   *
   * @param addr The slave device address
   * @param length Length, in bytes, written
   * @param 'uint8_t* COUNT(length) data' Pointer to the data buffer written
   * @param success SUCCESS if transfer completed without error.
   */
  async event void writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data);
}
