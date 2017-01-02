/*
 * Copyright (c) 2012-2014, 2016 Eric B. Decker
 * Copyright (c) 2011-2012 Joao Goncalves
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
 * Implement the SPI-related interfaces for a MSP432 USCI module
 * instance.
 *
 * Uses Panic to call out abnormal conditions.  These conditions are
 * assumed to be out of normal behaviour and aren't recoverable.
 *
 * Uses Platform to obtain raw timing information for timeout functions.
 *
 * WARNING: By default, null versions for both Panic and timing modules are
 * used.  This effectively disables any timeout checks or panic invocations.
 * This preserves the original behaviour and doesn't require changing lots
 * of things all at once.  When a Platform wants to use the new functionality
 * it can wire in the required components.  This is the recommended
 * configuration
 *
 * To enable Panic signalling and timeout functions, you must wire in
 * appropriate routines into Panic and Platform in this module.
 *
 * WARNING: If you don't wire in platform timing functions, it is possible
 * for routines in this module to hang in an infinite loop (this duplicates
 * the original behaviour when the busy waits were infinite).  If a platform
 * has enabled a watchdog timer, it is possible that the watchdog would
 * then be invoked.  However most platforms don't enable the watchdog.
 *
 * It is recommended that you define REQUIRE_PLATFORM and REQUIRE_PANIC in
 * your platform.h file.  This will require that appropriate wiring exists
 * for Panic and Platform and is wired in.
 *
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 * @author Joao Goncalves <joao.m.goncalves@ist.utl.pt>
 * @author Eric B. Decker <cire831@gmail.com>
 */

#ifndef PANIC_USCI

enum {
  __panic_usci = unique(UQ_PANIC_SUBSYS)
};

#define PANIC_USCI __panic_usci
#endif

