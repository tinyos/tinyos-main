// $Id: Atm128Adc.h,v 1.1 2007-11-05 20:36:41 sallai Exp $

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
// @author Hu Siquan <husq@xbow.com>

/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */

// @author Janos Sallai <janos.sallai@vanderbilt.edu>

/*
   Updated chips/atm128 to include atm1281's ADCSRB register.
*/

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
    uint8_t adate : 1;  //!< ADC Auto Trigger Enable
    uint8_t adsc  : 1;  //!< ADC Start Conversion
    uint8_t aden  : 1;  //!< ADC Enable
} Atm128Adcsra_t;

/* ADC Multiplexer Selection Register */
typedef struct
{
    uint8_t adts  : 3;  //!< ADC Trigger Select
    uint8_t mux5  : 1;  //!< Analog Channel and Gain Selection Bit
    uint8_t resv1 : 2;  //!< Reserved
    uint8_t acme  : 1;  //!< Analog Comparator Multiplexer Enable
    uint8_t resv2 : 1;  //!< Reserved
} Atm128Adcsrb_t;


typedef uint8_t Atm128_ADCH_t;         //!< ADC data register high
typedef uint8_t Atm128_ADCL_t;         //!< ADC data register low

// The resource identifier string for the ADC subsystem
#define UQ_ATM128ADC_RESOURCE "atm128adc.resource"

#endif //_H_Atm128ADC_h

