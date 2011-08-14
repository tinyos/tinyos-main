/*
 * Copyright (c) 2010 Eric B. Decker
 * Copyright (c) 2009 DEXMA SENSORS SL
 * Copyright (c) 2004-2005, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Copyright (c) 2004-2005, Technische Universitaet Berlin
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
 * Byte-level interface to control Usci based modules (MSP430X), msp430f2618 etc.
 * USCI_A supports Uart, SPI, and irDA modes.  USCI_B SPI and I2C.  Stateless
 * interface modeled after HplMsp430Usart of the MSP430 family.
 *
 * @author Vlado Handziski (handzisk@tkn.tu-berlin.de)
 * @author Jan Hauer (hauer@tkn.tu-berlin.de)
 * @author Joe Polastre
 * @author Xavier Orduna <xorduna@dexmatech.com>
 * @author Eric B. Decker <cire831@gmail.com>
 *
 * see msp430usci.h for basic definitions.
 * See TI MSP430x2xx Family User's Guide SLAU144E for details.
 */

#include "msp430usci.h"

interface HplMsp430UsciA {

  /* UCxxCTL0 */
  async command void setUctl0(msp430_uctl0_t control);
  async command msp430_uctl0_t getUctl0();

  /* UCxxCTL1 */
  async command void setUctl1(msp430_uctl1_t control);
  async command msp430_uctl1_t getUctl1();

  /* UCxxBR1 UCxxBR0 */
  async command void setUbr(uint16_t ubr);
  async command uint16_t getUbr();

  /* UCxxMCTL */
  async command void setUmctl(uint8_t umctl);
  async command uint8_t getUmctl();

  /*
   * access usci status registers.  yes there are control
   * bits in the status register.
   */
  /* UCxxSTAT */
  async command void setUstat(uint8_t ustat);
  async command uint8_t getUstat();

  /*
   * resetUsci() - reset or unreset module port
   *
   * reset:	TRUE (set UCSWRST)
   *		FALSE (unset UCSWRST), let the port run
   */
  async command void resetUsci(bool reset);

  /*
   * return enum indicating what mode the usci port in in.
   */
  async command msp430_uscimode_t getMode();

  /*
   * configure or deconfigure gpio pins for SPI mode
   *
   * switches io pins between port and module function.
   */
  async command void enableSpi();
  async command void disableSpi();
  
  /*
   * Returns TRUE if the Usci is in SPI mode
   */
  async command bool isSpi();
  
  /*
   * configure usci as spi using config.
   * leaves interrupts disabled.
   */
  async command void setModeSpi(msp430_spi_union_config_t* config);
  
  /* Interrupt control */
  async command void disableRxIntr();
  async command void disableTxIntr();
  async command void disableIntr();
  async command void enableRxIntr();
  async command void enableTxIntr();
  async command void enableIntr();
  
  async command bool isTxIntrPending();
  async command bool isRxIntrPending();
  async command void clrTxIntr();
  async command void clrRxIntr();
  async command void clrIntr();

  async command bool isTxEmpty();

  /**
   * Transmit a byte of data. When the transmission is completed,
   * <code>txDone</done> is generated. Only then a new byte may be
   * transmitted, otherwise the previous byte will be overwritten.
   */
  async command void tx(uint8_t data);
  
  /**
   * Get current value from RX-buffer.
   *
   * return:	byte received.
   */
  async command uint8_t rx();

  /*
   * Returns TRUE if the Usci is in Uart mode
   */
  async command bool isUart();

  /*
   * configure or deconfigure gpio pins for UART mode
   *
   * switches io pins between port and module function.
   */
  async command void enableUart();
  async command void disableUart();

  /*
   * configure usci as uart using config.
   * leaves interrupts disabled.
   */
  async command void setModeUart(msp430_uart_union_config_t* config);
}
