/*
 * Copyright (c) 2016 Eric B. Decker
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
 *
 * @author Eric B. Decker <cire831@gmail.com>
 */

#include <msp432usci.h>

module UsciConfP {
  provides {
    interface Msp432UsciConfigure as UartConf;
    interface Msp432UsciConfigure as I2CConf;
    interface Msp432UsciConfigure as MasterConf;
    interface Msp432UsciConfigure as SlaveConf;
  }
}
implementation {

  const msp432_usci_config_t uart_config = {
    ctlw0 : EUSCI_A_CTLW0_SSEL__SMCLK,
    brw   : 109,
    mctlw : (0 << EUSCI_A_MCTLW_BRF_OFS) |
            (2 << EUSCI_A_MCTLW_BRS_OFS),
    i2coa : 0
  };

#ifndef MSP430_I2C_DIVISOR
#define MSP430_I2C_DIVISOR 80
#endif

  const msp432_usci_config_t i2c_config = {
    ctlw0 : EUSCI_B_CTLW0_SYNC     | EUSCI_B_CTLW0_MODE_3 |
            MSP432_I2C_MASTER_MODE | EUSCI_B_CTLW0_SSEL__SMCLK,
    brw   : MSP430_I2C_DIVISOR,		/* SMCLK/div */
              				/* 8*10^6/div -> 100,000 Hz */
    mctlw : 0,
    i2coa : 0x41,
  };


  /*
   * PH, data captured on first UCLK edge, changed on falling
   * pl, inactive low
   * uclk <- smclk/2 (4Mhz), master, 8 bit, 3 wire spi (mode 0),
   */
  const msp432_usci_config_t master_config = {
    ctlw0 : (EUSCI_B_CTLW0_CKPH        | EUSCI_B_CTLW0_MSB  |
             EUSCI_B_CTLW0_MST         | EUSCI_B_CTLW0_SYNC |
             EUSCI_B_CTLW0_SSEL__SMCLK),
    brw   : 2,                  /* 8MHz/2 -> 4 MHz */
    mctlw : 0,                  /* Always 0 in SPI mode */
    i2coa : 0
  };

  /*
   * PH, data captured on first UCLK edge, changed on falling
   * pl, inactive low, SSEL doesn't matter (leave 0, reserved)
   * slave, 8 bit, 3 wire spi (mode 0).
   */
  const msp432_usci_config_t slave_config = {
    ctlw0 : (EUSCI_B_CTLW0_CKPH        | EUSCI_B_CTLW0_MSB  |
             EUSCI_B_CTLW0_SYNC),
    brw   : 2,
    mctlw : 0,
    i2coa : 0
  };

  async command const msp432_usci_config_t *UartConf.getConfiguration() {
    return &uart_config;
  }

  async command const msp432_usci_config_t *I2CConf.getConfiguration() {
    return &i2c_config;
  }

  async command const msp432_usci_config_t *MasterConf.getConfiguration() {
    return &master_config;
  }

  async command const msp432_usci_config_t *SlaveConf.getConfiguration() {
    return &slave_config;
  }

}
