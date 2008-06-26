/// $Id: HplAtm128SpiP.nc,v 1.6 2008-06-26 04:39:03 regehr Exp $

/*
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. 
 *
 * CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS 
 * ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS ANY 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
 */

/**
 * Implementation of the SPI bus abstraction for the atm128
 * microcontroller.
 *
 * @author Philip Levis
 * @author Martin Turon
 */

#include "Atm128Spi.h"

module HplAtm128SpiP @safe() {
  provides interface Atm128Spi as SPI;
  provides interface AsyncStdControl;
  
  uses {
    interface GeneralIO as SS;   // Slave set line
    interface GeneralIO as SCK;  // SPI clock line
    interface GeneralIO as MOSI; // Master out, slave in
    interface GeneralIO as MISO; // Master in, slave out
    interface McuPowerState as Mcu;
  }
}
implementation {

  async command error_t AsyncStdControl.start() {
    call SPI.enableSpi(TRUE);
  }

  async command error_t AsyncStdControl.stop() {
    call SPI.enableInterrupt(FALSE);
    call SPI.enableSpi(FALSE);
  }
  
  async command void SPI.initMaster() {
    call MOSI.makeOutput();
    call MISO.makeInput();
    call SCK.makeOutput();
    call SPI.setMasterBit(TRUE);
  }

  async command void SPI.initSlave() {
    call MISO.makeOutput();
    call MOSI.makeInput();
    call SCK.makeInput();
    call SS.makeInput();
    call SPI.setMasterBit(FALSE);
  }
  
  async command void SPI.sleep() {
//    call SS.set();	// why was this needed?
  }
  
  async command uint8_t SPI.read()        { return SPDR; }
  async command void SPI.write(uint8_t d) { SPDR = d; }
    
  default async event void SPI.dataReady(uint8_t d) {}
  AVR_ATOMIC_HANDLER(SIG_SPI) {
      signal SPI.dataReady(call SPI.read());
  }

  //=== SPI Bus utility routines. ====================================
  async command bool SPI.isInterruptPending() {
    return READ_BIT(SPSR, SPIF);
  }

  async command bool SPI.isInterruptEnabled () {                
    return READ_BIT(SPCR, SPIE);
  }

  async command void SPI.enableInterrupt(bool enabled) {
    if (enabled) {
      SET_BIT(SPCR, SPIE);
      call Mcu.update();
    }
    else {
      CLR_BIT(SPCR, SPIE);
      call Mcu.update();
    }
  }

  async command bool SPI.isSpiEnabled() {
    return READ_BIT(SPCR, SPE);
  }
  
  async command void SPI.enableSpi(bool enabled) {
    if (enabled) {
      SET_BIT(SPCR, SPE);
      call Mcu.update();
    }
    else {
      CLR_BIT(SPCR, SPE);
      call Mcu.update();
    }
  }

  /* DORD bit */
  async command void SPI.setDataOrder(bool lsbFirst) {
    if (lsbFirst) {
      SET_BIT(SPCR, DORD);
    }
    else {
      CLR_BIT(SPCR, DORD);
    }
  }
  
  async command bool SPI.isOrderLsbFirst() {
    return READ_BIT(SPCR, DORD);
  }
  
  /* MSTR bit */
  async command void SPI.setMasterBit(bool isMaster) {
    if (isMaster) {
      SET_BIT(SPCR, MSTR);
    }
    else {
      CLR_BIT(SPCR, MSTR);
    }
  }
  async command bool SPI.isMasterBitSet() {
    return READ_BIT(SPCR, MSTR);
  }
  
  /* CPOL bit */
  async command void SPI.setClockPolarity(bool highWhenIdle) {
    if (highWhenIdle) {
      SET_BIT(SPCR, CPOL);
    }
    else {
      CLR_BIT(SPCR, CPOL);
    }
  }
  
  async command bool SPI.getClockPolarity() {
    return READ_BIT(SPCR, CPOL);
  }
  
  /* CPHA bit */
  async command void SPI.setClockPhase(bool sampleOnTrailing) {
    if (sampleOnTrailing) {
      SET_BIT(SPCR, CPHA);
    }
    else {
      CLR_BIT(SPCR, CPHA);
    }
  }
  async command bool SPI.getClockPhase() {
    return READ_BIT(SPCR, CPHA);
  }

  
  async command uint8_t SPI.getClock () {                
    return READ_FLAG(SPCR, ((1 << SPR1) | (1 <<SPR0)));
  }
  
  async command void SPI.setClock (uint8_t v) {
    v &= (SPR1) | (SPR0);
    SPCR = (SPCR & ~(SPR1 | SPR0)) | v;
  }

  async command bool SPI.hasWriteCollided() {
    return READ_BIT(SPSR, WCOL);
  }

  async command bool SPI.isMasterDoubleSpeed() {
    return READ_BIT(SPSR, SPI2X);
  }

  async command void SPI.setMasterDoubleSpeed(bool on) {
   if (on) {
      SET_BIT(SPSR, SPI2X);
    }
    else {
      CLR_BIT(SPSR, SPI2X);
    }
  }
}
