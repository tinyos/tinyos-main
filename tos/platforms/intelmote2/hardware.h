/*
 * Copyright (c) 2005 Arched Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arched Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/*
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 */
/*
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * @Author Philip Buonadonna
 * @Author Robbie Adler
 *
 */

#ifndef __TOSH_HARDWARE_H__
#define __TOSH_HARDWARE_H__

#include "pxa27xhardware.h"
//#include "AM.h"

// enum so components can override power saving,
// as per TEP 112.
// Note that currently the pxa27x does not support
// McuPowerOverride, so SLEEP_NONE is defined to
// be 0.
enum {
  TOS_SLEEP_NONE = 0,
};

#define MIN(a,b) ((a) < (b) ? (a) : (b))

/* Watchdog Prescaler
 */
enum {
  TOSH_period16 = 0x00, // 47ms
  TOSH_period32 = 0x01, // 94ms
  TOSH_period64 = 0x02, // 0.19s
  TOSH_period128 = 0x03, // 0.38s
  TOSH_period256 = 0x04, // 0.75s
  TOSH_period512 = 0x05, // 1.5s
  TOSH_period1024 = 0x06, // 3.0s
  TOSH_period2048 = 0x07 // 6.0s
};

/* Global interrupt priority table. 
 *    Table is indexed by the Peripheral ID (PPID). Priorities are 0 - 39
 *    where 0 is the highest.  Priorities MUST be unique. 0XFF = invalid/unassigned
 */
const uint8_t TOSH_IRP_TABLE[] = { 0x05, // PPID  0 SSP_3 Service Req
				   0xFF, // PPID  1 MSL
				   0xFF, // PPID  2 USBH2
				   0xFF, // PPID  3 USBH1
				   0xFF, // PPID  4 Keypad
				   0xFF, // PPID  5 Memory Stick
				   0xFF, // PPID  6 Power I2C
				   0x04, // PPID  7 OST match Register 4-11
				   0x01, // PPID  8 GPIO_0
				   0x03, // PPID  9 GPIO_1
				   0x02, // PPID 10 GPIO_x
				   0x08, // PPID 11 USBC
				   0xFF, // PPID 12 PMU
				   0xFF, // PPID 13 I2S
				   0xFF, // PPID 14 AC '97
				   0xFF, // PPID 15 SIM status/error
				   0xFF, // PPID 16 SSP_2 Service Req
				   0xFF, // PPID 17 LCD Controller Service Req
				   0xFF, // PPID 18 I2C Service Req
				   0xFF, // PPID 19 TX/RX ERROR IRDA
				   0x07, // PPID 20 TX/RX ERROR STUART
				   0xFF, // PPID 21 TX/RX ERROR BTUART
				   0x06, // PPID 22 TX/RX ERROR FFUART
				   0xFF, // PPID 23 Flash Card status/Error Detect
				   0x0A, // PPID 24 SSP_1 Service Req
				   0x00, // PPID 25 DMA Channel Service Req
				   0xFF, // PPID 26 OST equals Match Register 0
				   0xFF, // PPID 27 OST equals Match Register 1
				   0xFF, // PPID 28 OST equals Match Register 2
				   0xFF, // PPID 29 OST equals Match Register 3
				   0xFF, // PPID 30 RTC One HZ TIC
				   0xFF, // PPID 31 RTC equals Alarm
				   0xFF, // PPID 32
				   0x09, // PPID 33 Quick Capture Interface
				   0xFF, // PPID 34
				   0xFF, // PPID 35
				   0xFF, // PPID 36
				   0xFF, // PPID 37
				   0xFF, // PPID 38
				   0xFF  // PPID 39
};

#ifdef IMOTE2_DEVBOARD 

// LED assignments
#define RED_LED_PIN (95)
#define GREEN_LED_PIN (102)
#define BLUE_LED_PIN (27)

// CC2420 RADIO #defines
#define CC2420_VREN_PIN (40)
#define CC2420_RSTN_PIN (22)
#define CC2420_FIFO_PIN (114)
#define CC2420_CCA_PIN (116)
#define CC2420_FIFOP_PIN (115)
#define CC2420_SFD_PIN (16)
#define CC2420_CSN_PIN (39)

#else

// LED assignments
#define RED_LED_PIN (103)
#define GREEN_LED_PIN (104)
#define BLUE_LED_PIN (105)

// CC2420 RADIO #defines
#define CC2420_VREN_PIN (115)
#define CC2420_RSTN_PIN (22)
#define CC2420_FIFO_PIN (114)
#define CC2420_CCA_PIN (116)
#define CC2420_FIFOP_PIN (0)
#define CC2420_SFD_PIN (16)
#define CC2420_CSN_PIN (39)

#endif /* IMOTE2_DEVBOARD */

#define SSP3_RXD (41)
#define SSP3_RXD_ALTFN (3)
#define SSP3_TXD (35)
#define SSP3_TXD_ALTFN (3)
#define SSP3_SFRM (39)
#define SSP3_SFRM_ALTFN (3)
#define SSP3_SCLK (34)
#define SSP3_SCLK_ALTFN (3)

#define SSP1_RXD (26)
#define SSP1_RXD_ALTFN (1 )
#define SSP1_TXD (25)
#define SSP1_TXD_ALTFN (2 )
#define SSP1_SCLK (23)
#define SSP1_SCLK_ALTFN (2 )
#define SSP1_SFRM (24)
#define SSP1_SFRM_ALTFN (2 )

#define FFUART_RXD (96)
#define FFUART_RXD_ALTFN (3)
#define FFUART_TXD (99) 
#define FFUART_TXD_ALTFN (3)

#define STUART_RXD (46)
#define STUART_RXD_ALTFN (2)
#define STUART_TXD (47) 
#define STUART_TXD_ALTFN (1)

#define I2C_SCL (117)
#define I2C_SCL_ALTFN (1)
#define I2C_SDA (118)
#define I2C_SDA_ALTFN (1)

#define DS2745_SLAVE_ADDR (0x48)

#if 0
TOSH_ASSIGN_PIN(CC_VREN,A,CC_VREN_PIN); 
TOSH_ASSIGN_PIN(CC_RSTN,A,CC_RSTN_PIN);
TOSH_ASSIGN_PIN(CC_FIFO,A,CC_FIFO_PIN);
TOSH_ASSIGN_PIN(RADIO_CCA,A,RADIO_CCA_PIN);
TOSH_ASSIGN_PIN(CC_FIFOP,A,CC_FIFOP_PIN);
TOSH_ASSIGN_PIN(CC_SFD,A,CC_SFD_PIN);
TOSH_ASSIGN_PIN(CC_CSN,A,CC_CSN_PIN);
#endif

void TOSH_SET_PIN_DIRECTIONS(void)
{

  PSSR = (PSSR_RDH | PSSR_PH);   // Reenable the GPIO buffers (needed out of reset)
#if 0
  TOSH_CLR_CC_RSTN_PIN();
  TOSH_MAKE_CC_RSTN_OUTPUT();
  TOSH_CLR_CC_VREN_PIN();
  TOSH_MAKE_CC_VREN_OUTPUT();
  TOSH_SET_CC_CSN_PIN();
  TOSH_MAKE_CC_CSN_OUTPUT();
  TOSH_MAKE_CC_FIFOP_INPUT();
  TOSH_MAKE_CC_FIFO_INPUT();
  TOSH_MAKE_CC_SFD_INPUT();
  TOSH_MAKE_RADIO_CCA_INPUT();
#endif
}


#endif //TOSH_HARDWARE_H
