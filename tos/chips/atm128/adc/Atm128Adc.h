// $Id: Atm128Adc.h,v 1.6 2010-06-29 22:07:43 scipio Exp $

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
// @author Hu Siquan <husq@xbow.com>

#ifndef _H_Atm128ADC_h
#define _H_Atm128ADC_h

//================== 8 channel 10-bit ADC ==============================

/* Voltage Reference Settings */
enum {
    ATM128_ADC_VREF_OFF = 0, //!< VR+ = AREF   and VR- = GND
    ATM128_ADC_VREF_AVCC = 1,//!< VR+ = AVcc   and VR- = GND
    ATM128_ADC_VREF_RSVD,
    ATM128_ADC_VREF_2_56 = 3,//!< VR+ = 2.56V  and VR- = GND
};

/* Voltage Reference Settings */
enum {
    ATM128_ADC_RIGHT_ADJUST = 0, 
    ATM128_ADC_LEFT_ADJUST = 1,
};


/* ADC Multiplexer Settings */
enum {
    ATM128_ADC_SNGL_ADC0 = 0,
    ATM128_ADC_SNGL_ADC1,
    ATM128_ADC_SNGL_ADC2,
    ATM128_ADC_SNGL_ADC3,
    ATM128_ADC_SNGL_ADC4,
    ATM128_ADC_SNGL_ADC5,
    ATM128_ADC_SNGL_ADC6,
    ATM128_ADC_SNGL_ADC7,
    ATM128_ADC_DIFF_ADC00_10x,
    ATM128_ADC_DIFF_ADC10_10x,
    ATM128_ADC_DIFF_ADC00_200x,
    ATM128_ADC_DIFF_ADC10_200x,
    ATM128_ADC_DIFF_ADC22_10x,
    ATM128_ADC_DIFF_ADC32_10x,
    ATM128_ADC_DIFF_ADC22_200x,
    ATM128_ADC_DIFF_ADC32_200x,
    ATM128_ADC_DIFF_ADC01_1x,
    ATM128_ADC_DIFF_ADC11_1x,
    ATM128_ADC_DIFF_ADC21_1x,
    ATM128_ADC_DIFF_ADC31_1x,
    ATM128_ADC_DIFF_ADC41_1x,
    ATM128_ADC_DIFF_ADC51_1x,
    ATM128_ADC_DIFF_ADC61_1x,
    ATM128_ADC_DIFF_ADC71_1x,
    ATM128_ADC_DIFF_ADC02_1x,
    ATM128_ADC_DIFF_ADC12_1x,
    ATM128_ADC_DIFF_ADC22_1x,
    ATM128_ADC_DIFF_ADC32_1x,
    ATM128_ADC_DIFF_ADC42_1x,
    ATM128_ADC_DIFF_ADC52_1x,
    ATM128_ADC_SNGL_1_23,
    ATM128_ADC_SNGL_GND,
};

/* ADC Multiplexer Selection Register */
typedef struct
{
    uint8_t mux   : 5;  //!< Analog Channel and Gain Selection Bits
    uint8_t adlar : 1;  //!< ADC Left Adjust Result
    uint8_t refs  : 2;  //!< Reference Selection Bits
} Atm128Admux_t;

/* ADC Prescaler Settings */
/* Note: each platform must define ATM128_ADC_PRESCALE to the smallest
   prescaler which guarantees full A/D precision. */
enum {
    ATM128_ADC_PRESCALE_2 = 0,
    ATM128_ADC_PRESCALE_2b,
    ATM128_ADC_PRESCALE_4,
    ATM128_ADC_PRESCALE_8,
    ATM128_ADC_PRESCALE_16,
    ATM128_ADC_PRESCALE_32,
    ATM128_ADC_PRESCALE_64,
    ATM128_ADC_PRESCALE_128,

    // This special value is used to ask the platform for the prescaler
    // which gives full precision.
    ATM128_ADC_PRESCALE
};

/* ADC Enable Settings */
enum {
    ATM128_ADC_ENABLE_OFF = 0,
    ATM128_ADC_ENABLE_ON,
};

/* ADC Start Conversion Settings */
enum {
    ATM128_ADC_START_CONVERSION_OFF = 0,
    ATM128_ADC_START_CONVERSION_ON,
};

/* ADC Free Running Select Settings */
enum {
    ATM128_ADC_FREE_RUNNING_OFF = 0,
    ATM128_ADC_FREE_RUNNING_ON,
};

/* ADC Interrupt Flag Settings */
enum {
    ATM128_ADC_INT_FLAG_OFF = 0,
    ATM128_ADC_INT_FLAG_ON,
};

/* ADC Interrupt Enable Settings */
enum {
    ATM128_ADC_INT_ENABLE_OFF = 0,
    ATM128_ADC_INT_ENABLE_ON,
};

/* ADC Multiplexer Selection Register */
typedef struct
{
    uint8_t adps  : 3;  //!< ADC Prescaler Select Bits
    uint8_t adie  : 1;  //!< ADC Interrupt Enable
    uint8_t adif  : 1;  //!< ADC Interrupt Flag
    uint8_t adfr  : 1;  //!< ADC Free Running Select
    uint8_t adsc  : 1;  //!< ADC Start Conversion
    uint8_t aden  : 1;  //!< ADC Enable
} Atm128Adcsra_t;

typedef uint8_t Atm128_ADCH_t;         //!< ADC data register high
typedef uint8_t Atm128_ADCL_t;         //!< ADC data register low

// The resource identifier string for the ADC subsystem
#define UQ_ATM128ADC_RESOURCE "atm128adc.resource"

#endif //_H_Atm128ADC_h

