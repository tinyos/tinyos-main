/*
 * Copyright (c) 2010-2011 Eric B. Decker
 * Copyright (c) 2009-2010 DEXMA SENSORS SL
 * Copyright (c) 2005-2006 Arch Rock Corporation
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

#include "msp430usci.h"

/*
 * Implementation of Usci_B1 (spi or i2c) lowlevel functionality - stateless.
 * Setting a mode will by default disable USCI-Interrupts.
 *
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * @author: Jonathan Hui <jhui@archedrock.com>
 * @author: Vlado Handziski <handzisk@tkn.tu-berlin.de>
 * @author: Joe Polastre
 * @author: Philipp Huppertz <huppertz@tkn.tu-berlin.de>
 * @author: Xavier Orduna <xorduna@dexmatech.com>
 * @author: Eric B. Decker <cire831@gmail.com>
 * @author: Jordi Soucheiron <jsoucheiron@dexmatech.com>
 *
 * A0, A1: uart, spi, irda.
 * B0, B1: spi, i2c.
 *
 * This module interfaces to usciB1: spi or i2c.
 */

module HplMsp430UsciB1P @safe() {
  provides {
    interface HplMsp430UsciB as Usci;
    interface HplMsp430UsciInterrupts as Interrupts;
  }
  uses {
    interface HplMsp430GeneralIO as SIMO;
    interface HplMsp430GeneralIO as SOMI;
    interface HplMsp430GeneralIO as UCLK;
    interface HplMsp430GeneralIO as USDA;
    interface HplMsp430GeneralIO as USCL;
    interface HplMsp430UsciRawInterrupts as UsciRawInterrupts;
  }
}

