// $Id: I2CPacket.nc,v 1.3 2006-11-07 19:31:17 scipio Exp $
/*
 * "Copyright (c) 2000-2005 The Regents of the University  of California.
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
 * I2C Packet/buffer interface for sending data over the I2C bus.
 * The address, length, and buffer must be specified.  The I2C bus then
 * has control of that buffer and returns it when the operation has
 * completed.  The I2CPacket interface supports master-mode communication
 * and provides for multiple repeated STARTs and multiple reads/writes 
 * within the same START transaction. 
 * The interface is typed according to the address size supported by 
 * the master hardware.  Masters capable of supporting extended (10-bit)
 * I2C addressing MUST export both types. Applications should use the 
 * smallest address size to ensure best portability.
 *
 * @param addr_size A type indicating the slave address size. Supported
 * values are TI2CExtdAddr (for 10-bit addressing) and TI2CBasicAddr (7-bit
 * addressing). 
 *
 * @author Joe Polastre
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * @author Jonathan Hui <jhui@archrock.com>
 * @author Phil Levis <pal@cs.stanford.edu>
 * Revision:  $Revision: 1.3 $
 */

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
   * @param addr The slave device address. Only used if I2C_START is set.
   * @param length Length, in bytes, to be read
   * @param data A point to a data buffer to read into
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
   * @param addr The slave device address. Only used if I2C_START is set.
   * @param length Length, in bytes, to be read
   * @param data A point to a data buffer to read into
   *
   * @return SUCCESS if bus available and request accepted. 
   */
  async command error_t write(i2c_flags_t flags, uint16_t addr, uint8_t length, uint8_t* data);

  /**
   * Notification that the read operation has completed
   *
   * @param addr The slave device address
   * @param length Length, in bytes, read
   * @param data Pointer to the received data buffer
   * @param success SUCCESS if transfer completed without error.
   */
  async event void readDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data);

  /**
   * Notification that the write operation has completed
   *
   * @param addr The slave device address
   * @param length Length, in bytes, written
   * @param data Pointer to the data buffer written
   * @param success SUCCESS if transfer completed without error.
   */
  async event void writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data);
}
