// $Id: Atm128I2C.h,v 1.5 2010-06-29 22:07:43 scipio Exp $

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

#ifndef _H_Atm128I2C_h
#define _H_Atm128I2C_h

//====================== I2C Bus ==================================

/* SCL freq = CPU freq / (16 + 2(TWBR) * pow(4, TWPR)) */
enum {
  ATM128_I2C_RATE_DIVIDE_16 = 0,
  ATM128_I2C_RATE_DIVIDE_24 = 1,
  ATM128_I2C_RATE_DIVIDE_80 = 2,
}

  typedef uint8_t Atm128_TWBR_t;  //!< Two Wire Bit Rate Register

/* I2C Control Register */
typedef struct
{
  uint8_t twie  : 1;  //!< Two Wire Interrupt Enable
  uint8_t rsvd  : 1;  //!< Reserved
  uint8_t twen  : 1;  //!< Two Wire Enable Bit
  uint8_t twwc  : 1;  //!< Two Wire Write Collision Flag
  uint8_t twsto : 1;  //!< Two Wire Stop Condition Bit
  uint8_t twsta : 1;  //!< Two Wire Start Condition Bit
  uint8_t twea  : 1;  //!< Two Wire Enable Acknowledge Bit
  uint8_t twint : 1;  //!< Two Wire Interrupt Flag
} Atm128I2CControl_t;


typedef Atm128I2CControl_t Atm128_TWCR_t;  //!< Two Wire Control Register

/* SCL freq = CPU freq / (16 + 2(TWBR) * pow(4, TWPR)) */
enum {
  ATM128_I2C_PRESCALE_1 = 0,
  ATM128_I2C_PRESCALE_4 = 1,
  ATM128_I2C_PRESCALE_16 = 2,
  ATM128_I2C_PRESCALE_64 = 3,
};

enum {
  ATM128_I2C_STATUS_START = 1,
};

/* I2C Status Register */
typedef struct
{
  uint8_t twps  : 2;  //!< Two Wire Prescaler Bits
  uint8_t rsvd  : 1;  //!< Reserved
  uint8_t tws   : 5;  //!< Two Wire Status
} Atm128I2CStatus_t;


typedef Atm128I2CStatus_t Atm128_TWCR_t;  //!< Two Wire Status Register

typedef uint8_t Atm128_TWDR_t;  //!< Two Wire Data Register
typedef uint8_t Atm128_TWAR_t;  //!< Two Wire Slave Address Register

#endif //_H_Atm128I2C_h