generic module Msp432UsciSpiP () @safe() {
  provides {
    interface Init;
    interface SpiPacket;
    interface SpiBlock;
    interface SpiByte;
    interface FastSpiByte;
    interface Msp432UsciError;
  }
  uses {
    interface HplMsp432Usci    as Usci;
    interface HplMsp432Gpio    as SIMO;
    interface HplMsp432Gpio    as SOMI;
    interface HplMsp432Gpio    as CLK;
    interface HplMsp432UsciInt as Interrupt;

    interface Msp432UsciConfigure;
    interface Panic;
    interface Platform;
  }
}
implementation {

  enum {
    SPI_ATOMIC_SIZE = 2,
    SPI_MAX_BUSY_WAIT = 1000,           /* 1ms max busy wait */
  };

#define __PANIC_USCI(where, x, y, z) do { \
	call Panic.panic(PANIC_USCI, where, call Usci.getModuleIdentifier(), \
			 x, y, z); \
	call Usci.enterResetMode_(); \
  } while (0)

  norace uint16_t m_len;
  norace uint8_t* COUNT_NOK(m_len) m_tx_buf;
  norace uint8_t* COUNT_NOK(m_len) m_rx_buf;
  norace uint16_t m_pos;
  norace uint8_t m_client;

  void signalDone();

  task void signalDone_task() {
    atomic signalDone();
  }

  /**
   * The SPI is busy if it's actively transmitting/receiving.
   * What we really want is to know if the h/w is still
   * transmitting (we shut down or change state if not Txing)
   * But that isn't how this h/w behaves.  Rather an incoming
   * byte will tell us we are busy thwarting the intent of the
   * h/w check on tx.  oh well.
   *
   * given that we are a master and if we are sending then
   * stuff will be coming into the receiver too.  So this
   * BUSY should work.  It will go unBUSY after receiving the
   * last byte that we pushed.
   */
  bool isBusy () {
    uint32_t t0, t1;

    t0 = call Platform.usecsRaw();
    while (call Usci.isBusy()) {
      /* busy-wait */
      t1 = call Platform.usecsRaw();
      if (t1 - t0 > SPI_MAX_BUSY_WAIT) {
	__PANIC_USCI(1, t1, t0, 0);
	return TRUE;
      }
    }
    return FALSE;
  }


  /**
   * Take the USCI out of SPI mode.
   *
   * Assumes the USCI is currently in SPI mode.  This will busy-wait
   * until any characters being actively transmitted or received are
   * out of their shift register.  The USCI is reset (which also
   * disables interrupts) and returns the SPI-related pins to their
   * IO function rather than module role.
   *
   * The USCI is left in software reset mode to avoid power drain.
   */
  void unconfigure_ () {
    while (isBusy()) {
      /* above checks and panics if it takes too long */
    }

    /* going into reset, clears all interrupt enables */
    call Usci.enterResetMode_();
    call SIMO.setFunction(MSP432_GPIO_IO);
    call SOMI.setFunction(MSP432_GPIO_IO);
    call CLK.setFunction(MSP432_GPIO_IO);
  }


  /**
   * Configure the USCI for SPI mode.
   *
   * Invoke the USCI configuration to set up the serial speed, but
   * leaves USCI in reset mode on completion.  This function then
   * follows up by setting the SPI-related pins to their module role
   * prior to taking the USCI out of reset mode.  All interrupts are
   * left off.
   */
  error_t configure_ (const msp432_usci_config_t* config) {
    if (! config) {
      __PANIC_USCI(2, 0, 0, 0);
      return FAIL;
    }


    /*
     * Do basic configuration, leaving USCI in reset mode.  Configure
     * the SPI pins, enable the USCI, and leave interrupts off.
     */
    atomic {
      call Usci.configure(config, TRUE);
      call SIMO.setFunction(MSP432_GPIO_MOD);
      call SOMI.setFunction(MSP432_GPIO_MOD);
      call CLK.setFunction(MSP432_GPIO_MOD);

      /*
       * The IE bits are cleared when the USCI is reset, so there is no need
       * to clear the IE bits.
       */
      call Usci.leaveResetMode_();
    }
    return SUCCESS;
  }


  bool bail_wait_for(uint8_t condition) {
    uint16_t t0, t1;

    t0 = call Platform.usecsRaw();
    while (! (condition & call Usci.getIfg())) {
      /* busywait */
      t1 = call Platform.usecsRaw();
      if (t1 - t0 > SPI_MAX_BUSY_WAIT) {
	__PANIC_USCI(3, t1, t0, 0);
	return TRUE;
      }
    }
    return FALSE;
  }


  async command uint8_t SpiByte.write (uint8_t data) {
    uint8_t stat;

    if (bail_wait_for(MSP432U_IFG_TX))
      return 0;
    call Usci.setTxbuf(data);

    if (bail_wait_for(MSP432U_IFG_RX))
      return 0;
    stat = call Usci.getStat();    /* remember what we have before clearing */
    data = call Usci.getRxbuf();   /* this clears errors in STATW */
    stat = (call Usci.getStat() | stat) & MSP432U_ERR_MASK;
    if (stat) {
      signal Msp432UsciError.condition(stat);
    }
    return data;
  }


  async command void FastSpiByte.splitWrite(uint8_t data) {
    if (bail_wait_for(MSP432U_IFG_TX))
      return;
    call Usci.setTxbuf(data);
  }


  async command uint8_t FastSpiByte.splitRead() {
    if (bail_wait_for(MSP432U_IFG_RX))
      return 0;
    return call Usci.getRxbuf();
  }


  async command uint8_t FastSpiByte.splitReadWrite(uint8_t data) {
    uint8_t b;

    if (bail_wait_for(MSP432U_IFG_RX))
      return 0;
    b = call Usci.getRxbuf();

    if (bail_wait_for(MSP432U_IFG_TX))
      return b;
    call Usci.setTxbuf(data);
    return b;
  }


  async command uint8_t FastSpiByte.write(uint8_t data) {
    call FastSpiByte.splitWrite(data);
    return call FastSpiByte.splitRead();
  }


  async command void SpiBlock.transfer(uint8_t* txBuf, uint8_t* rxBuf, uint16_t len) {
    uint8_t byt;

    while (len) {
      if (bail_wait_for(MSP432U_IFG_TX))
        return;

      byt = 0;
      if (txBuf)
	byt = *txBuf++;
      call Usci.setTxbuf(byt);

      if (bail_wait_for(MSP432U_IFG_RX))
        return;

      byt = call Usci.getRxbuf();
      if (rxBuf)
	*rxBuf++ = byt;
      len--;
    }
  }

  void continueOp() {
    uint8_t end;
    uint8_t tmp;

    atomic {
      call Usci.setTxbuf( m_tx_buf ? m_tx_buf[ m_pos ] : 0 );

      end = m_pos + SPI_ATOMIC_SIZE;
      if ( end > m_len )
	    end = m_len;

      while ( ++m_pos < end ) {
        /*
         * formerly a busy wait.  replaced with panic checks.
         * if panic returns, just go grab garbage from the
         * h/w.  We died, if panic doesn't trap and yell,
         * who cares.  Previously, we would just hang.
         */
        bail_wait_for(MSP432U_IFG_RX);
        tmp = call Usci.getRxbuf();
        if ( m_rx_buf )
          m_rx_buf[ m_pos - 1 ] = tmp;

        /* is it possible for there to not be room?  */
        call Usci.setTxbuf( m_tx_buf ? m_tx_buf[ m_pos ] : 0 );
      }
    }
  }
   /** Split phase SpiPacket send
   * Implemented just as in the x2 usci Msp432SpiNoDmaP
   */

  async command error_t SpiPacket.send(uint8_t* txBuf, uint8_t* rxBuf, uint16_t len) {
    m_tx_buf = txBuf;
    m_rx_buf = rxBuf;
    m_len = len;
    m_pos = 0;

    if ( len ) {
      call Usci.enableRxIntr();
      continueOp();
    } else
      post signalDone_task();
    return SUCCESS;
  }


  void signalDone() {
    signal SpiPacket.sendDone(m_tx_buf, m_rx_buf, m_len, SUCCESS);
  }


  async event void Interrupt.interrupted(uint8_t iv) {
    uint8_t data;

    switch (iv) {
      case MSP432U_IV_RXIFG:
        data = call Usci.getRxbuf();
        if ( m_rx_buf )
          m_rx_buf[ m_pos-1 ] = data;
        if ( m_pos < m_len )
          continueOp();
        else {
          call Usci.disableRxIntr();
          signalDone();
        }
        break;

      default:
      case MSP432U_IV_TXIFG:
        break;
    }
  }


  /* interrupts should be off */
  command error_t Init.init() {
    configure_(call Msp432UsciConfigure.getConfiguration());
    call Usci.enableModuleInterrupt();
    return SUCCESS;
  }


  default async event void SpiPacket.sendDone(uint8_t* txBuf,
			uint8_t* rxBuf, uint16_t len, error_t error) { }

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
