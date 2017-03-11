/*
 * Copyright (c) 2013, 2016 Eric B. Decker
 * Copyright (c) 2009-2010 People Power Co.
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

#include "msp432usci.h"

/**
 * Implement the UART-related interfaces for a MSP432 USCI module
 * instance.
 *
 * Interrupt Management
 * --------------------
 *
 * Upon grant of the USCI in UART mode to a client, interrupts are
 * turned off.  This compenent is dedicated so this needs to be rethought.
 *
 * On the MSP432, when the TX interrupt is raised the MCU
 * automatically clears the UCTXIFG bit that indicates that the TXBUF
 * is available for writing characters.  Rather than maintain local
 * state managed by cooperation between the TX interrupt handler and
 * the send code, we leave the TX interrupt disabled and rely on the
 * UCTXIFG flag to indicate that single-byte transmission is
 * permitted.  It is better and simpler to let the h/w maintain the
 * state.
 *
 * An exception to this is in support of the UartSerial.send()
 * function.  The transmit interrupt is enabled when the outgoing
 * message is provided; subsequent sends are interrupt-driven, and the
 * interrupt is disabled just prior to transmitting the last character
 * of the packet.  This leaves the UCTXIFG flag set upon completion of
 * the transfer.
 *
 * The receive interrupt is enabled upon configuration.  It is
 * controlled using the UartStream functions.  While a buffered
 * receive operation is active, received characters will be stored and
 * no notification provided until the full packet has been received.
 * If no buffered receive operation is active, the receivedByte()
 * event will be signaled for each received character.  Per byte
 * signal per each byte interrupt.
 *
 * As with the transmit interrupt, MCU execution of the receive
 * interrupt clears the UCRXIFG flag, making interrupt-driven
 * reception fundamentally incompatible with the busy-waiting
 * UartByte.receive() method.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 * @author Eric B. Decker <cire831@gmail.com>
 */

#ifndef PANIC_USCI

enum {
  __panic_usci = unique(UQ_PANIC_SUBSYS)
};

#define PANIC_USCI __panic_usci
#endif

