/*
 * Copyright (c) 2012 Eric B. Decker
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
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
 * I2CReg: interface to simple I2C devices with registers.
 * single phase, run to completion.
 *
 * @author Eric B. Decker <cire831@gmail.com>
 */

#include <I2C.h>

interface I2CReg {
  /*
   * slave_present: check to see if a device is on the bus
   *
   * input:	slave_addr to probe
   * output:	RETURN
   *		  0	slave not home
   *		  1	slave has responded.
   */
  async command bool slave_present(uint16_t slave_addr);

  /*
   * reg_read{,16}:	read byte (or word) from an i2c device register
   *
   * Uses register symantics, will first address the register.
   *
   * input:	slave_addr
   *		reg		8 bit register to address
   *		*val		pointer to 8 (or 16) bit val
   *				read value returned here.
   *
   * RETURNS:	SUCCESS		yum
   *		ETIMEOUT	operation would timeout.
   */
  async command error_t reg_read(uint16_t slave_addr, uint8_t reg, uint8_t *val);
  async command error_t reg_read16(uint16_t slave_addr, uint8_t reg, uint16_t *val);

  /*
   * reg_readBlock: read block of data from the device registers.
   *
   * Starting with reg, read a block of data from the device (ie. a register block)
   *
   * input:	slave_addr
   *		reg		8 bit register to address
   *		*buf		where to put the data.
   *
   * RETURNS:	SUCCESS		yum
   *		ETIMEOUT	operation would timeout.
   */
  async command error_t reg_readBlock(uint16_t slave_addr, uint8_t reg, uint8_t num_bytes, uint8_t *buf);

  /*
   * reg_write{,16}:	write byte (or word) from an i2c device register
   *
   * Uses register symantics, will first address the register.
   *
   * input:	slave_addr
   *		reg		8 bit register to address
   *		val		8 (or 16) bit val to write.
   *
   * RETURNS:	SUCCESS		yum
   *		ETIMEOUT	operation would timeout.
   */
  async command error_t reg_write(uint16_t slave_addr, uint8_t reg, uint8_t val);
  async command error_t reg_write16(uint16_t slave_addr, uint8_t reg, uint16_t val);

  /*
   * reg_writeBlock: write block of data to the device registers.
   *
   * Starting with reg, write a block of data to the device (ie. a register block)
   *
   * input:	slave_addr
   *		reg		8 bit register to address
   *		*buf		data to stuff
   *
   * RETURNS:	SUCCESS		yum
   *		ETIMEOUT	operation would timeout.
   */
  async command error_t reg_writeBlock(uint16_t slave_addr, uint8_t reg, uint8_t num_bytes, uint8_t *buf);

}
