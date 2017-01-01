/*
 * Copyright (c) 2012-2014, 2016 Eric B. Decker
 * All rights reserved.
 *
 * Multi-Master driver.
 * (NEEDS TO BE TESTED)
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
 *
 * Implement the I2C-related interfaces for a MSP432 USCI module
 * instance.  Multi-Master driver.
 *
 * Originally started with the Multi-Master i2c driver from John
 * Hopkins (Doug Carlson, et. al.).   From the USCI gen 1 port.
 *
 * Completely rewritten to simplify and verified for proper operation
 * at 400 KHz.  Previous drivers worked at 100 KHz but not at 400 KHz.
 *
 * This code is based on the single master driver rewrite with multi-master
 * additions.
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
 * for routines in this module to hang in an infinite loop.  If a platform
 * has enabled a watchdog timer, it is possible that the watchdog would
 * then be invoked.  Most platforms don't enable the watchdog.
 *
 * It is recommended that you define REQUIRE_PLATFORM and REQUIRE_PANIC in
 * your platform.h file.  This will require that appropriate wiring exists
 * for Panic and Platform and is wired in.
 *
 * @author Eric B. Decker <cire831@gmail.com>
 *
 * previous authors...   But it has been completely rewritten.
 *
 * @author Doug Carlson   <carlson@cs.jhu.edu>
 * @author Marcus Chang   <marcus.chang@gmail.com>
 * @author Peter A. Bigot <pab@peoplepowerco.com>
 * @author Derek Baker    <derek@red-slate.com>
 * @author Eric B. Decker <cire831@gmail.com>
 */

#include "msp432usci.h"
#include <I2C.h>

#ifndef PANIC_I2C

enum {
  __panic_i2c = unique(UQ_PANIC_SUBSYS)
};

#define PANIC_I2C __panic_i2c
#endif


generic module Msp432UsciI2CP () @safe() {
  provides {
    interface Init;
    interface I2CPacket<TI2CBasicAddr> as I2CBasicAddr;
    interface I2CReg;
    interface I2CSlave;
    interface ResourceConfigure;
  }
  uses {
    interface HplMsp432Usci as Usci;
    interface HplMsp432Gpio as SDA;
    interface HplMsp432Gpio as SCL;
    interface HplMsp432UsciInt as Interrupt;

    interface Msp432UsciConfigure;
    interface Panic;
    interface Platform;
  }
}

