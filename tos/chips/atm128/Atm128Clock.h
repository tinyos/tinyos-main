// $Id: Atm128Clock.h,v 1.4 2006-12-12 18:23:02 vlahan Exp $

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

#ifndef _H_ATM128CLOCK_H
#define _H_ATM128CLOCK_H

//====================== Oscillators ==================================

/* Timer Clock Select -- set via Fuses only through ISP */
enum {
  ATM128_CKSEL_EXT_CLK = 0,        //!< External clock source
  ATM128_CKSEL_INT_1MHZ = 1,       //!< Internal RC oscillator
  ATM128_CKSEL_INT_2MHZ,
  ATM128_CKSEL_INT_4MHZ,
  ATM128_CKSEL_INT_8MHZ,
  ATM128_CKSEL_EXT_RC_1MHZ = 5,    //!< External RC oscillator
  ATM128_CKSEL_EXT_RC_3MHZ,
  ATM128_CKSEL_EXT_RC_8MHZ,
  ATM128_CKSEL_EXT_RC_12MHZ,
  ATM128_CKSEL_EXT_CRYSTAL = 9,     //!< External low freq crystal
  ATM128_CKSEL_EXT_RES_1MHZ = 10,   //!< External resonator
  ATM128_CKSEL_EXT_RES_3MHZ,
  ATM128_CKSEL_EXT_RES_8MHZ
};

/* 
 * Calibration Register for Internal Oscillator
 *
 * OSCCAL      Min Freq         Max Freq
 * 0x00        50%              100%
 * 0x7F        75%              150%
 * 0xFF        100%             200%
 */
typedef uint8_t Atm128_OSCCAL_t;  //!< Internal Oscillator Calibration Register

/* 8-bit Clock Divider Register */
typedef struct
{
  uint8_t xdiven : 1;  //!< Enable clock divider
  uint8_t xdiv   : 7;  //!< fCLK = Source Clock / 129 - xdiv
} Atm128ClockDivider_t;

typedef Atm128ClockDivider_t Atm128_XTAL_t;  //!< Asynchronous Clock Divider


#endif //_H_ATM128CLOCK_H

