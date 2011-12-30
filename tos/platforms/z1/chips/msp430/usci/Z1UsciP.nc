/*
 * Copyright (c) 2009 DEXMA SENSORS SL
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

/*
 * @author: Xavier Orduna <xorduna@dexmatech.com>
 * @author: Jordi Soucheiron <jsoucheiron@dexmatech.com>
 */

generic module Z1UsciP() {
  provides interface Msp430SpiConfigure[ uint8_t id ];
  provides interface Msp430I2CConfigure[ uint8_t id ];
}
implementation {

  msp430_spi_union_config_t msp430_spi_z1_config = { {
    ubr		: 2,			/* smclk/2   */
    ucmode	: 0,			/* 3 pin master, no ste */
    ucmst	: 1,
    uc7bit	: 0,			/* 8 bit */
    ucmsb	: 1,			/* msb first, compatible with msp430 usart */
    ucckpl	: 1,			/* inactive state low */
    ucckph	: 0,			/* data captured on rising, changed falling */
    ucssel	: 2,			/* smclk */
  } };

  async command msp430_spi_union_config_t* Msp430SpiConfigure.getConfig[uint8_t id]() {
    return (msp430_spi_union_config_t*) &msp430_spi_z1_config;
  }

  msp430_i2c_union_config_t msp430_i2c_z1_config = { {
    ucmode  : 3,			/* i2c mode */
    ucmst   : 1,			/* master */
    ucmm    : 0,			/* single master */
    ucsla10 : 0,			/* 7 bit slave */
    uca10   : 0,			/* 7 bit us */
    uctr    : 0,			/* rx mode to start */
    ucssel  : 2,			/* smclk */
    i2coa   : 1,			/* our address is 1 */
    ucgcen  : 1,			/* respond to general call */
    ubr     : 800,			/* smclk/2 */
  } };

  async command msp430_i2c_union_config_t* Msp430I2CConfigure.getConfig[uint8_t id]() {
    return (msp430_i2c_union_config_t *) &msp430_i2c_z1_config;
  }

}
