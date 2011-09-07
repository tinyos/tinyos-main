/* 
 * Copyright (c) 2006, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.5 $
 * $Date: 2007-06-25 15:47:14 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
 
#ifndef MSP430ADC12_H
#define MSP430ADC12_H
#include "Msp430RefVoltGenerator.h"

#define ADC12_TIMERA_ENABLED
#define ADC12_P6PIN_AUTO_CONFIGURE
#define ADC12_CHECK_ARGS
//#define ADC12_ONLY_WITH_DMA

// for HIL clients 
#define REF_VOLT_AUTO_CONFIGURE

typedef struct { 
  // see README.txt
  unsigned int inch: 4;            // input channel 
  unsigned int sref: 3;            // reference voltage 
  unsigned int ref2_5v: 1;         // reference voltage level 
  unsigned int adc12ssel: 2;       // clock source sample-hold-time 
  unsigned int adc12div: 3;        // clock divider sample-hold-time 
  unsigned int sht: 4;             // sample-hold-time
  unsigned int sampcon_ssel: 2;    // clock source sampcon signal 
  unsigned int sampcon_id: 2;      // clock divider sampcon 
  unsigned int : 0;                // align to a word boundary 
} msp430adc12_channel_config_t;

typedef struct 
{
  // see README.txt
  volatile unsigned
  inch: 4,                                     // input channel
  sref: 3,                                     // reference voltage
  eos: 1;                                      // end of sequence flag
} __attribute__ ((packed)) adc12memctl_t;

enum inch_enum
{  
   // see device specific data sheet which pin Ax is mapped to
   INPUT_CHANNEL_A0 = 0,                    // input channel A0 
   INPUT_CHANNEL_A1 = 1,                    // input channel A1
   INPUT_CHANNEL_A2 = 2,                    // input channel A2
   INPUT_CHANNEL_A3 = 3,                    // input channel A3
   INPUT_CHANNEL_A4 = 4,                    // input channel A4
   INPUT_CHANNEL_A5 = 5,                    // input channel A5
   INPUT_CHANNEL_A6 = 6,                    // input channel A6
   INPUT_CHANNEL_A7 = 7,                    // input channel A7
   EXTERNAL_REF_VOLTAGE_CHANNEL = 8,        // VeREF+ (input channel 8)
   REF_VOLTAGE_NEG_TERMINAL_CHANNEL = 9,    // VREF-/VeREF- (input channel 9)
   TEMPERATURE_DIODE_CHANNEL = 10,          // Temperature diode (input channel 10)
   SUPPLY_VOLTAGE_HALF_CHANNEL = 11,        // (AVcc-AVss)/2 (input channel 11-15)
   INPUT_CHANNEL_NONE = 12                  // illegal (identifies invalid settings)
};

enum sref_enum
{
   REFERENCE_AVcc_AVss = 0,                 // VR+ = AVcc   and VR-= AVss
   REFERENCE_VREFplus_AVss = 1,             // VR+ = VREF+  and VR-= AVss
   REFERENCE_VeREFplus_AVss = 2,            // VR+ = VeREF+ and VR-= AVss
   REFERENCE_AVcc_VREFnegterm = 4,          // VR+ = AVcc   and VR-= VREF-/VeREF- 
   REFERENCE_VREFplus_VREFnegterm = 5,      // VR+ = VREF+  and VR-= VREF-/VeREF-   
   REFERENCE_VeREFplus_VREFnegterm = 6      // VR+ = VeREF+ and VR-= VREF-/VeREF-
};

enum ref2_5v_enum
{
  REFVOLT_LEVEL_1_5 = 0,                    // reference voltage of 1.5 V
  REFVOLT_LEVEL_2_5 = 1,                    // reference voltage of 2.5 V
  REFVOLT_LEVEL_NONE = 0,                   // if e.g. AVcc is chosen 
};

enum adc12ssel_enum
{
   SHT_SOURCE_ADC12OSC = 0,                // ADC12OSC
   SHT_SOURCE_ACLK = 1,                    // ACLK
   SHT_SOURCE_MCLK = 2,                    // MCLK
   SHT_SOURCE_SMCLK = 3                    // SMCLK
};

enum adc12div_enum
{
   SHT_CLOCK_DIV_1 = 0,                         // ADC12 clock divider of 1
   SHT_CLOCK_DIV_2 = 1,                         // ADC12 clock divider of 2
   SHT_CLOCK_DIV_3 = 2,                         // ADC12 clock divider of 3
   SHT_CLOCK_DIV_4 = 3,                         // ADC12 clock divider of 4
   SHT_CLOCK_DIV_5 = 4,                         // ADC12 clock divider of 5
   SHT_CLOCK_DIV_6 = 5,                         // ADC12 clock divider of 6
   SHT_CLOCK_DIV_7 = 6,                         // ADC12 clock divider of 7
   SHT_CLOCK_DIV_8 = 7,                         // ADC12 clock divider of 8
};

enum sht_enum
{
   SAMPLE_HOLD_4_CYCLES = 0,         // sampling duration is 4 clock cycles
   SAMPLE_HOLD_8_CYCLES = 1,         // ...
   SAMPLE_HOLD_16_CYCLES = 2,         
   SAMPLE_HOLD_32_CYCLES = 3,         
   SAMPLE_HOLD_64_CYCLES = 4,         
   SAMPLE_HOLD_96_CYCLES = 5,        
   SAMPLE_HOLD_128_CYCLES = 6,        
   SAMPLE_HOLD_192_CYCLES = 7,        
   SAMPLE_HOLD_256_CYCLES = 8,        
   SAMPLE_HOLD_384_CYCLES = 9,        
   SAMPLE_HOLD_512_CYCLES = 10,        
   SAMPLE_HOLD_768_CYCLES = 11,        
   SAMPLE_HOLD_1024_CYCLES = 12       
};

enum sampcon_ssel_enum
{
   SAMPCON_SOURCE_TACLK = 0,        // Timer A clock source is (external) TACLK
   SAMPCON_SOURCE_ACLK = 1,         // Timer A clock source ACLK
   SAMPCON_SOURCE_SMCLK = 2,        // Timer A clock source SMCLK
   SAMPCON_SOURCE_INCLK = 3,        // Timer A clock source is (external) INCLK
};

enum sampcon_id_enum
{
   SAMPCON_CLOCK_DIV_1 = 0,             // SAMPCON clock divider of 1
   SAMPCON_CLOCK_DIV_2 = 1,             // SAMPCON clock divider of 2
   SAMPCON_CLOCK_DIV_4 = 2,             // SAMPCON clock divider of 4
   SAMPCON_CLOCK_DIV_8 = 3,             // SAMPCON clock divider of 8
};

// The unique string for allocating ADC resource interfaces
#define MSP430ADC12_RESOURCE "Msp430Adc12C.Resource"

// The unique string for accessing HAL2
#define ADCC_SERVICE "AdcC.Service"

// The unique string for accessing HAL2 via ReadStream
#define ADCC_READ_STREAM_SERVICE "AdcC.ReadStream.Client"



#ifdef __MSP430_TI_HEADERS__
//#if __GNUC__ >= 4
  
// "The bitfield structures that overlay peripheral registers are not part of
// mspgcc in the future; the recommended way of accessing those fields is to
// use the masks defined in the TI headers."
// (http://www.millennium.berkeley.edu/pipermail/tinyos-devel/2011-March/004804.html)
//
// Until the ADC driver is updated our temporary workaround is to re-define the
// bitfield structures and continue using them when accessing peripheral
// registers via the DEFINE_UNION_CAST (the same is done in the MSP430 Timer
// and USART drivers). It has been verified that the definitions of the ADC12
// flags has not changed over the different MSP430 chip variants that have an
// ADC12, i.e. using common structs is safe (verified for the header files
// installed via package msp430mcu-tinyos version 20110613-20110821).
// (http://mail.millennium.berkeley.edu/pipermail/tinyos-2.0wg/2011-August/003861.html)

typedef struct {
  volatile unsigned
    adc12sc:1,
    enc:1,
    adc12tovie:1,
    adc12ovie:1,
    adc12on:1,
    refon:1,
    r2_5v:1,
    msc:1,
    sht0:4,
    sht1:4;
volatile unsigned int : 0; // align to word boundary (saves significant amount of code)
} __attribute__ ((packed)) adc12ctl0_t;

typedef struct {
  volatile unsigned
    adc12busy:1,
    conseq:2,
    adc12ssel:2,
    adc12div:3,
    issh:1,
    shp:1,
    shs:2,
    cstartadd:4;
volatile unsigned int : 0; // align to word boundary (saves significant amount of code)
} __attribute__ ((packed)) adc12ctl1_t;

#else

  /* Test for GCC bug (bitfield access) - only version 3.2.3 is known to be stable */
  #define GCC_VERSION (__GNUC__ * 100 + __GNUC_MINOR__ * 10 + __GNUC_PATCHLEVEL__)
  #if GCC_VERSION == 332
    #error "This msp430-gcc version (3.3.2) is known to contain a bug when accessing bitfield structs."
  #elif GCC_VERSION != 323
    #warning "This version of msp430-gcc might contain a bug when accessing bitfield structs (version 3.2.3 is safe - anything else is on your own risk)"
  #endif  

#endif


#if !defined(__msp430_have_adc12) && !defined(__MSP430_HAS_ADC12__)
#error Target msp430 device does not have ADC12 module
#endif

#endif
