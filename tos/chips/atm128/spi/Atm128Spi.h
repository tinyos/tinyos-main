// $Id: Atm128Spi.h,v 1.5 2010-06-29 22:07:43 scipio Exp $

/*
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

// @author Martin Turon <mturon@xbow.com>

#ifndef _H_Atm128SPI_h
#define _H_Atm128SPI_h

//====================== SPI Bus ==================================

enum {
  ATM128_SPI_CLK_DIVIDE_4 = 0,
  ATM128_SPI_CLK_DIVIDE_16 = 1,
  ATM128_SPI_CLK_DIVIDE_64 = 2,
  ATM128_SPI_CLK_DIVIDE_128 = 3,
};

/* SPI Control Register */
typedef struct {
  uint8_t spie  : 1;  //!< SPI Interrupt Enable
  uint8_t spe   : 1;  //!< SPI Enable
  uint8_t dord  : 1;  //!< SPI Data Order
  uint8_t mstr  : 1;  //!< SPI Master/Slave Select
  uint8_t cpol  : 1;  //!< SPI Clock Polarity
  uint8_t cpha  : 1;  //!< SPI Clock Phase
  uint8_t spr   : 2;  //!< SPI Clock Rate

} Atm128SPIControl_s;
typedef union {
  uint8_t flat;
  Atm128SPIControl_s bits;
} Atm128SPIControl_t;

typedef Atm128SPIControl_t Atm128_SPCR_t;  //!< SPI Control Register

/* SPI Status Register */
typedef struct {
  uint8_t spif  : 1;  //!< SPI Interrupt Flag
  uint8_t wcol  : 1;  //!< SPI Write COLision flag
  uint8_t rsvd  : 5;  //!< Reserved
  uint8_t spi2x : 1;  //!< Whether we are in double speed

} Atm128SPIStatus_s;
typedef union {
  uint8_t flat;
  Atm128SPIStatus_s bits;
} Atm128SPIStatus_t;

typedef Atm128SPIStatus_t Atm128_SPSR_t;  //!< SPI Status Register

typedef uint8_t Atm128_SPDR_t;  //!< SPI Data Register

#endif //_H_Atm128SPI_h
