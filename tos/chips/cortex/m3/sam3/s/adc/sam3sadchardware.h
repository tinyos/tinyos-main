/*
 * Copyright (c) 2011 University of Utah.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Sam3s ADC register definitions
 *
 * @author Thomas Schmid
 */

#ifndef SAM3SADCHARDWARE_H
#define SAM3SADCHARDWARE_H

/**
 * ADC Control Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t swrst      :  1; // Software Reset
        uint32_t start      :  1; // Start Conversion
        uint32_t reserved   : 30;
    } __attribute__((__packed__)) bits;
} adc_cr_t;

/**
 * ADC Mode Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t trgen      : 1; // Trigger Enable
        uint32_t trgsel     : 3; // Trigger Selection
        uint32_t lowres     : 1; // Resolution
        uint32_t sleep      : 1; // Sleep Mode
        uint32_t fwup       : 1; // Fast Wake Up
        uint32_t freerun    : 1; // Free Run Mode
        uint32_t prescal    : 8; // Prescaler Rate Selection
        uint32_t startup    : 4; // Start Up Time
        uint32_t settling   : 2; // Analog Settling Time
        uint32_t reserved0  : 1;
        uint32_t anach      : 1; // Analog change
        uint32_t tracktim   : 4; // Tracking Time
        uint32_t transfer   : 2; // Transfer Period
        uint32_t reserved1  : 1;
        uint32_t useq       : 1; // Use Sequence Enable
    } __attribute__((__packed__)) bits;
} adc_mr_t;

/**
 * ADC Channel Sequence 1 Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t usch1     : 3; // User Sequence Number
        uint32_t reserved0 : 1;
        uint32_t usch2     : 3; // User Sequence Number
        uint32_t reserved1 : 1;
        uint32_t usch3     : 3; // User Sequence Number
        uint32_t reserved2 : 1;
        uint32_t usch4     : 3; // User Sequence Number
        uint32_t reserved3 : 1;
        uint32_t usch5     : 3; // User Sequence Number
        uint32_t reserved4 : 1;
        uint32_t usch6     : 3; // User Sequence Number
        uint32_t reserved5 : 1;
        uint32_t usch7     : 3; // User Sequence Number
        uint32_t reserved6 : 1;
        uint32_t usch8     : 3; // User Sequence Number
        uint32_t reserved7 : 1;
    } __attribute__((__packed__)) bits;
} adc_seqr1_t;

/**
 * ADC Channel Sequence 2 Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t usch9     : 3; // User Sequence Number
        uint32_t reserved0 : 1;
        uint32_t usch10    : 3; // User Sequence Number
        uint32_t reserved1 : 1;
        uint32_t usch11    : 3; // User Sequence Number
        uint32_t reserved2 : 1;
        uint32_t usch12    : 3; // User Sequence Number
        uint32_t reserved3 : 1;
        uint32_t usch13    : 3; // User Sequence Number
        uint32_t reserved4 : 1;
        uint32_t usch14    : 3; // User Sequence Number
        uint32_t reserved5 : 1;
        uint32_t usch15    : 3; // User Sequence Number
        uint32_t reserved6 : 1;
        uint32_t usch16    : 3; // User Sequence Number
        uint32_t reserved7 : 1;
    } __attribute__((__packed__)) bits;
} adc_seqr2_t;

/**
 * ADC Channel Enable Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t ch0      :  1; // Channel Enable
        uint32_t ch1      :  1; // Channel Enable
        uint32_t ch2      :  1; // Channel Enable
        uint32_t ch3      :  1; // Channel Enable
        uint32_t ch4      :  1; // Channel Enable
        uint32_t ch5      :  1; // Channel Enable
        uint32_t ch6      :  1; // Channel Enable
        uint32_t ch7      :  1; // Channel Enable
        uint32_t ch8      :  1; // Channel Enable
        uint32_t ch9      :  1; // Channel Enable
        uint32_t ch10     :  1; // Channel Enable
        uint32_t ch11     :  1; // Channel Enable
        uint32_t ch12     :  1; // Channel Enable
        uint32_t ch13     :  1; // Channel Enable
        uint32_t ch14     :  1; // Channel Enable
        uint32_t ch15     :  1; // Channel Enable
        uint32_t reserved : 16; 
    } __attribute__((__packed__)) bits;
} adc_cher_t;

/**
 * ADC Channel Disable Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t ch0      :  1; // Channel Disable
        uint32_t ch1      :  1; // Channel Disable
        uint32_t ch2      :  1; // Channel Disable
        uint32_t ch3      :  1; // Channel Disable
        uint32_t ch4      :  1; // Channel Disable
        uint32_t ch5      :  1; // Channel Disable
        uint32_t ch6      :  1; // Channel Disable
        uint32_t ch7      :  1; // Channel Disable
        uint32_t ch8      :  1; // Channel Disable
        uint32_t ch9      :  1; // Channel Disable
        uint32_t ch10     :  1; // Channel Disable
        uint32_t ch11     :  1; // Channel Disable
        uint32_t ch12     :  1; // Channel Disable
        uint32_t ch13     :  1; // Channel Disable
        uint32_t ch14     :  1; // Channel Disable
        uint32_t ch15     :  1; // Channel Disable
        uint32_t reserved : 16; 
    } __attribute__((__packed__)) bits;
} adc_chdr_t;

/**
 * ADC Channel Status Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t ch0      :  1; // Channel Status
        uint32_t ch1      :  1; // Channel Status 
        uint32_t ch2      :  1; // Channel Status 
        uint32_t ch3      :  1; // Channel Status 
        uint32_t ch4      :  1; // Channel Status 
        uint32_t ch5      :  1; // Channel Status 
        uint32_t ch6      :  1; // Channel Status 
        uint32_t ch7      :  1; // Channel Status 
        uint32_t ch8      :  1; // Channel Status 
        uint32_t ch9      :  1; // Channel Status 
        uint32_t ch10     :  1; // Channel Status 
        uint32_t ch11     :  1; // Channel Status 
        uint32_t ch12     :  1; // Channel Status 
        uint32_t ch13     :  1; // Channel Status 
        uint32_t ch14     :  1; // Channel Status 
        uint32_t ch15     :  1; // Channel Status 
        uint32_t reserved : 16; 
    } __attribute__((__packed__)) bits;
} adc_chsr_t;

/**
 * ADC Last Converted Data Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t ldata    : 12; // Last Data Converted
        uint32_t chnb     :  4; // Channel Number
        uint32_t reserved : 16;
    } __attribute__((__packed__)) bits;
} adc_lcdr_t;

/**
 * ADC Interrupt Enable Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t eoc0      : 1; // End of Conversion Interrupt Enable x
        uint32_t eoc1      : 1; // End of Conversion Interrupt Enable x
        uint32_t eoc2      : 1; // End of Conversion Interrupt Enable x
        uint32_t eoc3      : 1; // End of Conversion Interrupt Enable x
        uint32_t eoc4      : 1; // End of Conversion Interrupt Enable x
        uint32_t eoc5      : 1; // End of Conversion Interrupt Enable x
        uint32_t eoc6      : 1; // End of Conversion Interrupt Enable x
        uint32_t eoc7      : 1; // End of Conversion Interrupt Enable x
        uint32_t eoc8      : 1; // End of Conversion Interrupt Enable x
        uint32_t eoc9      : 1; // End of Conversion Interrupt Enable x
        uint32_t eoc10     : 1; // End of Conversion Interrupt Enable x
        uint32_t eoc11     : 1; // End of Conversion Interrupt Enable x
        uint32_t eoc12     : 1; // End of Conversion Interrupt Enable x
        uint32_t eoc13     : 1; // End of Conversion Interrupt Enable x
        uint32_t eoc14     : 1; // End of Conversion Interrupt Enable x
        uint32_t eoc15     : 1; // End of Conversion Interrupt Enable x
        uint32_t reserved0 : 8;
        uint32_t drdy      : 1; // Data Ready Interrupt Enable
        uint32_t govre     : 1; // General Overrun Error Interrupt Enable
        uint32_t compe     : 1; // comparison Event Interrupt Enable
        uint32_t endrx     : 1; // End of Receive Buffer Interrupt Enable
        uint32_t rxbuff    : 1; // Receive Buffer Full Interrupt Enable
        uint32_t reserved1 : 3;
    } __attribute__((__packed__)) bits;
} adc_ier_t;

/**
 * ADC Interrupt Disable Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t eoc0      : 1; // End of Conversion Interrupt Disable x
        uint32_t eoc1      : 1; // End of Conversion Interrupt Disable x
        uint32_t eoc2      : 1; // End of Conversion Interrupt Disable x
        uint32_t eoc3      : 1; // End of Conversion Interrupt Disable x
        uint32_t eoc4      : 1; // End of Conversion Interrupt Disable x
        uint32_t eoc5      : 1; // End of Conversion Interrupt Disable x
        uint32_t eoc6      : 1; // End of Conversion Interrupt Disable x
        uint32_t eoc7      : 1; // End of Conversion Interrupt Disable x
        uint32_t eoc8      : 1; // End of Conversion Interrupt Disable x
        uint32_t eoc9      : 1; // End of Conversion Interrupt Disable x
        uint32_t eoc10     : 1; // End of Conversion Interrupt Disable x
        uint32_t eoc11     : 1; // End of Conversion Interrupt Disable x
        uint32_t eoc12     : 1; // End of Conversion Interrupt Disable x
        uint32_t eoc13     : 1; // End of Conversion Interrupt Disable x
        uint32_t eoc14     : 1; // End of Conversion Interrupt Disable x
        uint32_t eoc15     : 1; // End of Conversion Interrupt Disable x
        uint32_t reserved0 : 8;
        uint32_t drdy      : 1; // Data Ready Interrupt Disable
        uint32_t govre     : 1; // General Overrun Error Interrupt Disable
        uint32_t compe     : 1; // comparison Event Interrupt Disable
        uint32_t endrx     : 1; // End of Receive Buffer Interrupt Disable
        uint32_t rxbuff    : 1; // Receive Buffer Full Interrupt Disable
        uint32_t reserved1 : 3;
    } __attribute__((__packed__)) bits;
} adc_idr_t;

/**
 * ADC Interrupt Mask Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t eoc0      : 1; // End of Conversion Interrupt Mask x
        uint32_t eoc1      : 1; // End of Conversion Interrupt Mask x
        uint32_t eoc2      : 1; // End of Conversion Interrupt Mask x
        uint32_t eoc3      : 1; // End of Conversion Interrupt Mask x
        uint32_t eoc4      : 1; // End of Conversion Interrupt Mask x
        uint32_t eoc5      : 1; // End of Conversion Interrupt Mask x
        uint32_t eoc6      : 1; // End of Conversion Interrupt Mask x
        uint32_t eoc7      : 1; // End of Conversion Interrupt Mask x
        uint32_t eoc8      : 1; // End of Conversion Interrupt Mask x
        uint32_t eoc9      : 1; // End of Conversion Interrupt Mask x
        uint32_t eoc10     : 1; // End of Conversion Interrupt Mask x
        uint32_t eoc11     : 1; // End of Conversion Interrupt Mask x
        uint32_t eoc12     : 1; // End of Conversion Interrupt Mask x
        uint32_t eoc13     : 1; // End of Conversion Interrupt Mask x
        uint32_t eoc14     : 1; // End of Conversion Interrupt Mask x
        uint32_t eoc15     : 1; // End of Conversion Interrupt Mask x
        uint32_t reserved0 : 8;
        uint32_t drdy      : 1; // Data Ready Interrupt Mask
        uint32_t govre     : 1; // General Overrun Error Interrupt Mask
        uint32_t compe     : 1; // comparison Event Interrupt Mask
        uint32_t endrx     : 1; // End of Receive Buffer Interrupt Mask
        uint32_t rxbuff    : 1; // Receive Buffer Full Interrupt Mask
        uint32_t reserved1 : 3;
    } __attribute__((__packed__)) bits;
} adc_imr_t;

/**
 * ADC Interrupt Status Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t eoc0      : 1; // End of Conversion Interrupt Status x
        uint32_t eoc1      : 1; // End of Conversion Interrupt Status x
        uint32_t eoc2      : 1; // End of Conversion Interrupt Status x
        uint32_t eoc3      : 1; // End of Conversion Interrupt Status x
        uint32_t eoc4      : 1; // End of Conversion Interrupt Status x
        uint32_t eoc5      : 1; // End of Conversion Interrupt Status x
        uint32_t eoc6      : 1; // End of Conversion Interrupt Status x
        uint32_t eoc7      : 1; // End of Conversion Interrupt Status x
        uint32_t eoc8      : 1; // End of Conversion Interrupt Status x
        uint32_t eoc9      : 1; // End of Conversion Interrupt Status x
        uint32_t eoc10     : 1; // End of Conversion Interrupt Status x
        uint32_t eoc11     : 1; // End of Conversion Interrupt Status x
        uint32_t eoc12     : 1; // End of Conversion Interrupt Status x
        uint32_t eoc13     : 1; // End of Conversion Interrupt Status x
        uint32_t eoc14     : 1; // End of Conversion Interrupt Status x
        uint32_t eoc15     : 1; // End of Conversion Interrupt Status x
        uint32_t reserved0 : 8;
        uint32_t drdy      : 1; // Data Ready Interrupt Status
        uint32_t govre     : 1; // General Overrun Error Interrupt Status
        uint32_t compe     : 1; // comparison Event Interrupt Status
        uint32_t endrx     : 1; // End of Receive Buffer Interrupt Status
        uint32_t rxbuff    : 1; // Receive Buffer Full Interrupt Status
        uint32_t reserved1 : 3;
    } __attribute__((__packed__)) bits;
} adc_isr_t;

/**
 * ADC Overrun Status Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t ovre0      :  1; // Overrun Error x
        uint32_t ovre1      :  1; // Overrun Error x
        uint32_t ovre2      :  1; // Overrun Error x
        uint32_t ovre3      :  1; // Overrun Error x
        uint32_t ovre4      :  1; // Overrun Error x
        uint32_t ovre5      :  1; // Overrun Error x
        uint32_t ovre6      :  1; // Overrun Error x
        uint32_t ovre7      :  1; // Overrun Error x
        uint32_t ovre8      :  1; // Overrun Error x
        uint32_t ovre9      :  1; // Overrun Error x
        uint32_t ovre10     :  1; // Overrun Error x
        uint32_t ovre11     :  1; // Overrun Error x
        uint32_t ovre12     :  1; // Overrun Error x
        uint32_t ovre13     :  1; // Overrun Error x
        uint32_t ovre14     :  1; // Overrun Error x
        uint32_t ovre15     :  1; // Overrun Error x
        uint32_t reserved   : 16;
    } __attribute__((__packed__)) bits;
} adc_over_t;

/**
 * ADC Extended Mode Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t cmpmode    :  2; // Comparison Mode
        uint32_t reserved0  :  2;
        uint32_t cmpsel     :  4; // Comparison Selected Channel
        uint32_t reserved1  :  1;
        uint32_t cmpall     :  1; //Compare All Channels
        uint32_t reserved2  : 14;
        uint32_t tag        :  1; // TAG of ADC_LDCR register
        uint32_t reserved3  :  7;
    } __attribute__((__packed__)) bits;
} adc_emr_t;

/**
 * ADC Compare Window Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t lowthres   : 12; // Low Threshold
        uint32_t reserved0  :  4;
        uint32_t highthres  : 12; // High Threshold
        uint32_t reserved1  :  4;
    } __attribute__((__packed__)) bits;
} adc_cwr_t;

/**
 * ADC Channel Gain Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t gain0    : 2; // Gain Channel x
        uint32_t gain1    : 2; // Gain Channel x
        uint32_t gain2    : 2; // Gain Channel x
        uint32_t gain3    : 2; // Gain Channel x
        uint32_t gain4    : 2; // Gain Channel x
        uint32_t gain5    : 2; // Gain Channel x
        uint32_t gain6    : 2; // Gain Channel x
        uint32_t gain7    : 2; // Gain Channel x
        uint32_t gain8    : 2; // Gain Channel x
        uint32_t gain9    : 2; // Gain Channel x
        uint32_t gain10   : 2; // Gain Channel x
        uint32_t gain11   : 2; // Gain Channel x
        uint32_t gain12   : 2; // Gain Channel x
        uint32_t gain13   : 2; // Gain Channel x
        uint32_t gain14   : 2; // Gain Channel x
        uint32_t gain15   : 2; // Gain Channel x
    } __attribute__((__packed__)) bits;
} adc_cgr_t;

/**
 * ADC Channel Offset Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t off0   : 1; // Offset for Channel x
        uint32_t off1   : 1; // Offset for Channel x
        uint32_t off2   : 1; // Offset for Channel x
        uint32_t off3   : 1; // Offset for Channel x
        uint32_t off4   : 1; // Offset for Channel x
        uint32_t off5   : 1; // Offset for Channel x
        uint32_t off6   : 1; // Offset for Channel x
        uint32_t off7   : 1; // Offset for Channel x
        uint32_t off8   : 1; // Offset for Channel x
        uint32_t off9   : 1; // Offset for Channel x
        uint32_t off10  : 1; // Offset for Channel x
        uint32_t off11  : 1; // Offset for Channel x
        uint32_t off12  : 1; // Offset for Channel x
        uint32_t off13  : 1; // Offset for Channel x
        uint32_t off14  : 1; // Offset for Channel x
        uint32_t off15  : 1; // Offset for Channel x
        uint32_t diff0  : 1; // Differential inputs for channel x
        uint32_t diff1  : 1; // Differential inputs for channel x
        uint32_t diff2  : 1; // Differential inputs for channel x
        uint32_t diff3  : 1; // Differential inputs for channel x
        uint32_t diff4  : 1; // Differential inputs for channel x
        uint32_t diff5  : 1; // Differential inputs for channel x
        uint32_t diff6  : 1; // Differential inputs for channel x
        uint32_t diff7  : 1; // Differential inputs for channel x
        uint32_t diff8  : 1; // Differential inputs for channel x
        uint32_t diff9  : 1; // Differential inputs for channel x
        uint32_t diff10 : 1; // Differential inputs for channel x
        uint32_t diff11 : 1; // Differential inputs for channel x
        uint32_t diff12 : 1; // Differential inputs for channel x
        uint32_t diff13 : 1; // Differential inputs for channel x
        uint32_t diff14 : 1; // Differential inputs for channel x
        uint32_t diff15 : 1; // Differential inputs for channel x
    } __attribute__((__packed__)) bits;
} adc_cor_t;

/**
 * ADC Channel Data Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t data     : 12; // converted Data
        uint32_t reserved : 20;
    } __attribute__((__packed__)) bits;
} adc_cdr_t;

/**
 * ADC Analog Control Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t reserved0 :  4;
        uint32_t tson      :  1; // Temperature Sensor On
        uint32_t reserved1 :  3;
        uint32_t ibctl     :  2; // ADC Bias Current Control
        uint32_t reserved2 : 22;
    } __attribute__((__packed__)) bits;
} adc_acr_t;

/**
 * ADC Write Protect Mode Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t wpen      :  1; // Write Protect Enable
        uint32_t reserved0 :  7;
        uint32_t wpkey     : 24; // Write Protect key
    } __attribute__((__packed__)) bits;
} adc_wpmr_t;

#define ADC_WPMR_KEY 0x414443

/**
 * ADC Write Protect Status Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t wpvs      :  1; // Write Protect Violation Status
        uint32_t reserved0 :  7;
        uint32_t wpvsrc    : 16; // Write Protect Violation Source
        uint32_t reserved1 :  8;
    } __attribute__((__packed__)) bits;
} adc_wpsr_t;

/**
 * ADC Register definitions, AT91 ARM Cortex-M3 based Microcontrollers SAM3S
 * Series, Preliminary, p. 989
 */
