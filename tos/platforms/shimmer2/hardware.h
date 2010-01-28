/*
 * Copyright (c) 2007, Intel Corporation
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * Redistributions of source code must retain the above copyright notice, 
 * this list of conditions and the following disclaimer. 
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution. 
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software 
 * without specific prior written permission. 
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * @author Steven Ayer
 * @date   July 2007
 */


#ifndef _H_hardware_h
#define _H_hardware_h

#include "msp430hardware.h"
/*
 * these left from tos-1.x...
 *
 *#include "MSP430ADC12.h"
 *
 *#include "CC2420Const.h"
 */


// LEDs
TOSH_ASSIGN_PIN(RED_LED,    4, 0);
TOSH_ASSIGN_PIN(YELLOW_LED, 4, 2);
TOSH_ASSIGN_PIN(GREEN_LED,  4, 3);

// CC2420 RADIO
TOSH_ASSIGN_PIN(RADIO_FIFO,  1, 5);
TOSH_ASSIGN_PIN(RADIO_FIFOP, 1, 2);
TOSH_ASSIGN_PIN(RADIO_CCA,   2, 7);

// vref is legacy from telos and cc2420 lib; schematic and cc2420 pin say vreg_en
TOSH_ASSIGN_PIN(RADIO_VREF,  5, 6);   

TOSH_ASSIGN_PIN(RADIO_SFD,   1, 0);
TOSH_ASSIGN_PIN(RADIO_SIMO1, 5, 1);
TOSH_ASSIGN_PIN(RADIO_SOMI1, 5, 2);
TOSH_ASSIGN_PIN(RADIO_CSN,   5, 4);
TOSH_ASSIGN_PIN(RADIO_RESET, 5, 7);

// this happens in hplcc2420pinsc
TOSH_ASSIGN_PIN(CC_FIFOP, 1, 2);
TOSH_ASSIGN_PIN(CC_FIFO, 1, 5);
TOSH_ASSIGN_PIN(CC_SFD, 1, 0);
TOSH_ASSIGN_PIN(CC_VREN, 5, 6);
TOSH_ASSIGN_PIN(CC_RSTN, 5, 7);

// BT pins
TOSH_ASSIGN_PIN(BT_PIO,      2, 6);
TOSH_ASSIGN_PIN(BT_RTS,      1, 6);
TOSH_ASSIGN_PIN(BT_CTS,      1, 7);
TOSH_ASSIGN_PIN(BT_TXD,      3, 6);
TOSH_ASSIGN_PIN(BT_RXD,      3, 7);
TOSH_ASSIGN_PIN(BT_RESET,    5, 5);

//BSL Pins
TOSH_ASSIGN_PIN(PROG_OUT,  1, 1);
TOSH_ASSIGN_PIN(PROG_IN,   2, 2);

// SD uart chip-select
TOSH_ASSIGN_PIN(SD_CS_N, 3, 0);

TOSH_ASSIGN_PIN(TILT,  2, 4);

// ADC lines on the testpoints
TOSH_ASSIGN_PIN(ADC_0, 6, 0);
TOSH_ASSIGN_PIN(ADC_1, 6, 1);
TOSH_ASSIGN_PIN(ADC_2, 6, 2);
TOSH_ASSIGN_PIN(ADC_6, 6, 6);
TOSH_ASSIGN_PIN(ADC_7, 6, 7);

TOSH_ASSIGN_PIN(ADC_ACCELZ, 6, 3);
TOSH_ASSIGN_PIN(ADC_ACCELY,  6, 4);
TOSH_ASSIGN_PIN(ADC_ACCELX, 6, 5);

TOSH_ASSIGN_PIN(DAC0_AN, 6, 6);
TOSH_ASSIGN_PIN(DAC1_AN, 6, 7);

TOSH_ASSIGN_PIN(VSENSE_ADC6, 6, 6);
TOSH_ASSIGN_PIN(VSENSE_ADC7,  6, 7);

// bus arbitration pins
TOSH_ASSIGN_PIN(SW_SD_PWR_N, 4, 5);
TOSH_ASSIGN_PIN(SW_BT_PWR_N, 4, 6);

// if used as expansion GPIOs
TOSH_ASSIGN_PIN(SER0_RTS, 1, 3);
TOSH_ASSIGN_PIN(SER0_CTS, 1, 4);

TOSH_ASSIGN_PIN(SIMO0, 3, 1);
TOSH_ASSIGN_PIN(SOMI0, 3, 2);
TOSH_ASSIGN_PIN(UCLK0, 3, 3);
TOSH_ASSIGN_PIN(UTXD0, 3, 4);
TOSH_ASSIGN_PIN(URXD0, 3, 5);

// redefinitions for the sd card driver
TOSH_ASSIGN_PIN(SD_DI, 3, 1);
TOSH_ASSIGN_PIN(SD_DO, 3, 2);
TOSH_ASSIGN_PIN(SD_CLK, 3, 3);


TOSH_ASSIGN_PIN(SIMO1, 5, 1);
TOSH_ASSIGN_PIN(SOMI1, 5, 2);
TOSH_ASSIGN_PIN(UCLK1, 5, 3);
TOSH_ASSIGN_PIN(UTXD1, 3, 6);
TOSH_ASSIGN_PIN(URXD1, 3, 7);

TOSH_ASSIGN_PIN(GIO0, 2, 0);
TOSH_ASSIGN_PIN(GIO1, 2, 1);
TOSH_ASSIGN_PIN(GIO2, 2, 5);  // second internal expansion gpio

// 1-Wire
TOSH_ASSIGN_PIN(ONEWIRE, 4, 7);

// ROSC
TOSH_ASSIGN_PIN(ROSC, 2, 5);

// docked signal from programming board
TOSH_ASSIGN_PIN(DOCK_N, 2, 3);

// ACCEL
TOSH_ASSIGN_PIN(ACCEL_SEL0,  4, 1);
TOSH_ASSIGN_PIN(ACCEL_SEL1,  4, 4);
TOSH_ASSIGN_PIN(ACCEL_SLEEP_N, 5, 0);

#endif // _H_hardware_h

