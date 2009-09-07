// $Id: M16c62pAdc.h,v 1.1 2009-09-07 14:12:25 r-studio Exp $

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

#ifndef __H_M16C62PADC_H__
#define __H_M16C62PADC_H__

//================== 8 channel 10-bit ADC ==============================

/* Voltage Reference Settings */
enum {
    M16c62p_ADC_VREF_OFF = 0, //!< VR+ = AREF   and VR- = GND
    M16c62p_ADC_VREF_AVCC = 1,//!< VR+ = AVcc   and VR- = GND
};

/* Voltage Reference Settings */
enum {
    M16c62p_ADC_RIGHT_ADJUST = 0,
    M16c62p_ADC_LEFT_ADJUST = 1,
};


/* ADC Channel Settings */
enum {
    M16c62p_ADC_CHL_AN0 = 0,
    M16c62p_ADC_CHL_AN1,
    M16c62p_ADC_CHL_AN2,
    M16c62p_ADC_CHL_AN3,
    M16c62p_ADC_CHL_AN4,
    M16c62p_ADC_CHL_AN5,
    M16c62p_ADC_CHL_AN6,
    M16c62p_ADC_CHL_AN7,
    M16c62p_ADC_CHL_AN10 = 8,
    M16c62p_ADC_CHL_AN11,
    M16c62p_ADC_CHL_AN12,
    M16c62p_ADC_CHL_AN13,
    M16c62p_ADC_CHL_AN14,
    M16c62p_ADC_CHL_AN15,
    M16c62p_ADC_CHL_AN16,
    M16c62p_ADC_CHL_AN17,

};

/* ADC Control Register 0 */
typedef struct
{
    uint8_t ch012   : 3;  //!< Analog Channel and Gain Selection Bits
    uint8_t md01   : 2;  //!< ADC operation mode select bit
    uint8_t trg : 1;  //!< Trigger select bit
    uint8_t adst  : 1;  //!< ADC start flag
    uint8_t cks0  :1;  //!< Frequency Selection Bit 0
} M16c62pADCON0_t;

/* ADC Control Register 1 */
typedef struct
{
    uint8_t scan01  : 2;  //!< ADC scan mode select bit
    uint8_t md2  : 1;  //!< ADC operation mode select bit 1
    uint8_t bits  : 1;  //!< 8/10-bit mode select bit
    uint8_t cks1  : 1;  //!< Frequency select bit 1
    uint8_t vcut  : 1;  //!< Vref connect bit
    uint8_t opa01  : 2;  //!< External op-amp connection mode bit
} M16c62pADCON1_t;

/* ADC Control Register 2 */
typedef struct
{
    uint8_t smp  : 1;  //!< ADC method select bit
    uint8_t adgsel01  : 2;  //!< port group select: 00 select P10 group
                            //                      01 select NULL
                            //                      10 select P0 group
                            //                      11 select P2 group
    uint8_t bit3  : 1;  //!< reserved bit (always set to 0)
    uint8_t cks2  : 1;  //!< Frequency select bit 2
    uint8_t bit5  : 1;  //!< nothing assigned.
    uint8_t bit6  : 1;  //!< nothing assigned.
    uint8_t bit7  : 1;  //!< nothing assigned.
} M16c62pADCON2_t;

/* ADC Prescaler Settings */
/* Note: each platform must define M16c62p_ADC_PRESCALE to the smallest
   prescaler which guarantees full A/D precision. */
enum {
    M16c62p_ADC_PRESCALE_2 = 1,
    M16c62p_ADC_PRESCALE_3 = 6,
    M16c62p_ADC_PRESCALE_4 = 0,
    M16c62p_ADC_PRESCALE_6 = 5,
    M16c62p_ADC_PRESCALE_12 = 4,

    // This special value is used to ask the platform for the prescaler
    // which gives full precision.
    M16c62p_ADC_PRESCALE = 2,
};

/* ADC Precision Settings */
enum {
    M16c62p_ADC_PRECISION_10BIT = 0,
    M16c62p_ADC_PRECISION_8BIT,
};

/* ADC operation mode select bit */
enum {
    M16c62p_ADC_ONESHOT_MODE = 0,
    M16c62p_ADC_REPEAT_MODE,
};

/* ADC Enable Settings */
enum {
    M16c62p_ADC_ENABLE_OFF = 0,
    M16c62p_ADC_ENABLE_ON,
};

/* ADC Start Conversion Settings */
enum {
    M16c62p_ADC_START_CONVERSION_OFF = 0,
    M16c62p_ADC_START_CONVERSION_ON,
};

/* ADC Free Running Select Settings */
enum {
    M16c62p_ADC_FREE_RUNNING_OFF = 0,
    M16c62p_ADC_FREE_RUNNING_ON,
};

/* ADC Interrupt Flag Settings */
enum {
    M16c62p_ADC_INT_FLAG_OFF = 0,
    M16c62p_ADC_INT_FLAG_ON,
};

/* ADC Interrupt Enable Settings */
enum {
    M16c62p_ADC_INT_ENABLE_OFF = 0,
    M16c62p_ADC_INT_ENABLE_ON,
};


typedef uint8_t M16c62p_ADCH_t;         //!< ADC data register high
typedef uint8_t M16c62p_ADCL_t;         //!< ADC data register low

// The resource identifier string for the ADC subsystem
#define UQ_M16c62pADC_RESOURCE "M16c62padc.resource"

#endif //  __H_M16C62PADC_H_

