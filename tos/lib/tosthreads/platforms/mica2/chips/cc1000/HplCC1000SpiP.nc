// $Id: HplCC1000SpiP.nc,v 1.1 2008-06-12 14:02:43 klueska Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
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
 */


module HplCC1000SpiP {
  provides interface Init as PlatformInit;
  provides interface HplCC1000Spi;
  //uses interface PowerManagement;
  uses {
    interface GeneralIO as SpiSck;
    interface GeneralIO as SpiMiso;
    interface GeneralIO as SpiMosi;
    interface GeneralIO as OC1C;
    interface PlatformInterrupt;
  }
}
implementation
{
  uint8_t outgoingByte;

  command error_t PlatformInit.init() {
    call SpiSck.makeInput();
    call OC1C.makeInput();
    call HplCC1000Spi.rxMode();
    return SUCCESS;
  }

  AVR_ATOMIC_HANDLER(SIG_SPI) {
    register uint8_t temp = SPDR;
    SPDR = outgoingByte;
    signal HplCC1000Spi.dataReady(temp);
    call PlatformInterrupt.postAmble();
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
