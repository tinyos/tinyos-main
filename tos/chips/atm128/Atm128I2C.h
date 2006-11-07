// $Id: Atm128I2C.h,v 1.3 2006-11-07 19:30:43 scipio Exp $

/*
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
