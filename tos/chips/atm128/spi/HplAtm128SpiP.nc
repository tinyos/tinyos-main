/// $Id: HplAtm128SpiP.nc,v 1.7 2010-06-29 22:07:43 scipio Exp $

/*
 * Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
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
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of Crossbow Technology nor the names of
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
