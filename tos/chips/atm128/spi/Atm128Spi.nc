/// $Id: Atm128Spi.nc,v 1.5 2010-06-29 22:07:43 scipio Exp $ 

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
 * HPL-level access to the Atmega128 SPI bus. Refer to pages 162-9
 * of the Atmega128 datasheet (rev. 2467M-AVR-11/04) for details.
 *
 * <pre>
 *  $Id: Atm128Spi.nc,v 1.5 2010-06-29 22:07:43 scipio Exp $
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
