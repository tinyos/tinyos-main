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
 */

/**
 * Control of an MSP432 USCI module.
 *
 * This interface is completely agnostic of the modes supported by a
 * particular USCI module.  It supports the union of the module
 * registers across all modes.
 *
 * Where the same memory location reflects different registers
 * depending on USCI mode, independent functions are provided.
 *
 * @author Eric B. Decker <cire831@gmail.com>
 */

#include "msp432usci.h"

interface HplMsp432Usci {

  async command uint16_t getModuleIdentifier();

  /**
   * Read/Write the UCmx->CTLW0 Control register.
   * This register is present on all USCI modules, and is used in all modes.
   */
  async command uint16_t getCtlw0();
  async command void     setCtlw0(uint16_t v);
  async command void     orCtlw0(uint16_t v);
  async command void     andCtlw0(uint16_t v);

  /**
   * Read/Write the UCmx->BRW Baud Rate Control registers.
   * This register is present on all USCI modules.
   */
  async command uint16_t getBrw();
  async command void     setBrw(uint16_t v);

  /**
   * Read/Write the USCmx->MCTLW Modulation Control register.
   * This register is present on all USCI modules except I2C.
   */
  async command uint16_t getMctl();
  async command void     setMctl(uint16_t v);

  /**
   * Read the UCmx->STAT Status register.
   * This register is present on all USCI modules.
   */
  async command uint16_t getStat();
  async command void     setStat(uint16_t v);

  /**
   * Read/Write the UCmx->RXBUF Receive Buffer register.
   * This register is present on all USCI modules.
   */
  async command uint16_t getRxbuf();

  /**
   * Read the UCmxTXBUF Transmit Buffer register.
   * This register is present on all USCI modules.
   */
  async command uint16_t getTxbuf();
  async command void     setTxbuf(uint16_t v);

  /**
   * Read/Write the UCmx->ABCTL Auto Baud Rate Control register.
   * This register is present only on USCI_A modules in UART mode.
   */
  async command uint16_t getAbctl();
  async command void     setAbctl(uint16_t v);

  /**
   * Read the UCmx->I2COA I2C Own Address register.
   * This register is present only on USCI_B modules in I2C mode.
   */
  async command uint16_t getI2Coa();
  async command void     setI2Coa(uint16_t v);

  /**
   * Read/write the UCmx->I2CSA I2C Slave Address register.
   * This register is present only on USCI_B modules in I2C mode.
   */
  async command uint16_t getI2Csa();
  async command void     setI2Csa(uint16_t v);

  /**
   * Read/Write the UCmxIE Interrupt Enable register.
   * This register is present on all USCI modules, and is used in all modes.
   */
  async command uint16_t getIe();
  async command void     setIe(uint16_t v);

  /**
   * Read/Write the UCmxIFG Interrupt Enable register.
   * This register is present on all USCI modules, and is used in all modes.
   */
  async command uint16_t getIfg();
  async command void     setIfg(uint16_t v);

  /*
   * using setIfg and setIe to control interrupt state requires something like
   *
   *     setIe(getIe() & ~UCTXIE)          // turn of TX IE.
   *
   * The following provide a more optimized interface that directly references
   * the bit in question.  Generates better code.   Also some drivers have been
   * written using these interface specs while others with the direct register
   * access specs.
   *
   * Further on the MSP432/Cortex-M4F we hit individual bits using bitband which
   * is inherently atomic.
   */

  async command bool isRxIntrPending();
  async command void clrRxIntr();
  async command void disableRxIntr();
  async command void enableRxIntr();

  async command bool isTxIntrPending();
  async command void clrTxIntr();
  async command void disableTxIntr();
  async command void enableTxIntr();

  /*
   * TI h/w provides a busy bit.  return tx or rx is doing something
   *
   * This isn't really that useful.  This used to be called txEmpty on the x1
   * USART (where it really did represent that the tx path was empty) but that
   * isn't true on USCI modules.  Rather it indicates that tx, rx, or both are
   * active.  These paths are double buffered.
   *
   * For TX state machines (packet based etc), we want to know that all the bytes
   * went out, typically when switching resources.  For RX, we will have received
   * all the bytes we are interested in, so don't really care that the RX buffers in
   * the h/w are empty.
   *
   * In other words TI exchanged the txEmpty which worked for the isBusy which
   * doesn't really work.  Thanks, but no thanks, TI!
   *
   * TI fixed this for UARTs on the MSP432 but adding the TXCPT (transmit complete)
   * interrupt.  They also added STT (Start bit in UART mode) so one can wake up
   * and get a head start when a new char is coming in.
   */
  async command bool isBusy();


  /**
   * Reads the UCmxIV Interrupt Vector register.
   * This register is present on all USCI modules, and is used in all modes.
   * It is read-only.  This register should only be used if directly polling
   * the h/w.  Reading this register will clear the highest priority interrupt
   * for the associated block.
   */
  async command uint16_t getIv();

  /* I2C bits
   *
   * set direction of the bus
   */
  async command void setTransmitMode();
  async command void setReceiveMode();
  async command bool getTransmitReceiveMode();

  /* transmit NACK, Stop, or Start condition, automatically cleared */
  async command void setTxNack();
  async command void setTxStop();
  async command void setTxStart();

  async command bool getTxNack();
  async command bool getTxStop();
  async command bool getTxStart();

  async command bool isBusBusy();

  async command bool isNackIntrPending();
  async command void clrNackIntr();

  /* ----------------------------------------
   * Higher-level operations consistent across all modes.
   */

  /**
   * Set the USCI to the mode and speed specified in the given configuration.
   *
   * @param config The speed-relevant parameters for module
   * configuration.  Must be provided.
   *
   * @param leave_in_reset If TRUE, the module is left in software
   * reset mode upon exit, allowing the caller to perform additional
   * configuration steps such as configuring mode-specific ports.  It
   * is the caller's responsibility to invoke leaveResetMode_() upon
   * completion.
   */
  async command void configure(const msp432_usci_config_t* config,
                               bool leave_in_reset);

  /**
   * Place the USCI into software reset mode.
   * This command should only be invoked by modules that implement
   * specific USCI modes, in their mode-specific configuration
   * functions.
   */
  async command void enterResetMode_();

  /**
   * Take the USCI out of software reset mode.
   * This command should only be invoked by modules that implement
   * specific USCI modes, in their mode-specific configuration
   * functions.
   */
  async command void leaveResetMode_();

  /**
   * Return an enumeration value indicating the currently configured USCI
   * mode.  Values are from the msp432_usci_mode_t enumeration.
   */
  async command msp432_usci_mode_t currentMode();

  async command void enableModuleInterrupt();
  async command void disableModuleInterrupt();
}
