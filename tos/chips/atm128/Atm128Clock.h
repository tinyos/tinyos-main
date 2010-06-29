// $Id: Atm128Clock.h,v 1.5 2010-06-29 22:07:43 scipio Exp $

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

