/// $Id: Atm128Spi.nc,v 1.4 2006-12-12 18:23:04 vlahan Exp $ 

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
 * HPL-level access to the Atmega128 SPI bus. Refer to pages 162-9
 * of the Atmega128 datasheet (rev. 2467M-AVR-11/04) for details.
 *
 * <pre>
 *  $Id: Atm128Spi.nc,v 1.4 2006-12-12 18:23:04 vlahan Exp $
 * </pre>
 *
 * @author Philip Levis
 * @author Martin Turon <mturon@xbow.com>
 * @date   September 8 2005
 */

#include "Atm128Spi.h"

interface Atm128Spi {

  /* Modal functions */

  /** Initialize the ATmega128 SPI bus into master mode. */
  async command void initMaster();

  /** Initialize the ATmega128 SPI bus into slave mode. */
  async command void initSlave();

  /** Disable and sleep the ATmega128 SPI bus. */
  async command void sleep();
  
  /* SPDR: SPI Data Register */

  /** 
   * Read the SPI data register 
   * @return last data byte
   */
  async command uint8_t read();

  /** 
   * Write the SPI data register 
   * @param data   next data byte
   */
  async command void write(uint8_t data);

  /**
   * Interrupt signalling SPI data cycle is complete. 
   * @param data   data byte from data register
   */
  async event   void dataReady(uint8_t data);
  
  /* SPCR: SPI Control Register */
  /* SPIE bit */
  async command void enableInterrupt(bool enabled);
  async command bool isInterruptEnabled();
  /* SPI bit */
  async command void enableSpi(bool busOn);
  async command bool isSpiEnabled();
  /* DORD bit */
  async command void setDataOrder(bool lsbFirst);
  async command bool isOrderLsbFirst();
  /* MSTR bit */
  async command void setMasterBit(bool isMaster);
  async command bool isMasterBitSet();
  /* CPOL bit */
  async command void setClockPolarity(bool highWhenIdle);
  async command bool getClockPolarity();
  /* CPHA bit */
  async command void setClockPhase(bool sampleOnTrailing);
  async command bool getClockPhase();
  /* SPR1 and SPR0 bits */
  async command void  setClock(uint8_t speed);
  async command uint8_t getClock();
  
  /* SPSR: SPI Status Register */
  
  /* SPIF bit */
  async command bool isInterruptPending();
  /* WCOL bit */
  async command bool hasWriteCollided();
  /* SPI2X bit */
  async command bool isMasterDoubleSpeed();
  async command void setMasterDoubleSpeed(bool on);
}
