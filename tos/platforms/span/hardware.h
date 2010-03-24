/*
 * Copyright (c) 2009, Shimmer Research, Ltd.
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of Shimmer Research, Ltd. nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  @author  Steve Ayer
 *  @date    May, 2009
 */

#ifndef _H_hardware_h
#define _H_hardware_h

#include "msp430hardware.h"

//#include "CC2420Const.h"

// enum so components can override power saving,
// as per TEP 112.
enum {
  TOS_SLEEP_NONE = MSP430_POWER_ACTIVE,
};

TOSH_ASSIGN_PIN(GREEN_LED,  4, 3);

// CC2420 RADIO #defines
TOSH_ASSIGN_PIN(RADIO_FIFOP,     2, 3);
TOSH_ASSIGN_PIN(RADIO_FIFO,      2, 4);
TOSH_ASSIGN_PIN(RADIO_CCA,       2, 6);
TOSH_ASSIGN_PIN(RADIO_SFD,       2, 7);

TOSH_ASSIGN_PIN(RADIO_VREF,      5, 5);   

TOSH_ASSIGN_PIN(RADIO_SIMO1,     5, 1);
TOSH_ASSIGN_PIN(RADIO_SOMI1,     5, 2);
TOSH_ASSIGN_PIN(RADIO_CSN,       5, 4);
TOSH_ASSIGN_PIN(RADIO_RESET,     3, 3);

// for mainstream tos...
TOSH_ASSIGN_PIN(CC_FIFOP, 2, 3);
TOSH_ASSIGN_PIN(CC_FIFO,  2, 4);
TOSH_ASSIGN_PIN(CC_SFD,   2, 7);
TOSH_ASSIGN_PIN(CC_VREN,  5, 5);
TOSH_ASSIGN_PIN(CC_RSTN,  3, 3);


// UART pins
// SPI1 attached to cc2420
TOSH_ASSIGN_PIN(UCLK1, 5, 3);
TOSH_ASSIGN_PIN(SOMI1, 5, 2);
TOSH_ASSIGN_PIN(SIMO1, 5, 1);

// 1-Wire
TOSH_ASSIGN_PIN(ONEWIRE, 5, 6);

//BSL Pins
TOSH_ASSIGN_PIN(PROG_OUT,  1, 1);
TOSH_ASSIGN_PIN(PROG_IN,   2, 2);

// ADC lines on the testpoints
TOSH_ASSIGN_PIN(ADC_7,   6, 7);
TOSH_ASSIGN_PIN(DAC1_AN, 6, 7);

// connected to external UART 
TOSH_ASSIGN_PIN(UTXD0, 3, 4);
TOSH_ASSIGN_PIN(URXD0, 3, 5);
TOSH_ASSIGN_PIN(UTXD1, 3, 6);
TOSH_ASSIGN_PIN(URXD1, 3, 7);

// GIO pins
TOSH_ASSIGN_PIN(SER0_RTS, 1, 3);
TOSH_ASSIGN_PIN(SER0_CTS, 1, 4);

TOSH_ASSIGN_PIN(ROSC, 2, 5);

TOSH_ASSIGN_PIN(GIO0, 1, 0);
TOSH_ASSIGN_PIN(GIO1, 1, 5);
TOSH_ASSIGN_PIN(GIO2, 1, 6);

TOSH_ASSIGN_PIN(FTDI_ADBUS_7, 1, 2);
TOSH_ASSIGN_PIN(FTDI_ADBUS_3, 2, 0);

/*
 * NC Pins below
 */
TOSH_ASSIGN_PIN(NC_GIO0,     1, 7);
TOSH_ASSIGN_PIN(NC_GIO1,     2, 1);
TOSH_ASSIGN_PIN(NC_CS,       3, 0);
TOSH_ASSIGN_PIN(SIMO0,       3, 1);
TOSH_ASSIGN_PIN(SOMI0,       3, 2);
TOSH_ASSIGN_PIN(UCLK0,       3, 3);
TOSH_ASSIGN_PIN(NC_LED0,     4, 0);
TOSH_ASSIGN_PIN(NC_LED1,     4, 1);
TOSH_ASSIGN_PIN(NC_LED2,     4, 2);
TOSH_ASSIGN_PIN(NC_ACCEL0,   4, 4);
TOSH_ASSIGN_PIN(NC_ACCEL1,   4, 5);
TOSH_ASSIGN_PIN(NC_ACCELS,   4, 6);
TOSH_ASSIGN_PIN(NC_TB0,      4, 7);
TOSH_ASSIGN_PIN(NC_GIO2,     5, 0);
TOSH_ASSIGN_PIN(NC_SVS,      5, 7);
TOSH_ASSIGN_PIN(NC_ADC_0,    6, 0);
TOSH_ASSIGN_PIN(NC_ADC_1,    6, 1);
TOSH_ASSIGN_PIN(NC_ADC_2,    6, 2);
TOSH_ASSIGN_PIN(NC_ADC_3,    6, 3);
TOSH_ASSIGN_PIN(NC_ADC_4,    6, 4);
TOSH_ASSIGN_PIN(NC_ADC_5,    6, 5);
TOSH_ASSIGN_PIN(NC_ADC_6,     6, 6);

#endif // _H_hardware_h