generic module Msp432UsciUartP () @safe() {
  provides {
    interface Init;
    interface UartStream;
    interface UartByte;
    interface Msp432UsciError;
  }
  uses {
    interface HplMsp432Usci    as Usci;
    interface HplMsp432Gpio    as RXD;
    interface HplMsp432Gpio    as TXD;
    interface HplMsp432UsciInt as Interrupt;

    interface Msp432UsciConfigure;
    interface Panic;
    interface Platform;
    interface LocalTime<TMilli> as LocalTime_bms;
  }
}
implementation {

  enum {
    UART_MAX_BUSY_WAIT = 10000,                 /* 10ms max busy wait time */
  };

#define __PANIC_USCI(where, x, y, z) do { \
	call Panic.panic(PANIC_USCI, where, call Usci.getModuleIdentifier(), \
			 x, y, z); \
	call Usci.enterResetMode_(); \
  } while (0)

  norace uint16_t m_tx_len, m_rx_len;
  norace uint8_t * COUNT_NOK(m_tx_len) m_tx_buf, * COUNT_NOK(m_rx_len) m_rx_buf;
  norace uint16_t m_tx_pos, m_rx_pos;

  /**
   * The UART is busy if it's actively transmitting/receiving, or if
   * there is an active buffered I/O operation.
   */
  bool isBusy() {
    uint32_t t0, t1;

    t0 = call Platform.usecsRaw();
    while (call Usci.isBusy()) {
      /* busy-wait */
      t1 = call Platform.usecsRaw();
      if (t1 - t0 > UART_MAX_BUSY_WAIT) {
	__PANIC_USCI(1, t1, t0, 0);
	return TRUE;
      }
    }
    return FALSE;
  }


  /**
   * Take the USCI out of UART mode.
   *
   * Assumes the USCI is currently in UART mode.  This will busy-wait
   * until any characters being actively transmitted or received are
   * out of their shift register.  It disables the interrupts, puts
   * the USCI into reset, and returns the UART-related pins back to
   * IO mode.
   *
   * The USCI is left in reset mode to avoid power drain per UCS6.
   */
  void unconfigure_ () {
    while (isBusy()) {
    }
    /*
     * formerly, first thing we turned off the interrupt enables
     * but kicking reset turns off the interrupt enables.
     */
    call Usci.enterResetMode_();
    call RXD.setFunction(MSP432_GPIO_IO);
    call TXD.setFunction(MSP432_GPIO_IO);
  }

  /**
   * Configure the USCI for UART mode.
   *
   * Invoke the USCI configuration to set up the serial speed, but
   * leaves USCI in reset mode on completion.  This function then
   * follows up by setting the UART-related pins to their module role
   * prior to taking the USCI out of reset mode.  The RX interrupt is
   * enabled, and TX is disabled..
   */
  error_t configure_ (const msp432_usci_config_t* config) {
    if (! config) {
      __PANIC_USCI(2, 0, 0, 0);
      return FAIL;
    }

    /*
     * Do basic configuration, leaving USCI in reset mode.  Configure
     * the UART pins, enable the USCI, and turn on the rx interrupt.
     */
    atomic {
      call Usci.configure(config, TRUE);
      call RXD.setFunction(MSP432_GPIO_MOD);
      call TXD.setFunction(MSP432_GPIO_MOD);

      /*
       * all configured.  before leaving reset and turning on interrupts
       * reset the state variables about where we are in the buffer.
       */
      call Usci.leaveResetMode_();

      /* any IE bits are cleared on reset, turn on RX interrupt */
      call Usci.enableRxIntr();
    }
    return SUCCESS;
  }

  /**
   * Transmit the next character in the outgoing message.
   */
  void nextStreamTransmit() {
    uint8_t ch;
    bool    last_char;

    atomic {
      ch = m_tx_buf[m_tx_pos++];
      last_char = (m_tx_pos >= m_tx_len);

      if (last_char) {
        /*
	 * Disable TX interrupt, UCTXIFG will still be asserted
	 * once the next char going out finishes.
	 */
	call Usci.disableTxIntr();
      }
      call Usci.setTxbuf(ch);

      /*
       * On completion, disable the transmit infrastructure prior to
       * signaling completion.
       */
      if (last_char) {
        uint8_t* tx_buf;
        uint16_t tx_len;

	tx_buf = m_tx_buf;
	tx_len = m_tx_len;
        m_tx_buf = NULL;
        signal UartStream.sendDone(tx_buf, tx_len, SUCCESS);
      }
    }
  }

  async command error_t UartStream.send( uint8_t* buf, uint16_t len ) {
    error_t rv;

    if (isBusy())
      return EBUSY;

    if (!len || !buf)
      return FAIL;

    m_tx_buf = buf;
    m_tx_len = len;
    m_tx_pos = 0;
    /*
     * On start up UCTXIFG should be asserted, so enabling the TX interrupt
     * should cause the ISR to get invoked.
     */
    call Usci.enableTxIntr();
    return SUCCESS;
  }


  default async event void UartStream.sendDone(uint8_t* buf, uint16_t len, error_t error) { }


  /*
   * The behavior of UartStream during reception is not well defined.
   * In the original Msp432UartP implementation, both transmit and
   * receive interrupts were enabled upon UART configuration.  As
   * noted earlier, we keep the transmit interrupt disabled to
   * simplify control flow, but we do enable the receive interrupt for
   * backwards compatibility.
   *
   * If Usci.receive(uint8_t*,uint16_t) is called, then subsequent received
   * characters will be stored into the buffer until completion, and
   * the receivedByte(uint8_t) event will not be signaled.  If no
   * buffered receive is active, then receivedByte(uint8_t) will be
   * signaled.
   *
   * There is no coordination with UartByte, for which the receive
   * operation simply busy-waits until the interrupt register
   * indicates data is available.  If UartStream's
   * enableReceiveInterrupt() is in force, it is probable that the
   * loop will timeout as the interrupt will clear the flag
   * register.
   *
   * When the UART is unconfigured, the UART is left in reset which also
   * disables all interrupt enables.
   */

  async command error_t UartStream.enableReceiveInterrupt() {
    call Usci.enableRxIntr();
    return SUCCESS;
  }

  async command error_t UartStream.disableReceiveInterrupt() {
    call Usci.disableRxIntr();
    return SUCCESS;
  }


  default async event void UartStream.receivedByte(uint8_t byte) { }

  async command error_t UartStream.receive(uint8_t* buf, uint16_t len) {
    if (!len || !buf)
      return FAIL;

    atomic {
      if (m_rx_buf)
        return EBUSY;

      m_rx_buf = buf;
      m_rx_len = len;
      m_rx_pos = 0;
    }
    return SUCCESS;
  }


  default async event void UartStream.receiveDone(uint8_t* buf, uint16_t len, error_t error) { }

  async command error_t UartByte.send(uint8_t byte) {
    if (m_tx_buf)
      return EBUSY;

    /* Wait for TXBUF to become available */
    while (!(call Usci.isTxIntrPending())) {
    }

    /*
     * Transmit the character.  Note that it hasn't actually gone out
     * over the wire until UCBUSY (see UCmxSTAT) is cleared.
     */
    call Usci.setTxbuf(byte);

    /*
     * wait until it's actually sent.   This kills the pipeline and sucks
     * performancewise.
     */
    while(call Usci.isBusy()) {
    }
    return SUCCESS;
  }


  /*
   * Check to see if space is available for another transmit byte to go out.
   */
  async command bool UartByte.sendAvail() {
    return call Usci.isTxIntrPending();
  }


  enum {
    /**
     * The timeout for UartByte.receive is specified in "byte times",
     * which we can't know without reverse engineering the clock
     * subsystem.  Assuming a 57600 baud system, one byte takes
     * roughly 170usec to transmit (ten bits per byte), or about five
     * byte times per (binary) millisecond.
     *
     * This is seriously wedged because it is platform dependent.
     * The platform interface should specify a byte time in number
     * of microseconds (of whatever flavor the platform is providing).
     */
    ByteTimesPerMillisecond = 5,

    /**
     * Using an 8-bit value to represent a count of events with
     * sub-millisecond duration is a horrible interface for humans:
     * gives us at most 52msec to react.  For testing purposes, scale
     * that by some value (e.g., 100 will increase the maximum delay
     * to 5 seconds).
     */
    ByteTimeScaleFactor = 1,
  };

  async command error_t UartByte.receive(uint8_t* bytePtr, uint8_t timeout_bt) {
    uint32_t startTime_bms, timeout_bms;

    if (! bytePtr)
      return FAIL;

    if (m_rx_buf)
      return EBUSY;

    startTime_bms = call LocalTime_bms.get();
    timeout_bms = ByteTimeScaleFactor * ((ByteTimesPerMillisecond + timeout_bt - 1) / ByteTimesPerMillisecond);

    while (! call Usci.isRxIntrPending()) {
      if((call LocalTime_bms.get() - startTime_bms) > timeout_bms)
        return FAIL;
    }

    *bytePtr = call Usci.getRxbuf();
    return SUCCESS;
  }

  /*
   * Check to see if another Rx byte is available.
   */
  async command bool UartByte.receiveAvail() {
    return call Usci.isRxIntrPending();
  }


  async event void Interrupt.interrupted(uint8_t iv) {
    uint8_t stat, data;
    uint8_t *rx_buf;
    uint16_t rx_len;

    switch(iv) {
      case MSP432U_IV_RXIFG:
        stat = call Usci.getStat();
        data = call Usci.getRxbuf();

        /*
         * SLAU259 16.3.6: Errors are cleared by reading RXBUF.  Grab
         * the old errors, read the incoming data, then read the errors
         * again in case an overrun occurred between reading STATx and
         * RXBUF.  Mask off the bits we don't care about, and if there are
         * any left on notify somebody.
         */
        stat = (call Usci.getStat() | stat) & MSP432U_ERR_MASK;
        if (stat)
          signal Msp432UsciError.condition(stat);

        if (m_rx_buf) {
          m_rx_buf[m_rx_pos++] = data;
          if (m_rx_len == m_rx_pos) {
            rx_buf = m_rx_buf;
            rx_len = m_rx_len;
            m_rx_buf = NULL;
            signal UartStream.receiveDone(rx_buf, rx_len, SUCCESS);
          }
        } else
          signal UartStream.receivedByte(data);
        return;

      case MSP432U_IV_TXIFG:
        nextStreamTransmit();
        return;

      default:
        break;
    }
  }

  /* interrupts should be off */
  command error_t Init.init() {
    configure_(call Msp432UsciConfigure.getConfiguration());
    call Usci.enableModuleInterrupt();
    return SUCCESS;
  }

  default async event void Msp432UsciError.condition(unsigned int errors) { }
  default async event void Msp432UsciError.timeout() { }

  async event void Panic.hook() { }

#ifndef REQUIRE_PLATFORM
  default async command uint32_t Platform.usecsRaw()       { return 0; }
  default async command uint32_t Platform.usecsRawSize()   { return 0; }
  default async command uint32_t Platform.jiffiesRaw()     { return 0; }
  default async command uint32_t Platform.jiffiesRawSize() { return 0; }
#endif

#ifndef REQUIRE_PANIC
  default async command void Panic.panic(uint8_t pcode, uint8_t where,
        parg_t arg0, parg_t arg1, parg_t arg2, parg_t arg3) { }
  default async command void  Panic.warn(uint8_t pcode, uint8_t where,
        parg_t arg0, parg_t arg1, parg_t arg2, parg_t arg3) { }
#endif
}