typedef struct adc
{
    volatile adc_cr_t cr; // Control Register
    volatile adc_mr_t mr; // Mode Register
    volatile adc_seqr1_t seqr1; // Channel Sequence Register 1
    volatile adc_seqr2_t seqr2; // Channel Sequence Register 2
    volatile adc_cher_t  cher;  // Channel Enable Register
    volatile adc_chdr_t  chdr;  // Channel Disable Register
    volatile adc_chsr_t  chsr;  // channel Status Register
    uint32_t reserved0;
    volatile adc_lcdr_t  lcdr;  // Last Converted Data Register
    volatile adc_ier_t   ier;   // Interrupt Enable Register
    volatile adc_idr_t   idr;   // Interrupt Disable Register
    volatile adc_imr_t   imr;   // Interrupt Mask Register
    volatile adc_isr_t   isr;   // Interrupt Status Register
    uint32_t reserved1;
    uint32_t reserved2;
    volatile adc_over_t  over;  // Overrun Status Register
    volatile adc_emr_t   emr;   // Extended Mode Register
    volatile adc_cwr_t   cwr;   // Compare Window Register
    volatile adc_cgr_t   cgr;   // Channel Gain Register
    volatile adc_cor_t   cor;   // Channel Offset Register
    volatile adc_cdr_t   cdr[16];  // Channel Data Register x
    uint32_t reserved3;
    volatile adc_acr_t   acr;   // Analog Control Register
    uint32_t reserved4[19];
    volatile adc_wpmr_t  wpmr;  // Write Protect Mode Register
    volatile adc_wpsr_t  wpsr;  // Write Protect Status Register
} adc_t;

/**
 * Memory mapping for the ADC
 */
#define ADC_BASE_ADDRESS 0x40038000
volatile adc_t* ADC = (volatile adc_t *) ADC_BASE_ADDRESS; // ADC Base Address

#define SAM3SADC_RESOURCE "Sam3AdcC.Resource"
#define ADCC_SERVICE "AdcC.Service"
#define ADCC_READ_STREAM_SERVICE "AdcC.ReadStream.Client"

typedef struct { 
  uint32_t channel  : 4;
  uint32_t trgen    : 1;
  uint32_t trgsel   : 3;
  uint32_t lowres   : 1;
  uint32_t sleep    : 1;
  uint32_t fwup     : 1;
  uint32_t freerun  : 1;
  uint32_t prescal  : 8;
  uint32_t startup  : 4;
  uint32_t settling : 2;
  uint32_t anach    : 1;
  uint32_t tracktim : 4;
  uint32_t transfer : 2;
  uint32_t useq     : 1; 
  uint32_t ibctl    : 2;
  uint32_t diff     : 1;
  uint32_t gain     : 2;
  uint32_t offset   : 1;
} sam3s_adc_channel_config_t;

#endif //SAM3SADCHARDWARE_H