implementation {

  enum {
    MASTER_IDLE  = 0,
    MASTER_READ  = 1,
    MASTER_WRITE = 2,
    SLAVE        = 3,

    /*
     * Time based timeouts.  Given 100 KHz, 400 uS should be plenty, but
     * this doesn't handle clock stretching.  The time out code needs
     * to handle this special.   And still needs to make sure that we
     * don't hang.   While still giving the h/w long enough to complete
     * its bus transaction.
     *
     * For the time being we ignore clock stretching.   Cross that bridge
     * if the troll climbs out from underneath.
     *
     * Timeout is in either uS or uiS depending on what the base clock
     * system is set for.  Just set it high enough so it doesn't matter.
     */
    I2C_MAX_TIME = 400,			/* max allowed, 400 uS */
  };

#define __PANIC_I2C(where, x, y, z) do { \
	call Panic.panic(PANIC_I2C, where, call Usci.getModuleIdentifier(), \
			 x, y, z); \
	force_idle(); \
  } while (0)

  norace uint8_t*    m_buf;
  norace uint8_t     m_len;
  norace uint8_t     m_pos;
  norace uint8_t     m_left;
  norace uint8_t     m_action;
					/* TRUE if TXSTART issued */
  norace uint8_t     m_started;		/* 1 if started, 0 otherwise */
  norace i2c_flags_t m_flags;		/* START, STOP, RESTART, etc. */


  error_t configure_(const msp432_usci_config_t* config) {
    if (!config)
      return FAIL;			/* does anyone actually check? */

    atomic {
      call Usci.configure(config, TRUE);	/* leave in reset */
      call SCL.setFunction(MSP432_GPIO_MOD);
      call SDA.setFunction(MSP432_GPIO_MOD);
      call Usci.setI2Coa(config->i2coa);

      /*
       * Turn on START interrupt.   Used for when we are the slave end
       * and someone else is trying to talk to us...
       *
       * But is anything wired in and ready to receive the incoming?
       * hopefully should be statically wired in.   And it should be
       * ready to deal with immediate interrupts.
       */
      m_action = SLAVE;
      call Usci.leaveResetMode_();
      call Usci.setIe(EUSCI_B_IE_STTIE);
    }
    return SUCCESS;
  }


  error_t force_idle() {
    /*
     * force the h/w back to idle.   That means take the h/w
     * out of master (force back to slave, just in case someone
     * is trying to talk to us).
     *
     * If already a Slave don't reset the beasty, preserve any
     * state currently present.
     *
     * Should this actually leave the h/w in reset?  force_idle
     * only gets called after something goes wrong.   But our
     * default state is to be in Slave mode.
     */
    atomic {
      if (call Usci.getCtlw0() & EUSCI_B_CTLW0_MST) {
	call Usci.enterResetMode_();
	call Usci.andCtlw0(~EUSCI_B_CTLW0_MST);
	call Usci.leaveResetMode_();
      }
      call Usci.setIe(EUSCI_B_IE_STTIE);
      m_action = SLAVE;
    }
    return SUCCESS;
  }


  /*
   * We assume that the pins being used for SCL/SDA have been set up
   * or left (initial state) as input (DIR set to 0 for the pin).
   * When we deselect the pins from the module, the pins will go
   * back to inputs.  The module itself is kept in reset.   This
   * configuration should be reasonable for lowish power.
   */
  error_t unconfigure_() {
    atomic {
      call Usci.enterResetMode_();	/* leave in reset */
      call SCL.setFunction(MSP432_GPIO_IO);
      call SDA.setFunction(MSP432_GPIO_IO);
    }
    return SUCCESS;
  }


  /*
   * Set up for a transaction.
   *
   * First, reset the module.  This will blow away pending interrupts and
   * interrupt enables.  Will this also make it impossible for the bus
   * to be busy?
   *
   * Reset and then make sure the bus isn't busy.   Since this is the
   * multi-master driver we want to set MST as we are preparing to go
   * on the bus.
   */

  error_t start_check_busy() {
    uint16_t t0, t1;

    call Usci.enterResetMode_();			// blow any cruft away
    call Usci.orCtlw0(EUSCI_B_CTLW0_MST);				// force into master
    call Usci.leaveResetMode_();			// trying to talk

    t0 = call Platform.usecsRaw();
    while (call Usci.isBusBusy()) {
      t1 = call Platform.usecsRaw();
      if (t1 - t0 > I2C_MAX_TIME) {
	__PANIC_I2C(1, t1, t0, 0);
	return EBUSY;
      }
    }
    return SUCCESS;
  }


  /*
   * Wait for a CTRL1 signal to deassert.   These in particular
   * are TXNACK (Nack), TXSTP (Stop), and TXSTT (Start).
   * Typically only Stop and Start are actually looked at.
   */
  error_t wait_deassert_ctlw0(uint8_t code) {
    uint16_t t0, t1;

    t0 = call Platform.usecsRaw();

    /* wait for code bits to go away */
    while (call Usci.Ctlw0() & code) {
      t1 = call Platform.usecsRaw();
      if (t1 - t0 > I2C_MAX_TIME) {
	__PANIC_I2C(2, t1, t0, 0);
	return ETIMEOUT;
      }
    }
    return SUCCESS;
  }


  /*
   * wait_ifg: wait for a particlar USCI_IFG bit to pop
   *
   * uses I2C_MAX_TIME to time out the access
   * checks for NACKIFG, if it pops abort
   *
   * NAKIFG simply panics which also yields a i2c h/w reset.
   * It doesn't send a STOP on the bus which may confuse some
   * devices.  It is assumed this is a single master system
   * and new transactions will start with a TXSTART which
   * should reset all devices out there to start looking
   * properly.
   *
   * It may be necessary to change the NACK abort code so
   * it issues a STOP prior to panicing just to clean the
   * bus up.
   */
  error_t wait_ifg(uint8_t code) {
    uint16_t t0, t1;
    uint8_t ifg;

    t0 = call Platform.usecsRaw();
    while (1) {
      ifg = call Usci.getIfg();
      if (ifg & EUSCI_B_IFG_NACKIFG) {          // didn't respond.
	__PANIC_I2C(3, ifg, 0, 0);
	return EINVAL;
      }
      if (ifg & code) break;
      t1 = call Platform.usecsRaw();
      if (t1 - t0 > I2C_MAX_TIME) {
	__PANIC_I2C(4, t1, t0, 0);
	return ETIMEOUT;
      }
    }
    return SUCCESS;
  }


  /*************************************************************************/
  /*
   * WARNING: The TI I2C implementation is double buffered.  One of the
   * side effects of this, is any unSTOPPed read will result in one possibly
   * two additional bytes being queued up.  Depends on timing and what
   * other operations the cpu is doing prior to servicing the i2c interrupts.
   *
   * One needs to be careful when using UNSTOPPED transactions coupled with
   * RESTARTs.  It is very easy to hang the bus or get confused.  Typically
   * this will result in a NACK interrupt.   See notes below inside of read.
   */

  /*
   * I2CBasicAddr.read - interrupt driven I2C read
   *
   * If we return SUCCESS, an I2CBasicAddr.readDone is guaranteed to be
   * signalled.  This happens off an interrupt.
   *
   * Any error return (non-SUCCESS) indicates no signal will be generated.
   * Any error leaves the cpu I2C h/w reset and in low power state prior
   * to returning.
   *
   * This implementation closely follows the I2CReg.reg_readBlock code
   * without the initial register address write.
   */
  async command error_t I2CBasicAddr(i2c_flags_t flags,
		uint16_t addr, uint8_t len, uint8_t* buf ) {
    error_t rtn;

    if (!len || !buf)
      return EINVAL;

    m_buf    = buf;
    m_len    = len;
    m_left   = len;
    m_flags  = flags;
    m_pos    = 0;
    m_action = MASTER_READ;

    /*
     * check if this is a new connection or a continuation
     * If RESTARTing, then don't do the start_check_busy.
     * RESTART implies START.
     */
    if (m_flags & (I2C_START | I2C_RESTART)) {

      /*
       * If RESTARTing, assume that we are already in the mode we want (MST or
       * SLAVE).  Otherwise call start_check_busy to set things up and make sure
       * we are in a reasonable state.   This will set MST because we are trying
       * to talk.
       */
      if (!(m_flags & I2C_RESTART) && (rtn = start_check_busy()))
	  return rtn;

      call Usci.setI2Csa(addr);
      call Usci.setReceiveMode();	/* clears CTR, reading */
      call Usci.setTxStart();		/* set TXSTT, send Start  */
      m_started = 1;

      /*
       * if only reading 1 byte, STOP bit must be set right after
       * START condition has gone (TXSTT deasserts).
       *
       * Normally (more than 1 byte), we assert TXSTT (start)
       * and then wait for the 1st RXIFG interrupt.  The logic
       * in the RX interrupt handler will set TXSTOP at the
       * proper time.
       *
       * But if we are only doing one byte we must set STOP
       * immediately after TXSTT deasserts and it starts
       * clocking to receive the 1st byte into the RX SR
       * for the STOP condition to be signalled properly.
       */
      if ((m_left == 1) && (m_flags & I2C_STOP)) {
	if ((rtn = wait_deassert_ctlw0(EUSCI_B_CTLW0_TXSTT)))
	  return rtn;
	call Usci.setTxStop();
      }

      call Usci.setIe(EUSCI_B_IE_NACKIE | EUSCI_B_IE_ALIE | EUSCI_B_IE_RXIE);
      return SUCCESS;
    }

    /*
     * Not START or RESTART.  Continuing with a read...
     *
     * This is actually a strange way to access the bus.  Typically
     * one would do something like (reading a register for example):
     *
     * I2CBasicAddr.write(I2C_START, DEV_ADDR, len, buf);
     *		<-- I2CBasicAddr.writeDone(...);
     * I2CBasicAddr.read(I2C_RESTART | I2C_STOP, DEV_ADDR, len, buf);
     *		<-- I2CBasicAddr.readDone(...);
     *
     * In other words, typically one always touches the bus with a
     * bus transaction that causes TXSTART to be asserted.  Stalling
     * the bus while then getting around to accessing it again isn't
     * typical and is what this section of code supports.  Also it
     * has been observed that stalling the bus for too long causes
     * a NACK to get generated.   Unless one restarts the bus.
     *
     * In other words, I've never seen this section actually work.
     *
     * We have to special case the one byte case.  Because of how
     * STOP gets set when actually doing a start.
     *
     * Because we are reading and because the h/w is double buffered,
     * we will read one possibly two extra bytes.  One byte will be
     * sitting in RXBUF while the next byte will be mostly in the
     * shift register (SR).  Depends on the timing and when STOP is
     * set.
     */

    /*
     * Must have seen a start prior or abort
     */

    if (!m_started) {
      __PANIC_I2C(5, 0, 0, 0);
      return EINVAL;
    }

    if ((m_left == 1) && (m_flags & I2C_STOP))
      call Usci.setTxStop();
    call Usci.setIe(EUSCI_B_IE_NACKIE | EUSCI_B_IE_ALIE | EUSCI_B_IE_RXIE);
    return SUCCESS;
  }


  /*************************************************************************/

  /*
   * I2CBasicAddr.write - interrupt driven I2C write
   *
   * If we return SUCCESS, a I2CBasicAddr.writeDone is guaranteed to be
   * signalled.  This happens off an interrupt.
   *
   * Any error return (non-SUCCESS) then no signal will be generated.
   */
  async command error_t I2CBasicAddr.write(i2c_flags_t flags,
		uint16_t addr, uint8_t len, uint8_t* buf) {
    error_t rtn;

    if (!len || !buf)
      return EINVAL;

    m_buf    = buf;
    m_len    = len;
    m_left   = len;
    m_flags  = flags;
    m_pos    = 0;
    m_action = MASTER_WRITE;

    /*
     * check if this is a new connection or a continuation
     * If RESTARTing, then don't do the start_check_busy.
     */
    if (m_flags & (I2C_START | I2C_RESTART)) {

      if (!(m_flags & I2C_RESTART) && (rtn = start_check_busy()))
	  return rtn;

      call Usci.setI2Csa(addr);
      call Usci.orCtlw0(EUSCI_B_CTLW0_TR | EUSCI_B_CTLW0_TXSTT);		// writing, Start.
      m_started = 1;
    }

    if (!m_started) {
      __PANIC_I2C(6, 0, 0, 0);
      return EINVAL;
    }
    call Usci.setIe(EUSCI_B_IE_NACKIE | EUSCI_B_IE_ALIE | EUSCI_B_IE_TXIE);
    return SUCCESS;
  }


  /***************************************************************************/
  /*
   * Defaults for I2CBasicAddr
   */

  default async event void I2CBasicAddr.readDone(error_t error, uint16_t addr,
								 uint8_t length, uint8_t* data)  {}

  default async event void I2CBasicAddr.writeDone(error_t error, uint16_t addr,
								  uint8_t length, uint8_t* data) {}


  /***************************************************************************/
  /*
   * Slave Interfaces
   */

  async command void I2CSlave.slaveTransmit(uint8_t data) {
    //TODO: safety
    //write it, reenable interrupt (if it was disabled)
    call Usci.setTxbuf(data);
    call Usci.enableTxIntr();
  }


  async command uint8_t I2CSlave.slaveReceive() {
    //re-enable rx interrupt, read the byte
    call Usci.enableRxIntr();
    return call Usci.getRxbuf();
  }


  command error_t I2CSlave.setOwnAddress(uint16_t addr) {
    //retain GCEN bit
    call Usci.enterResetMode_();
    call Usci.setI2Coa(addr);
    call Usci.leaveResetMode_();
    return SUCCESS;
  }


  command error_t I2CSlave.enableGeneralCall() {
    call Usci.enterResetMode_();
    call Usci.setI2Coa(EUSCI_B_I2COA0_GCEN | (call Usci.getI2Coa()));
    call Usci.leaveResetMode_();
    return SUCCESS;
  }


  command error_t I2CSlave.disableGeneralCall() {
    call Usci.enterResetMode_();
    call Usci.setI2Coa(~EUSCI_B_I2COA0_GCEN & (call Usci.getI2Coa()));
    call Usci.leaveResetMode_();
    return SUCCESS;
  }


  default async event bool I2CSlave.slaveReceiveRequested()  { return FALSE; }
  default async event bool I2CSlave.slaveTransmitRequested() { return FALSE; }

  default async event void I2CSlave.slaveStart(bool isGeneralCall) { ; }
  default async event void I2CSlave.slaveStop() { ; }


  /***************************************************************************/
  /*
   * INTERRUPT HANDLERS
   *
   */

  void TXInterrupts_interrupted(uint8_t iv) {
    error_t rtn;

    if (m_left) {
      call Usci.setTxbuf(m_buf[m_pos++]);
      m_left--;
      return;
    }

    /*
     * when m_left is 0, all bytes have been sent.
     *
     * the last byte has just been transferred to the SR and we have
     * taken one last TXIFG interrupt.  If stopping we need to set
     * STOP now.
     */
    rtn = SUCCESS;
    if (m_flags & I2C_STOP) {
      call Usci.setTxStop();
      rtn = wait_deassert_ctlw0(EUSCI_B_CTLW0_TXSTP);
      m_started = 0;
    }

    /* the last byte is still on its way out.   we may need to give
     * it some time before signalling.   But for now just signal.
     *
     * If STOPing, this isn't an issue because we wait for the STOP
     * to be transmitted above.
     */
    call Usci.setIe(0);			/* turn off all interrupts */
    signal I2CBasicAddr.writeDone(
	rtn, call Usci.getI2Csa(), m_len, m_buf);
    return;
  }


  void RXInterrupts_interrupted(uint8_t iv) {
    error_t rtn;

    m_left--;

    /*
     * When we are pulling the next to last byte (ie. the SR is
     * receiving the last byte), we want to make sure the last
     * byte get STOP set which will be asserted after that last
     * byte comes in.
     */
    if ((m_left == 1) && (m_flags & I2C_STOP))
      call Usci.setTxStop();

    m_buf[m_pos++] = call Usci.getRxbuf();

    if (m_left == 0) {
      /*
       * all done receiving...
       */
      call Usci.setIe(0);		/* turn off all interrupts */
      rtn = SUCCESS;

      /* if stopping wait for STOP to deassert */
      if (m_flags & I2C_STOP) {
	rtn = wait_deassert_ctlw0(EUSCI_B_CTLW0_TXSTP);
	m_started = 0;
      }
      signal I2CBasicAddr.readDone( rtn, call Usci.getI2Csa(), m_pos, m_buf);
    }
  }


  void NACK_interrupt() {
    bool reading;
    error_t rtn;

    /* remember what we were doing... */
    reading = (m_action == MASTER_READ);

    /*
     * Nobody home, abort.   Read or Write
     *
     * First close off the transaction.   This releases the bus
     * properly.   Takes into account other masters (yes we are
     * single master so who cares, but its the right thing to do.)
     */
    call Usci.setTxStop();
    if ((rtn = wait_deassert_ctlw0(EUSCI_B_CTLW0_TXSTP)))
      goto nack_abort;

    rtn = ENOACK;

    /*
     * Throw a PANIC because NACK should never happen.
     * Someone did something weird or something broke.
     *
     * __PANIC_I2C will reset the h/w and will reset m_action.
     */
    __PANIC_I2C(98, 0, 0, 0);

    /*
     * Panic itself may be a NOP (ie. not wired to anything) so
     * we may end up back here.  Signal failure to the application.
     */

    /*
     * you can't use the h/w (TR bit) because it has been reset
     * which clears the bit.   You can't use m_action because Panic
     * forces m_action to MASTER_IDLE.
     */
nack_abort:
    m_started = 0;
    if (reading) {
      signal I2CBasicAddr.readDone(
		rtn, call Usci.getI2Csa(), m_len, m_buf);
      return;
    }

    /* we were writing.   Signal appropriately */
    signal I2CBasicAddr.writeDone(
		rtn, call Usci.getI2Csa(), m_len, m_buf);
    return;
  }


  void AL_interrupt() {
    uint8_t lastAction = m_action;

    force_idle();

    switch (lastAction) {
      case MASTER_WRITE:
	signal I2CBasicAddr.writeDone(EBUSY, call Usci.getI2Csa(), m_len, m_buf );
	break;

      case MASTER_READ:
	signal I2CBasicAddr.readDone( EBUSY, call Usci.getI2Csa(), m_len, m_buf);
	break;

      default:
	break;
    }

    //once this returns, we should get another interrupt for STT
    //if we are addressed. Otherwise, we're just chillin' in idle
    //slave mode as per usual.
  }


  void STP_interrupt() {

    /* disable STOP interrupt, enable START interrupt */
    call Usci.setIe((call Usci.getIe() | EUSCI_B_IE_STTIE) & ~EUSCI_B_IE_STPIE);

    //this is ugly: the stop interrupt has higher priority than RX.
    //It appears to be the case that since we get the RX interrupt as
    //soon as the byte is received, and the STP interrupt as soon as
    //the stop condition is received, there is a very short window
    //where we have the RX but not the STP, and we tend to see the
    //stop interrupt first.  This will surely confound upper-level
    //logic (it would see a stop, then another byte), so we reverse
    //the priority for this case in software.

    if (call Usci.getIfg() & EUSCI_B_IFG_RXIFG & call Usci.getIe()) {
      RXInterrupts_interrupted(call Usci.getIfg());
    }
    signal I2CSlave.slaveStop();
  }


  void STT_interrupt() {

    //This is the same issue as noted in the STP_interrupt above, but
    //applied to repeated start conditions.

    if (call Usci.getIfg() & EUSCI_B_IFG_RXIFG & call Usci.getIe() ) {
      RXInterrupts_interrupted(call Usci.getIfg());
    }
    call Usci.setIe(call Usci.getIe() | EUSCI_B_IE_STPIE | EUSCI_B_IE_RXIE | EUSCI_B_IE_TXIE);
    signal I2CSlave.slaveStart( call Usci.getStat() & EUSCI_B_STATW_GC);
  }


  async event void Interrupt.interrupted(uint8_t iv) {
    switch(iv) {
      case MSP432U_IV_I2C_AL:
        AL_interrupt();
        break;
      case MSP432U_IV_I2C_NACK:
        NACK_interrupt();
        break;
      case MSP432U_IV_I2C_STT:
        STT_interrupt();
        break;
      case MSP432U_IV_I2C_STP:
        STP_interrupt();
        break;
      case MSP432U_IV_I2C_RX0:
        RXInterrupts_interrupted(iv);
        break;
      case MSP432U_IV_I2C_TX0:
        TXInterrupts_interrupted(iv);
        break;
      default:
	/* very strange */
	__PANIC_I2C(99, 0, 0, 0);
        break;
    }
  }


  /***************************************************************************/
  /*
   *
   * I2CReg implementation.
   *
   * WARNING: DOES NOT SUPPORT MULTI-MASTER.   Assumes single-master (us).
   * Forces MST mode and doesn't let go.  Not sure how to put it back in SLAVE
   * in a reasonable fashion.
   *
   * Does not support lost arbitration.
   */


  /*
   * see if the slave is out there...
   *
   * 0  if no one home
   * 1  well your guess here.
   */
  async command bool I2CReg.slave_present(uint16_t sa) {
    error_t rtn;

    if ((rtn = start_check_busy()))
      return rtn;

    call Usci.setI2Csa(sa);
    call Usci.orCtlw0(EUSCI_B_CTLW0_TR | EUSCI_B_CTLW0_TXSTT | EUSCI_B_CTLW0_TXSTP);		// Write, Start, Stop

    if ((rtn = wait_deassert_ctlw0(EUSCI_B_CTLW0_TXSTP)))
      return rtn;

    rtn = call Usci.isNackIntrPending();		// 1 says NACK'd
    return (!rtn);					// we want the opposite sense
  }


  /*
   * reg_read:
   *
   * START (w/ device addr, in i2csa), transmit
   * 1st write the reg addr
   * 2nd restart (w/device addr), receive
   * read byte (reg contents)
   * finish
   */
  async command error_t I2CReg.reg_read(uint16_t sa, uint8_t reg, uint8_t *val) {
    uint16_t data;
    error_t rtn;

    *val = 0;
    if ((rtn = start_check_busy()))
      return rtn;
    call Usci.setI2Csa(sa);

    /* We want to write the regAddr, send the SA and then write regAddr */
    call Usci.orCtlw0(EUSCI_B_CTLW0_TR | EUSCI_B_CTLW0_TXSTT);		// TR (write) & STT

    /*
     * get 1st TxIFG
     *
     * The MSP432 is double buffered.  1st TxIFG will show up shortly after
     * TxSTT has been sent (both buffers empty).   We write the first byte
     * (the reg addr), it gets moved to the output buffer (shift register) and
     * will start to be clocked out.   2nd TxIFG will show at this point.
     * This is when we want to turn the bus around so we can receive the
     * byte coming back.
     */

    if ((rtn = wait_ifg(EUSCI_B_IFG_TXIFG)))
      return rtn;
    call Usci.setTxbuf(reg);			// write register address

    /* looking for 2nd TxIFG */
    if ((rtn = wait_ifg(EUSCI_B_IFG_TXIFG)))		// says 1st byte got ack'd
      return rtn;

    /*
     * receive one byte
     *
     * First turn the bus around with a Restart.  Wait for the TxStart
     * to take and then assert the Stop.   This should put the stop
     * on the first receive byte.
     */
    call Usci.setReceiveMode();			// clears CTR
    call Usci.setTxStart();

    /* wait for the TxStart to go away */
    if ((rtn = wait_deassert_ctlw0(EUSCI_B_CTLW0_TXSTT)))
      return rtn;
    call Usci.setTxStop();

    /* wait for inbound char to show up, first rx byte */
    if ((rtn = wait_ifg(EUSCI_B_IFG_RXIFG)))
      return rtn;

    data = call Usci.getRxbuf();
    *val = data;
    return SUCCESS;
  }


  /*
   * reg_read16
   *
   * address slave (sa)
   * tx (write) reg addr (reg) to the device
   * restart (assert TXStart) to turn bus around
   * read two bytes.
   */
  async command error_t I2CReg.reg_read16(uint16_t sa, uint8_t reg, uint16_t *val) {
    uint16_t data;
    error_t rtn;

    *val = 0;
    if ((rtn = start_check_busy()))
      return rtn;
    call Usci.setI2Csa(sa);

    /* We want to write the regAddr, send the SA and then write regAddr */
    call Usci.orCtlw0(EUSCI_B_CTLW0_TR | EUSCI_B_CTLW0_TXSTT);		// TR (write) & STT

    /*
     * get 1st TxIFG
     *
     * The MSP432 is double buffered.  1st TxIFG will show up shortly after
     * TxSTT has been sent (both buffers empty).   We write the first byte
     * (the reg addr), it gets moved to the output buffer (shift register) and
     * will start to be clocked out.   2nd TxIFG will show at this point.
     * This is when we want to turn the bus around so we can receive two
     * bytes.  (Send a Restart (assert TxSTT again, but this time indicate
     * receiving)).   This will occur after the current outgoing byte (in
     * the outbound serial register) has been ACK'd.
     */

    if ((rtn = wait_ifg(EUSCI_B_IFG_TXIFG)))
      return rtn;
    call Usci.setTxbuf(reg);			// write register address

    /* looking for 2nd TxIFG */
    if ((rtn = wait_ifg(EUSCI_B_IFG_TXIFG)))		// says 1st byte got ack'd
      return rtn;

    /*
     * receive two bytes
     *
     * First turn the bus around with a Restart.
     *
     * Also double buffered....    When the 1st RxIFG asserts saying
     * there is something in RxBUF, the 2nd byte is also being clocked
     * into the Rx Shift register.  (unless the slave isn't ready in which
     * case it will be doing clock stretching, SCLLOW will be asserted).
     *
     * So if we want to receive two bytes all is good.   TxStop needs
     * to be asserted while the 2nd byte is being received which
     * means after the 1st RxIFG has been seen.   We should get one
     * more RxIFG and that should complete the transaction.
     */
    call Usci.setReceiveMode();			// clears CTR
    call Usci.setTxStart();

    /* wait for the TxStart to go away */
    if ((rtn = wait_deassert_ctlw0(EUSCI_B_CTLW0_TXSTT)))
      return rtn;

    /* wait for inbound char to show up, first rx byte */
    if ((rtn = wait_ifg(EUSCI_B_IFG_RXIFG)))
      return rtn;

    /*
     * Since we have RxIntr asserted, we have a byte in the RxBuf and its been ack'd.
     * The next byte is in progress so set TxStop.  It will go on the next byte.
     * Then actually read the current byte which will unfreeze the state machine.
     *
     * This will avoid starting another bus cycle, which can happen if we set
     * stop after reading the first byte.   Depends on if the bus is stalled.
     * Ie. we got backed up and the I2C h/w is ahead of us.
     */
    call Usci.setTxStop();

    data = call Usci.getRxbuf();
    data = data << 8;
    if ((rtn = wait_ifg(EUSCI_B_IFG_RXIFG)))
      return rtn;
    data |= call Usci.getRxbuf();
    *val = data;
    return SUCCESS;
  }


  async command error_t I2CReg.reg_readBlock(
	    uint16_t sa, uint8_t reg, uint8_t num_bytes, uint8_t *buf) {

    uint16_t left;
    error_t  rtn;

    if (num_bytes == 0 || buf == NULL)
      return EINVAL;

    left = num_bytes;

    /*
     * special case of left starts out 1, single byte.
     *
     */
    if (left == 1)
      return call I2CReg.reg_read(sa, reg, &buf[0]);

    if ((rtn = start_check_busy()))
      return rtn;

    call Usci.setI2Csa(sa);

    /* We want to write the regAddr, send the SA and then write regAddr */
    call Usci.orCtlw0(EUSCI_B_CTLW0_TR | EUSCI_B_CTLW0_TXSTT);		// TR (write) & STT

    /*
     * get 1st TxIFG
     *
     * The MSP432 is double buffered.  1st TxIFG will show up shortly after
     * TxSTT has been sent (both buffers empty).   We write the first byte
     * (the reg addr), it gets moved to the output buffer (shift register) and
     * will start to be clocked out.   2nd TxIFG will show at this point.
     * This is when we want to turn the bus around so we can start to receive
     * bytes.  (Send a Restart (assert TxSTT again, but this time indicate
     * receiving)).   This will occur after the current outgoing byte (in
     * the outbound serial register) has been ACK'd.
     */

    if ((rtn = wait_ifg(EUSCI_B_IFG_TXIFG)))
      return rtn;
    call Usci.setTxbuf(reg);			// write register address

    /* looking for 2nd TxIFG */
    if ((rtn = wait_ifg(EUSCI_B_IFG_TXIFG)))		// says 1st byte got ack'd
      return rtn;

    /*
     * Turn the bus around with a Restart.
     */
    call Usci.setReceiveMode();			// clears CTR
    call Usci.setTxStart();

    /* wait for the TxStart to go away */
    if ((rtn = wait_deassert_ctlw0(EUSCI_B_CTLW0_TXSTT)))
      return rtn;

    /*
     * RX is doubled buffered.   There is the incoming shift register (SR)
     * which feeds the actual RXBUF.  When rxbuf is loaded rxifg is asserted.
     *
     * After rxbuf is loaded, the next byte will start to be clocked into
     * SR.  If rxbuf hasn't been emptied by the time 7 bit times have gone
     * by, the state machine will stop clocking (scl will be low) until
     * rxbuf gets emptied.
     *
     * What happens if we assert TxStop when we are holding off the receiver?
     */
    while (left) {
      if ((rtn = wait_ifg(EUSCI_B_IFG_RXIFG)))
	return rtn;
      left--;

      /*
       * If there is only one more byte left, then set stop.
       * The state machine will have already started to receive
       * into the SR so the last byte is on the fly.
       *
       * If the state machine hung (on bit 7, scl low), setting
       * TxStop prior to pulling the last byte will issue the
       * Stop after this last byte.
       *
       * The order of setting txStop and pulling the Rxbuf byte
       * is important.
       */
      if (left == 1)
	call Usci.setTxStop();
      *buf++ = call Usci.getRxbuf();
    }
    if ((rtn = wait_deassert_ctlw0(EUSCI_B_CTLW0_TXSTP)))
      return rtn;
    return SUCCESS;
  }


  /*
   * reg_write:
   *
   * START (w/ device addr, in i2csa), transmit
   * 1st write the reg addr
   * write byte (reg contents)
   * finish
   */
  async command error_t I2CReg.reg_write(uint16_t sa,
						    uint8_t reg, uint8_t val) {
    error_t rtn;

    if ((rtn = start_check_busy()))
      return rtn;
    call Usci.setI2Csa(sa);

    /* We want to write the regAddr, send the SA and then write regAddr */
    call Usci.orCtlw0(EUSCI_B_CTLW0_TR | EUSCI_B_CTLW0_TXSTT);		// TR (write) & STT

    /*
     * get 1st TxIFG
     *
     * The MSP432 is double buffered.  1st TxIFG will show up shortly after
     * TxSTT has been sent (both buffers empty).   We write the first byte
     * (the reg addr), it gets moved to the output buffer (shift register) and
     * will start to be clocked out.   2nd TxIFG will show at this point.
     * This is when we want to turn the bus around so we can receive the
     * byte coming back.
     */

    if ((rtn = wait_ifg(EUSCI_B_IFG_TXIFG)))		// wait for txstart to finish
      return rtn;

    call Usci.setTxbuf(reg);			// write register address
    if ((rtn = wait_ifg(EUSCI_B_IFG_TXIFG)))		// says reg addr got ack'd
      return rtn;

    /*
     * write one byte
     *
     * We've got an existing TxIFG, so we have room.  Write the new value
     * and wait until it gets moved into the shift register (TxIfg will come
     * up when this happens).  Then set TxStop to finish.
     */
    call Usci.setTxbuf(val);
    if ((rtn = wait_ifg(EUSCI_B_IFG_TXIFG)))		// says val got ack'd
      return rtn;

    call Usci.setTxStop();
    if ((rtn = wait_deassert_ctlw0(EUSCI_B_CTLW0_TXSTP)))
      return rtn;
    return SUCCESS;
  }


  async command error_t I2CReg.reg_write16(uint16_t sa,
						      uint8_t reg, uint16_t val) {
    error_t rtn;

    if ((rtn = start_check_busy()))
      return rtn;
    call Usci.setI2Csa(sa);

    /* We want to write the regAddr, send the SA and then write regAddr */
    call Usci.orCtlw0(EUSCI_B_CTLW0_TR | EUSCI_B_CTLW0_TXSTT);		// TR (write) & STT

    /*
     * get 1st TxIFG
     *
     * The MSP432 is double buffered.  1st TxIFG will show up shortly after
     * TxSTT has been sent (both buffers empty).   We write the first byte
     * (the reg addr), it gets moved to the output buffer (shift register) and
     * will start to be clocked out.   2nd TxIFG will show at this point.
     * This is when we want to turn the bus around so we can receive the
     * byte coming back.
     */

    if ((rtn = wait_ifg(EUSCI_B_IFG_TXIFG)))
      return rtn;
    call Usci.setTxbuf(reg);			// write register address

    /* looking for 2nd TxIFG */
    if ((rtn = wait_ifg(EUSCI_B_IFG_TXIFG)))		// says reg addr got ack'd
      return rtn;

    /*
     * write first byte, we do msb first.
     * We've got an existing TxIFG, so we have room.
     */
    call Usci.setTxbuf(val >> 8);		// msb part
    if ((rtn = wait_ifg(EUSCI_B_IFG_TXIFG)))		// says 1st byte got ack'd
      return rtn;

    /*
     * send 2nd, but wait until it is in the shift register
     * before sending Stop
     */
    call Usci.setTxbuf(val & 0xff);		// lsb part
    if ((rtn = wait_ifg(EUSCI_B_IFG_TXIFG)))
      return rtn;

    call Usci.setTxStop();
    if ((rtn = wait_deassert_ctlw0(EUSCI_B_CTLW0_TXSTP)))
      return rtn;
    return SUCCESS;
  }


  async command error_t I2CReg.reg_writeBlock(uint16_t sa,
				uint8_t reg, uint8_t num_bytes, uint8_t *buf) {
    uint16_t left;
    error_t  rtn;

    if (num_bytes == 0 || buf == NULL)
      return EINVAL;

    left = num_bytes;

    if ((rtn = start_check_busy()))
      return rtn;
    call Usci.setI2Csa(sa);

    /* writing (will write regAddr), send start */
    call Usci.orCtlw0(EUSCI_B_CTLW0_TR | EUSCI_B_CTLW0_TXSTT);		// TR (write) & STT

    /*
     * get 1st TxIFG
     *
     * The MSP432 is double buffered.  1st TxIFG will show up shortly after
     * TxSTT has been sent (both buffers empty).   We write the first byte
     * (the reg addr), it gets moved to the output buffer (shift register) and
     * will start to be clocked out.   2nd TxIFG will show at this point.
     * This is when we want to turn the bus around so we can start to receive
     * bytes.  (Send a Restart (assert TxSTT again, but this time indicate
     * receiving)).   This will occur after the current outgoing byte (in
     * the outbound serial register) has been ACK'd.
     */

    if ((rtn = wait_ifg(EUSCI_B_IFG_TXIFG)))
      return rtn;
    call Usci.setTxbuf(reg);			// write register address

    while (left) {
      if ((rtn = wait_ifg(EUSCI_B_IFG_TXIFG)))		// says previous byte got ack'd
	return rtn;

      left--;
      call Usci.setTxbuf(*buf++);
    }
    /*
     * we have to wait until the last byte written actually
     * makes it into the SR before setting Stop.
     */
    if ((rtn = wait_ifg(EUSCI_B_IFG_TXIFG)))
      return rtn;
    call Usci.setTxStop();
    if ((rtn = wait_deassert_ctlw0(EUSCI_B_CTLW0_TXSTP)))
      return rtn;
    return SUCCESS;
  }


  command error_t Init.init() {
    configure_(call Msp432UsciConfigure.getConfiguration());
    call Usci.enableModuleInterrupt();
    return SUCCESS;
  }


  command error_t Init.init() {
    configure_(call Msp432UsciConfigure.getConfiguration());
    call Usci.enableModuleInterrupt();
    return SUCCESS;
  }


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
