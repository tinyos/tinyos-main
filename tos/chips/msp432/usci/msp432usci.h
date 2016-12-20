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
 *
 * Support the msp432 version of the eUSCI for the TI MSP432P401{m,r}
 * (see TI MSP432P4xx Family Technical Reference Manual slau356).
 *
 * msp432:  __MCU_HAS_EUSCI_A0__
 *          __MCU_HAS_EUSCI_A1__
 *          __MCU_HAS_EUSCI_A2__
 *          __MCU_HAS_EUSCI_A3__
 *          __MCU_HAS_EUSCI_B0__
 *          __MCU_HAS_EUSCI_B1__
 *          __MCU_HAS_EUSCI_B2__
 *          __MCU_HAS_EUSCI_B3__
 *
 * The eUSCI is effectively the same as the USCI used on the msp430f5438a.
 * The differences between eUSCI and USCIs are documented in SLAA522A,
 * "Migrating from the USCI Module to the eUSCI Module".
 *
 * There is confusion about max SPI speed.
 *   SPI up to 16MHz, main msp432p401r page
 *   up to 12MHz, data sheet Vcore0
 *   up to 24MHz, data sheet Vcore1
 *
 * When master, max clock 12MHz (Vcore0)?  Max input when slave?
 * Vcore0/Vcore1: 12MHz/24MHz.
 */

#ifndef __MSP432USCI_H__
#define __MSP432USCI_H__

#include <msp432.h>

/*
 * TI defines every possible different way of defining the same thing
 * without having it be different, even though the bit positions are
 * the same.  See msp432/usci/00_README for details.
 *
 * We redefine them to reflect that they are indeed the same bits
 * and work correctly across modules.
 *
 * We redefine only those that we use and have verified.
 */
enum {
  MSP432U_STAT_BUSY   = EUSCI_A_STATW_BUSY,
  MSP432U_STAT_PE     = EUSCI_A_STATW_PE,
  MSP432U_STAT_OE     = EUSCI_A_STATW_OE,
  MSP432U_STAT_FE     = EUSCI_A_STATW_FE,

  MSP432U_IFG_RX      = EUSCI_A_IFG_RXIFG,
  MSP432U_IFG_TX      = EUSCI_A_IFG_TXIFG,
};


/*
 * The USCIs use an IV register to indicate which interrupt source
 * is the highest priority.  When IV is read by the interrupt handler
 * it clears the h/w IFG flag.
 *
 * MSP432U_IV_<what>: MSP432 Usci Vector ID
 */
enum {
  MSP432U_IV_NONE       = 0,    /* none */
  MSP432U_IV_RXIFG      = 2,    /* rxifg, rxbuf full  */
  MSP432U_IV_TXIFG      = 4,    /* txifg, txbuf empty */
  MSP432U_IV_STTIFG     = 6,    /* start bit          */
  MSP432U_IV_TXCPTIFG   = 8,    /* tx complete        */

  MSP432U_IV_I2C_AL     = 2,    /* arbitration lost   */
  MSP432U_IV_I2C_NACK   = 4,    /* nack               */
  MSP432U_IV_I2C_STT    = 6,    /* start              */
  MSP432U_IV_I2C_STP    = 8,    /* stop               */
  MSP432U_IV_I2C_RX3    = 10,   /* rxifg 3            */
  MSP432U_IV_I2C_TX3    = 12,   /* txifg 3            */
  MSP432U_IV_I2C_RX2    = 14,   /* rxifg 2            */
  MSP432U_IV_I2C_TX2    = 16,   /* txifg 2            */
  MSP432U_IV_I2C_RX1    = 18,   /* rxifg 1            */
  MSP432U_IV_I2C_TX1    = 20,   /* txifg 1            */
  MSP432U_IV_I2C_RX0    = 22,   /* rxifg 0            */
  MSP432U_IV_I2C_TX0    = 24,   /* txifg 0            */
  MSP432U_IV_I2C_BCNT   = 26,   /* byte counter       */
  MSP432U_IV_I2C_CLTO   = 28,   /* clock low time out */
  MSP432U_IV_I2C_BIT9   = 30,   /* bit 9 int          */
};


/* MSP432_USCI_RESOURCE is used for USCI_IDs */
#define MSP432_USCI_RESOURCE "Msp432Usci.Resource"

#define MSP432_USCI_A0_RESOURCE "Msp432Usci.A0.Resource"
#define MSP432_USCI_A1_RESOURCE "Msp432Usci.A1.Resource"
#define MSP432_USCI_A2_RESOURCE "Msp432Usci.A2.Resource"
#define MSP432_USCI_A3_RESOURCE "Msp432Usci.A3.Resource"
#define MSP432_USCI_B0_RESOURCE "Msp432Usci.B0.Resource"
#define MSP432_USCI_B1_RESOURCE "Msp432Usci.B1.Resource"
#define MSP432_USCI_B2_RESOURCE "Msp432Usci.B2.Resource"
#define MSP432_USCI_B3_RESOURCE "Msp432Usci.B3.Resource"

typedef enum {
  MSP432_USCI_NONE = 0,
  MSP432_USCI_UART,
  MSP432_USCI_SPI,
  MSP432_USCI_SPI_SLAVE,
  MSP432_USCI_I2C,
} msp432_usci_mode_t;

#ifndef MSP432_I2C_MASTER_MODE
/*
 * default to Master.
 *
 * MM turns on multi-master mode, see i2c-mm/
 *
 * EUSCI_B_CTLW0_MM or EUSCI_B_CTLW0_MST
 */
#define MSP432_I2C_MASTER_MODE EUSCI_B_CTLW0_MST
#endif


#ifndef MSP432_I2C_DIVISOR
#define MSP432_I2C_DIVISOR 10
#endif


/*
 * Errors that can be kicked out from the USCI h/w
 */
enum {
  MSP432U_ERR_PARITY  = MSP432U_STAT_PE,
  MSP432U_ERR_OVERRUN = MSP432U_STAT_OE,
  MSP432U_ERR_FRAMING = MSP432U_STAT_FE,
  MSP432U_ERR_MASK    = MSP432U_STAT_PE | MSP432U_STAT_OE | MSP432U_STAT_FE,
};

/**
 * Aggregates basic configuration registers for an MSP432 USCI.
 * These are specifically the registers common to all configurations.
 * Mode-specific configuration data should be provided elsewise.
 *
 * According to the TRM (slau356E), pg 760, sec 23.3.6, A SPIs should
 * 0 MCTLW.  I don't think it matters, but screw it, zero the bugger.
 * This needs to happen when the structure is defined by the user!
 */
typedef struct msp432_usci_config_t {
  uint16_t ctlw0;			/* various control bits, msb */
                                        /* clock select and swreset, lsb */
  uint16_t brw;				/* divider/prescaler */
  uint16_t mctlw;
  uint16_t i2coa;
} msp432_usci_config_t;

#endif          /* __MSP432USCI_H__ */