implementation {
  MSP430REG_NORACE(UC1IE);
  MSP430REG_NORACE(UC1IFG);
  MSP430REG_NORACE(UCB1CTL0);
  MSP430REG_NORACE(UCB1CTL1);
  MSP430REG_NORACE(UCB1RXBUF);
  MSP430REG_NORACE(UCB1TXBUF);
  MSP430REG_NORACE(UCB1I2COA);
  MSP430REG_NORACE(UCB1I2CIE);

  async event void UsciRawInterrupts.rxDone(uint8_t temp) {
    signal Interrupts.rxDone(temp);
  }

  async event void UsciRawInterrupts.txDone() {
    signal Interrupts.txDone();
  }

  /* Control registers */
  async command void Usci.setUctl0(msp430_uctl0_t control) {
    UCB1CTL0 = uctl02int(control);
  }

  async command msp430_uctl0_t Usci.getUctl0() {
    return int2uctl0(UCB1CTL0);
  }

  async command void Usci.setUctl1(msp430_uctl1_t control) {
    UCB1CTL1 = uctl12int(control);
  }

  async command msp430_uctl1_t Usci.getUctl1() {
    return int2uctl1(UCB1CTL1);
  }

  async command void Usci.setUbr(uint16_t control) {
    atomic {
      UCB1BR0 = control & 0x00FF;
      UCB1BR1 = (control >> 8) & 0x00FF;
    }
  }

  async command uint16_t Usci.getUbr() {
    return (UCB1BR1 << 8) + UCB1BR0;
  }

  async command void Usci.setUstat(uint8_t control) {
    UCB1STAT = control;
  }

  async command uint8_t Usci.getUstat() {
    return UCB1STAT;
  }

  /* Operations */
  async command void Usci.resetUsci(bool reset) {
    if (reset)
      SET_FLAG(UCB1CTL1, UCSWRST);
    else
      CLR_FLAG(UCB1CTL1, UCSWRST);
  }

  bool isSpi() {
    msp430_uctl0_t tmp;

    tmp = int2uctl0(UCB1CTL0);
    return (tmp.ucsync && tmp.ucmode != 3);
  }

  bool isI2C() {
    msp430_uctl0_t tmp;

    tmp = int2uctl0(UCB1CTL0);
    return (tmp.ucsync && tmp.ucmode == 3);
  }

  async command bool Usci.isSpi() {
    return isSpi();
  }

  async command msp430_uscimode_t Usci.getMode() {
    if (isSpi())
      return USCI_SPI;
    if (isI2C())
      return USCI_I2C;
    return USCI_NONE;
  }

  async command void Usci.enableSpi() {
    atomic {
      call SIMO.selectModuleFunc();
      call SOMI.selectModuleFunc();
      call UCLK.selectModuleFunc();
    }
  }

  async command void Usci.disableSpi() {
    atomic {
      call SIMO.selectIOFunc();
      call SOMI.selectIOFunc();
      call UCLK.selectIOFunc();
    }
  }

  void configSpi(msp430_spi_union_config_t* config) {
    UCB1CTL1 = (config->spiRegisters.uctl1 | UCSWRST);
    UCB1CTL0 = (config->spiRegisters.uctl0 | UCSYNC);
    call Usci.setUbr(config->spiRegisters.ubr);
  }

  async command void Usci.setModeSpi(msp430_spi_union_config_t* config) {
    atomic {
      call Usci.disableIntr();
      call Usci.clrIntr();
      call Usci.resetUsci(TRUE);
      call Usci.enableSpi();
      configSpi(config);
      call Usci.resetUsci(FALSE);
    }    
  }

  async command bool Usci.isTxIntrPending(){
    if (UC1IFG & UCB1TXIFG)
      return TRUE;
    return FALSE;
  }

  async command bool Usci.isRxIntrPending() {
    if (UC1IFG & UCB1RXIFG)
      return TRUE;
    return FALSE;
  }

  async command void Usci.clrTxIntr(){
    UC1IFG &= ~UCB1TXIFG;
  }

  async command void Usci.clrRxIntr() {
    UC1IFG &= ~UCB1RXIFG;
  }

  async command void Usci.clrIntr() {
    UC1IFG &= ~(UCB1TXIFG | UCB1RXIFG);
  }

  async command void Usci.disableRxIntr() {
    UC1IE &= ~UCB1RXIE;
  }

  async command void Usci.disableTxIntr() {
    UC1IE &= ~UCB1TXIE;
  }

  async command void Usci.disableIntr() {
    UC1IE &= ~(UCB1TXIE | UCB1RXIE);
  }

  async command void Usci.enableRxIntr() {
    atomic {
      UC1IFG &= ~UCB1RXIFG;
      UC1IE  |=  UCB1RXIE;
    }
  }

  async command void Usci.enableTxIntr() {
    atomic {
      UC1IFG &= ~UCB1TXIFG;
      UC1IE  |=  UCB1TXIE;
    }
  }

  async command void Usci.enableIntr() {
    atomic {
      UC1IFG &= ~(UCB1TXIFG | UCB1RXIFG);
      UC1IE  |= (UCB1TXIE | UCB1RXIE);
    }
  }

  async command void Usci.tx(uint8_t data) {
    UCB1TXBUF = data;
  }

  async command uint8_t Usci.rx() {
    return UCB1RXBUF;
  }

  /*
   * i2c operations
   */
  async command bool Usci.isI2C(){
    return isI2C();
  }

  async command void Usci.enableI2C() {
    atomic {
 #ifdef PLATFORM_Z1
      /* Dirty, needs fixing */
        P5OUT &= ~0x06;
        P5REN &= ~0x06;
        P5OUT |= 0x06;
        P5REN |= 0x06;
      #endif
      call USDA.selectModuleFunc();
      call USCL.selectModuleFunc();
    }
  }

  async command void Usci.disableI2C() {
    atomic {
      call USDA.selectIOFunc();
      call USCL.selectIOFunc();
    }
  }

  void configI2C(msp430_i2c_union_config_t* config) {
    UCB1CTL1 = (config->i2cRegisters.uctl1 | UCSWRST);
    UCB1CTL0 = (config->i2cRegisters.uctl0 | UCSYNC);
    call Usci.setUbr(config->i2cRegisters.ubr);
    UCB1I2COA = config->i2cRegisters.ui2coa;
    UCB1I2CSA = 0;
    UCB1I2CIE = 0;
  }

  async command void Usci.setModeI2C( msp430_i2c_union_config_t* config ) {
    atomic {
      call Usci.disableIntr();
      call Usci.clrIntr();
      call Usci.resetUsci(TRUE);
      call Usci.enableI2C();
      configI2C(config);
      call Usci.resetUsci(FALSE);
    }
  }

  async command uint16_t Usci.getOwnAddress(){
  	return UCB1I2COA & ~UCGCEN;
  }
  
  async command void Usci.setOwnAddress( uint16_t addr ){
	UCB1I2COA &= UCGCEN;
	UCB1I2COA |= (addr & ~UCGCEN);
  }

  /*
   * commands subsummed into config structure.
   *
   * setMasterMode,  setSlaveMode, getTransmitReceiveMode, setTransmitMode,
   * setReceiveMode, getStopBit,   setStopBit,             getStartBit,
   * setStartBit,    
   *
   * the get commands can be replaced by .getUctl0 etc.
   *
   * similar things should be done for the other registers.  It keeps things
   * simple and consise.
   */

  /* set direction of the bus */
  async command void Usci.setTransmitMode() { UCB1CTL1 |=  UCTR; }
  async command void Usci.setReceiveMode()  { UCB1CTL1 &= ~UCTR; }

  /* transmit a NACK, Stop condition, or Start condition, automatically cleared */
  async command void Usci.setTXNACK()  { UCB1CTL1 |= UCTXNACK; }
  async command void Usci.setTXStop()  { UCB1CTL1 |= UCTXSTP;  }
  async command void Usci.setTXStart() { UCB1CTL1 |= UCTXSTT; }

  /* set whether to respond to GeneralCall. */
  async command void Usci.clearGeneralCall() { UCB1I2COA &= ~UCGCEN; }
  async command void Usci.setGeneralCall()   { UCB1I2COA |=  UCGCEN; }

  /* set master/slave mode, i2c */
  async command void Usci.setSlaveMode()  { UCB1CTL0 |=  UCMST; }
  async command void Usci.setMasterMode() { UCB1CTL0 &= ~UCMST; }

  /* get stop bit in i2c mode */
  async command bool Usci.getStartBit() { return (UCB1CTL1 & UCTXSTT); } 
  async command bool Usci.getStopBit() { return (UCB1CTL1 & UCTXSTP); }
  async command bool Usci.getTransmitReceiveMode() { return (UCB1CTL1 & UCTR); }

  /* get/set Slave Address, i2cSA */
  async command uint16_t Usci.getSlaveAddress()            { atomic { return UCB1I2CSA; } }
  async command void Usci.setSlaveAddress( uint16_t addr ) { atomic { UCB1I2CSA = addr; } }

  /* enable/disable NACK interrupt */
  async command void Usci.disableNACKInt() { UCB1I2CIE &= ~UCNACKIE; }
  async command void Usci.enableNACKInt()  { UCB1I2CIE |=  UCNACKIE; }

  /* enable/disable stop condition interrupt */
  async command void Usci.disableStopInt() { UCB1I2CIE &= ~UCSTPIE; }
  async command void Usci.enableStopInt()  { UCB1I2CIE |=  UCSTPIE; }

  /* enable/disable start condition interrupt */
  async command void Usci.disableStartInt() { UCB1I2CIE &= ~UCSTTIE; }
  async command void Usci.enableStartInt()  { UCB1I2CIE |=  UCSTTIE; }

  /* enable/disable arbitration lost interrupt */
  async command void Usci.disableArbLostInt() { UCB1I2CIE &= ~UCALIE; }
  async command void Usci.enableArbLostInt()  { UCB1I2CIE |=  UCALIE; }
}
