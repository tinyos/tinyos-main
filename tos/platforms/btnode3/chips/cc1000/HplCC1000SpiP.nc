// $Id: HplCC1000SpiP.nc,v 1.6 2010-06-29 22:07:52 scipio Exp $

/*
 * Copyright (c) 2006 ETH Zurich.  
 * Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
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
 * - Neither the name of the University of California nor the names of
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Low-level functions to access the CC1000 bus. Built using the mica2
 * hardware SPI.
 *
 * @author Jaein Jeong
 * @author Philip buonadonna
 * @author Jan Beutel
 */


module HplCC1000SpiP {
  provides interface Init as PlatformInit;
  provides interface HplCC1000Spi;
  //uses interface PowerManagement;
  uses {
    interface GeneralIO as SpiSck;
    interface GeneralIO as SpiMiso;
    interface GeneralIO as SpiMosi;
    //interface GeneralIO as OC1C;
  }
}
implementation
{
  uint8_t outgoingByte;

  command error_t PlatformInit.init() {
    call SpiSck.makeInput();
    //call OC1C.makeInput();
    call HplCC1000Spi.rxMode();
    return SUCCESS;
  }

  AVR_ATOMIC_HANDLER(SIG_SPI) {
    register uint8_t temp = SPDR;
    SPDR = outgoingByte;
    signal HplCC1000Spi.dataReady(temp);
  }
  default async event void HplCC1000Spi.dataReady(uint8_t data) { }
  

  async command void HplCC1000Spi.writeByte(uint8_t data) {
    atomic outgoingByte = data;
  }

  async command bool HplCC1000Spi.isBufBusy() {
    return bit_is_clear(SPSR, SPIF);
  }

  async command uint8_t HplCC1000Spi.readByte() {
    return SPDR;
  }

  async command void HplCC1000Spi.enableIntr() {
    //sbi(SPCR,SPIE);
    SPCR = 0xc0;
    CLR_BIT(DDRB, 0);
    //call PowerManagement.adjustPower();
  }

  async command void HplCC1000Spi.disableIntr() {
    CLR_BIT(SPCR, SPIE);
    SET_BIT(DDRB, 0);
    CLR_BIT(PORTB, 0);
    //call PowerManagement.adjustPower();
  }

  async command void HplCC1000Spi.initSlave() {
    atomic {
      CLR_BIT(SPCR, CPOL);		// Set proper polarity...
      CLR_BIT(SPCR, CPHA);		// ...and phase
      SET_BIT(SPCR, SPIE);	// enable spi port
      SET_BIT(SPCR, SPE);
    } 
  }
	
  async command void HplCC1000Spi.txMode() {
    call SpiMiso.makeOutput();
    call SpiMosi.makeOutput();
  }

  async command void HplCC1000Spi.rxMode() {
    call SpiMiso.makeInput();
    call SpiMosi.makeInput();
  }
}
