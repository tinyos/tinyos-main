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

/**
 * Core implementation for any USCI module present on an MSP432 chip.
 *
 * This module makes available the module-specific registers, along
 * with a small number of higher-level functions like generic USCI
 * chip configuration that are shared among the various modes of the
 * module.
 *
 * Also note that many of the fields in various registers shouldn't be
 * set unless the device (that is the module) is in reset.
 *
 * We look at the h/w as one unit.  That is there is the core USCI h/w
 * coupled with the interrupt system.  The upper level driver attaches
 * through interface exported by this module.  That is why interrupts
 * for the driver flow through wiring in this module.
 *
 * This is a dedicated (non-arbitrated) implementation.  Later if we add
 * arbitration, this (interrupt flow through here) also allows us to
 * direct the interrupt to the appropriate arbited client.
 *
 * Platform wiring:  The platform needs to provide appropriate wiring
 * before a particular port can be
 *
 * Initilization and Platform
 *
 * When arbitrated, Resource and ResourceConfigure handle initilization
 * the device by calling the appropriate pieces of this driver.
 */

#include "msp432usci.h"

/*
 * eUsci port address, unique id, and type (A: 0, B: 1)
 */
generic module HplMsp432UsciP(uint32_t up, uint32_t irqn, uint8_t USCI_ID, uint8_t _t) {
  provides {
    interface HplMsp432Usci       as Usci;
    interface HplMsp432UsciInt    as Interrupt;
  }
  uses interface HplMsp432UsciInt as RawInterrupt;
}
implementation {

#define APTR(x) ((EUSCI_A_Type *)(x))
#define BPTR(x) ((EUSCI_B_Type *)(x))

  async command uint16_t Usci.getModuleIdentifier()  { return USCI_ID; }

  async command uint16_t Usci.getCtlw0() {
    if (_t) return BPTR(up)->CTLW0;
    else    return APTR(up)->CTLW0;
  }

  async command void     Usci.setCtlw0(uint16_t v) {
    if (_t) BPTR(up)->CTLW0 = v;
    else    APTR(up)->CTLW0 = v;
  }

  async command void     Usci.orCtlw0(uint16_t v) {
    if (_t) atomic { BPTR(up)->CTLW0 |= v; }
    else    atomic { APTR(up)->CTLW0 |= v; }
  }

  async command void     Usci.andCtlw0(uint16_t v) {
    if (_t) atomic { BPTR(up)->CTLW0 &= v; }
    else    atomic { APTR(up)->CTLW0 &= v; }
  }

  async command uint16_t Usci.getBrw() {
    if (_t) return BPTR(up)->BRW;
    else    return APTR(up)->BRW;
  }

  async command void     Usci.setBrw(uint16_t v) {
    if (_t) BPTR(up)->BRW = v;
    else    APTR(up)->BRW = v;
  }

  async command uint16_t Usci.getMctl() {
    if (!_t) return APTR(up)->MCTLW;
  }

  async command void     Usci.setMctl(uint16_t v) {
    if (!_t) APTR(up)->MCTLW = v;
  }

  async command uint16_t Usci.getStat() {
    if (_t) return BPTR(up)->STATW;
    else    return APTR(up)->STATW;
  }

  async command void     Usci.setStat(uint16_t v) {
    if (_t) BPTR(up)->STATW = v;
    else    APTR(up)->STATW = v;
  }

  async command uint16_t Usci.getRxbuf() {
    if (_t) return BPTR(up)->RXBUF;
    else    return APTR(up)->RXBUF;
  }

  async command uint16_t Usci.getTxbuf() {
    if (_t) return BPTR(up)->TXBUF;
    else    return APTR(up)->TXBUF;
  }

  async command void     Usci.setTxbuf(uint16_t v) {
    if (_t) BPTR(up)->TXBUF = v;
    else    APTR(up)->TXBUF = v;
  }

  async command uint16_t Usci.getAbctl() {
    if (_t) return 0;
    else    return APTR(up)->ABCTL;
  }

  async command void     Usci.setAbctl(uint16_t v) {
    if (!_t) APTR(up)->ABCTL = v;
  }

  /* the i2c commands will blow up if wrong module is wired in.  Must be B USCI */
  async command uint16_t Usci.getI2Coa() {
    if (_t) return BPTR(up)->I2COA0;
    else    return 0;
  }

  async command void     Usci.setI2Coa(uint16_t v) {
    if (_t) BPTR(up)->I2COA0 = v;
  }

  async command uint16_t Usci.getI2Csa() {
    if (_t) return BPTR(up)->I2CSA;
    else    return 0;
  }

  async command void     Usci.setI2Csa(uint16_t v) {
    if (_t) BPTR(up)->I2CSA = v;
  }

  async command uint16_t Usci.getIe() {
    if (_t) return BPTR(up)->IE;
    else    return APTR(up)->IE;
  }

  async command void     Usci.setIe(uint16_t v) {
    if (_t) BPTR(up)->IE = v;
    else    APTR(up)->IE = v;
  }

  async command uint16_t Usci.getIfg() {
    if (_t) return BPTR(up)->IFG;
    else    return APTR(up)->IFG;
  }

  async command void	 Usci.setIfg(uint16_t v) {
    if (_t) BPTR(up)->IFG = v;
    else    APTR(up)->IFG = v;
  }

  /* EUSCI_{A,B}_IFG_RXIFG, EUSCI_B_IFG_RXIFG0 (i2c) */
  async command bool	 Usci.isRxIntrPending() {
    if (_t) return BPTR(up)->IFG & EUSCI_B_IFG_RXIFG;
    else    return APTR(up)->IFG & EUSCI_A_IFG_RXIFG;
  }

  async command void	 Usci.clrRxIntr() {
    if (_t) BITBAND_PERI(BPTR(up)->IFG, EUSCI_B_IFG_RXIFG_OFS) = 0;
    else    BITBAND_PERI(APTR(up)->IFG, EUSCI_A_IFG_RXIFG_OFS) = 0;
  }

  /* EUSCI_{A,B}_IE_RXIE_OFS, EUSCI_B_IE_RXIE0_OFS (i2c) */
  async command void	 Usci.disableRxIntr() {
    if (_t) BITBAND_PERI(BPTR(up)->IE, EUSCI_B_IE_RXIE_OFS) = 0;
    else    BITBAND_PERI(APTR(up)->IE, EUSCI_A_IE_RXIE_OFS) = 0;
  }

  async command void	 Usci.enableRxIntr() {
    if (_t) BITBAND_PERI(BPTR(up)->IE, EUSCI_B_IE_RXIE_OFS) = 1;
    else    BITBAND_PERI(APTR(up)->IE, EUSCI_A_IE_RXIE_OFS) = 1;
  }

  /* EUSCI_ {A,B}_IE_TXIFG, EUSCI_B_IE_TXIFG0 (i2c) */
  async command bool	 Usci.isTxIntrPending() {
    if (_t) return BPTR(up)->IFG & EUSCI_B_IFG_TXIFG;
    else    return APTR(up)->IFG & EUSCI_A_IFG_TXIFG;
  }

  async command void	 Usci.clrTxIntr() {
    if (_t) BITBAND_PERI(BPTR(up)->IFG, EUSCI_B_IFG_TXIFG_OFS) = 0;
    else    BITBAND_PERI(APTR(up)->IFG, EUSCI_A_IFG_TXIFG_OFS) = 0;
  }

  /* EUSCI_{A,B}_IE_TXIE_OFS, EUSCI_B_IE_TXIE0_OFS (i2c) */
  async command void	 Usci.disableTxIntr() {
    if (_t) BITBAND_PERI(BPTR(up)->IE, EUSCI_B_IE_TXIE_OFS) = 0;
    else    BITBAND_PERI(APTR(up)->IE, EUSCI_A_IE_TXIE_OFS) = 0;
  }

  async command void	 Usci.enableTxIntr() {
    if (_t) BITBAND_PERI(BPTR(up)->IE, EUSCI_B_IE_TXIE_OFS) = 1;
    else    BITBAND_PERI(APTR(up)->IE, EUSCI_A_IE_TXIE_OFS) = 1;
  }


  async command bool	 Usci.isBusy() {
    if (_t) return (BPTR(up)->STATW & EUSCI_B_STATW_BUSY);
    else    return (APTR(up)->STATW & EUSCI_A_STATW_BUSY);
  }


  async command uint16_t Usci.getIv() {
    if (_t) return BPTR(up)->IV;
    else    return APTR(up)->IV;
  }


  /*
   * I2C bits
   *
   * set direction of the bus
   */
  async command void Usci.setTransmitMode() {
    if (_t) BITBAND_PERI(BPTR(up)->CTLW0, EUSCI_B_CTLW0_TR_OFS) = 1;
  }

  async command void Usci.setReceiveMode() {
    if (_t) BITBAND_PERI(BPTR(up)->CTLW0, EUSCI_B_CTLW0_TR_OFS) = 0;
  }

  async command bool Usci.getTransmitReceiveMode() {
    if (_t) return BITBAND_PERI(BPTR(up)->CTLW0, EUSCI_B_CTLW0_TR_OFS);
    else    return 0;
  }


  /* NACK, Stop condition, or Start condition, automatically cleared */
  async command void Usci.setTxNack() {
    if (_t) BITBAND_PERI(BPTR(up)->CTLW0, EUSCI_B_CTLW0_TXNACK_OFS) = 1;
  }

  async command void Usci.setTxStop() {
    if (_t) BITBAND_PERI(BPTR(up)->CTLW0, EUSCI_B_CTLW0_TXSTP_OFS) = 1;
  }

  async command void Usci.setTxStart() {
    if (_t) BITBAND_PERI(BPTR(up)->CTLW0, EUSCI_B_CTLW0_TXSTT_OFS) = 1;
  }


  async command bool Usci.getTxNack() {
    if (_t) return BPTR(up)->CTLW0 & EUSCI_B_CTLW0_TXNACK;
    else    return 0;
  }

  async command bool Usci.getTxStop() {
    if (_t) return BPTR(up)->CTLW0 & EUSCI_B_CTLW0_TXSTP;
    else    return 0;
  }

  async command bool Usci.getTxStart() {
    if (_t) return BPTR(up)->CTLW0 & EUSCI_B_CTLW0_TXSTT;
    else    return 0;
  }


  async command bool Usci.isBusBusy() {
    if (_t) return BPTR(up)->STATW & EUSCI_B_STATW_BBUSY;
    else    return 0;
  }


  async command bool Usci.isNackIntrPending() {
    if (_t) return BPTR(up)->IFG & EUSCI_B_IFG_NACKIFG;
    else    return 0;
  }

  async command void Usci.clrNackIntr() {
    BITBAND_PERI(BPTR(up)->IFG, EUSCI_B_IFG_NACKIFG_OFS) = 0;
  }


  /*
   * Caller should disable interrupts.
   */
  async command void Usci.configure (const msp432_usci_config_t* config,
                                     bool leave_in_reset) {
    if (! config) {
      return;				/* panic? */
    }
    if (_t) {
      BPTR(up)->CTLW0 = config->ctlw0 | EUSCI_B_CTLW0_SWRST;
      BPTR(up)->BRW   = config->brw;
      BPTR(up)->I2COA0 = config->i2coa;
    } else {
      APTR(up)->CTLW0 = config->ctlw0 | EUSCI_A_CTLW0_SWRST;
      APTR(up)->BRW   = config->brw;
      APTR(up)->MCTLW = config->mctlw;
    }
    if (!leave_in_reset) {
      call Usci.leaveResetMode_();
    }
  }

  async command void Usci.enterResetMode_ () {
    if (_t) BITBAND_PERI(BPTR(up)->CTLW0, EUSCI_B_CTLW0_SWRST_OFS) = 1;
    else    BITBAND_PERI(APTR(up)->CTLW0, EUSCI_A_CTLW0_SWRST_OFS) = 1;
  }

  async command void Usci.leaveResetMode_ () {
    if (_t) BITBAND_PERI(BPTR(up)->CTLW0, EUSCI_B_CTLW0_SWRST_OFS) = 0;
    else    BITBAND_PERI(APTR(up)->CTLW0, EUSCI_A_CTLW0_SWRST_OFS) = 0;
  }


  async command msp432_usci_mode_t Usci.currentMode () {
    atomic {
      if (_t) {
        if ((BPTR(up)->CTLW0 & EUSCI_B_CTLW0_SYNC) == 0) {
          return MSP432_USCI_UART;
        }
        if ((BPTR(up)->CTLW0 & EUSCI_B_CTLW0_MODE_MASK) == EUSCI_B_CTLW0_MODE_3) {
          return MSP432_USCI_I2C;
        }
        if (BPTR(up)->CTLW0 & EUSCI_B_CTLW0_MST)
          return MSP432_USCI_SPI;
        return MSP432_USCI_SPI_SLAVE;
      } else {
        if ((APTR(up)->CTLW0 & EUSCI_A_CTLW0_SYNC) == 0) {
          return MSP432_USCI_UART;
        }
        if (APTR(up)->CTLW0 & EUSCI_A_CTLW0_MST)
          return MSP432_USCI_SPI;
        return MSP432_USCI_SPI_SLAVE;
      }
    }
    return MSP432_USCI_NONE;
  }


  async command void Usci.enableModuleInterrupt() {
    NVIC_EnableIRQ(irqn);
  }


  async command void Usci.disableModuleInterrupt() {
    NVIC_DisableIRQ(irqn);
  }


  async event void RawInterrupt.interrupted(uint8_t iv) {
    signal Interrupt.interrupted(iv);
  }

  default async event void Interrupt.interrupted(uint8_t iv) { }
}
