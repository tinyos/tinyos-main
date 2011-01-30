/*
 * Copyright (c) 2009 Johns Hopkins University.
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
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * 12 bit ADC register definitions.
 *
 * @author JeongGil Ko
 */

#ifndef _SAM3UADC12BHARDWARE_H
#define _SAM3UADC12BHARDWARE_H

/**
 *  ADC12B Control Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1105
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t swrst         :  1; // software reset
    uint8_t start         :  1; // start conversion
    uint8_t reserved0     :  6;
    uint16_t reserved1    : 16;
    uint8_t reserved2     :  8;
  } __attribute__((__packed__)) bits;
} adc12b_cr_t; 

/**
 *  ADC12B Mode Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1106
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t trgen         :  1; // trigger enable
    uint8_t trgsel        :  3; // trigger selection
    uint8_t lowres        :  1; // resolution
    uint8_t sleep         :  1; // sleep mode
    uint8_t reserved0     :  2;
    uint8_t prescal       :  8; // prescaler rate selection
    uint8_t startup       :  8; // startup time
    uint8_t shtim         :  4; // sample & hold time
    uint8_t reserved1     :  4;
  } __attribute__((__packed__)) bits;
} adc12b_mr_t; 


/**
 *  ADC12B Channel Enable Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1108
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t ch0           :  1;
    uint8_t ch1           :  1;
    uint8_t ch2           :  1;
    uint8_t ch3           :  1;
    uint8_t ch4           :  1;
    uint8_t ch5           :  1;
    uint8_t ch6           :  1;
    uint8_t ch7           :  1;
    uint16_t reserved0    : 16;
    uint8_t reserved1     :  8;
  } __attribute__((__packed__)) bits;
} adc12b_cher_t;

/**
 *  ADC12B Channel Disable Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1109
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t ch0           :  1;
    uint8_t ch1           :  1;
    uint8_t ch2           :  1;
    uint8_t ch3           :  1;
    uint8_t ch4           :  1;
    uint8_t ch5           :  1;
    uint8_t ch6           :  1;
    uint8_t ch7           :  1;
    uint16_t reserved0    : 16;
    uint8_t reserved1     :  8;
  } __attribute__((__packed__)) bits;
} adc12b_chdr_t;

/**
 *  ADC12B Channel Status Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1110
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t ch0           :  1;
    uint8_t ch1           :  1;
    uint8_t ch2           :  1;
    uint8_t ch3           :  1;
    uint8_t ch4           :  1;
    uint8_t ch5           :  1;
    uint8_t ch6           :  1;
    uint8_t ch7           :  1;
    uint16_t reserved0    : 16;
    uint8_t reserved1     :  8;
  } __attribute__((__packed__)) bits;
} adc12b_chsr_t;

/**
 *  ADC12B Analog Control Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1111
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t gain          :  2; // input gain
    uint8_t reserved0     :  6;
    uint8_t ibctl         :  2; // bias current control
    uint8_t reserved1     :  6;
    uint8_t diff          :  1; // differential mode
    uint8_t offset        :  1; // input offset
    uint8_t reserved2     :  6;
    uint8_t reserved3     :  8;
  } __attribute__((__packed__)) bits;
} adc12b_acr_t;

/**
 *  ADC12B Extended Mode Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1112
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t offmodes               :  1; // input gain
    uint8_t reserved0              :  7;
    uint8_t reserved1              :  8;
    uint8_t off_mode_startup_time  :  8; // startup time
    uint8_t reserved2              :  8;
  } __attribute__((__packed__)) bits;
} adc12b_emr_t;

/**
 *  ADC12B Status Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1113
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t eoc0                   :  1; // end of conversion <channel no.>
    uint8_t eoc1                   :  1; // end of conversion <channel no.>
    uint8_t eoc2                   :  1; // end of conversion <channel no.>
    uint8_t eoc3                   :  1; // end of conversion <channel no.>
    uint8_t eoc4                   :  1; // end of conversion <channel no.>
    uint8_t eoc5                   :  1; // end of conversion <channel no.>
    uint8_t eoc6                   :  1; // end of conversion <channel no.>
    uint8_t eoc7                   :  1; // end of conversion <channel no.>
    uint8_t ovre0                  :  1; // overrun error <channel no.>
    uint8_t ovre1                  :  1; // overrun error <channel no.>
    uint8_t ovre2                  :  1; // overrun error <channel no.>
    uint8_t ovre3                  :  1; // overrun error <channel no.>
    uint8_t ovre4                  :  1; // overrun error <channel no.>
    uint8_t ovre5                  :  1; // overrun error <channel no.>
    uint8_t ovre6                  :  1; // overrun error <channel no.>
    uint8_t ovre7                  :  1; // overrun error <channel no.>
    uint8_t drdy                   :  1; // data ready
    uint8_t govre                  :  1; // general overrun error
    uint8_t endrx                  :  1; // end of rx buffer
    uint8_t rxbuff                 :  1; // rx buffer full
    uint8_t reserved0              :  4;
    uint8_t reserved1              :  8;
  } __attribute__((__packed__)) bits;
} adc12b_sr_t;

/**
 *  ADC12B Last Converted Data Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1114
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint16_t ldata                 : 12; // last data converted 
    uint16_t reserved0             :  4;
    uint16_t reserved1             : 16;
  } __attribute__((__packed__)) bits;
} adc12b_lcdr_t;

/**
 *  ADC12B Interrupt Enable Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1115
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t eoc0                   :  1; // end of conversion interrupt enable <channel no.>
    uint8_t eoc1                   :  1; // end of conversion interrupt enable <channel no.>
    uint8_t eoc2                   :  1; // end of conversion interrupt enable <channel no.>
    uint8_t eoc3                   :  1; // end of conversion interrupt enable <channel no.>
    uint8_t eoc4                   :  1; // end of conversion interrupt enable <channel no.>
    uint8_t eoc5                   :  1; // end of conversion interrupt enable <channel no.>
    uint8_t eoc6                   :  1; // end of conversion interrupt enable <channel no.>
    uint8_t eoc7                   :  1; // end of conversion interrupt enable <channel no.>
    uint8_t ovre0                  :  1; // overrun error interrupt enable <channel no.>
    uint8_t ovre1                  :  1; // overrun error interrupt enable <channel no.>
    uint8_t ovre2                  :  1; // overrun error interrupt enable <channel no.>
    uint8_t ovre3                  :  1; // overrun error interrupt enable <channel no.>
    uint8_t ovre4                  :  1; // overrun error interrupt enable <channel no.>
    uint8_t ovre5                  :  1; // overrun error interrupt enable <channel no.>
    uint8_t ovre6                  :  1; // overrun error interrupt enable <channel no.>
    uint8_t ovre7                  :  1; // overrun error interrupt enable <channel no.>
    uint8_t drdy                   :  1; // data ready interrupt enable
    uint8_t govre                  :  1; // general overrun error interrupt enable
    uint8_t endrx                  :  1; // end of rx buffer interrupt enable
    uint8_t rxbuff                 :  1; // rx buffer full interrupt enable
    uint8_t reserved0              :  4;
    uint8_t reserved1              :  8;
  } __attribute__((__packed__)) bits;
} adc12b_ier_t;

/**
 *  ADC12B Interrupt Disable Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1116
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t eoc0                   :  1; // end of conversion interrupt disable <channel no.>
    uint8_t eoc1                   :  1; // end of conversion interrupt disable <channel no.>
    uint8_t eoc2                   :  1; // end of conversion interrupt disable <channel no.>
    uint8_t eoc3                   :  1; // end of conversion interrupt disable <channel no.>
    uint8_t eoc4                   :  1; // end of conversion interrupt disable <channel no.>
    uint8_t eoc5                   :  1; // end of conversion interrupt disable <channel no.>
    uint8_t eoc6                   :  1; // end of conversion interrupt disable <channel no.>
    uint8_t eoc7                   :  1; // end of conversion interrupt disable <channel no.>
    uint8_t ovre0                  :  1; // overrun error interrupt disable <channel no.>
    uint8_t ovre1                  :  1; // overrun error interrupt disable <channel no.>
    uint8_t ovre2                  :  1; // overrun error interrupt disable <channel no.>
    uint8_t ovre3                  :  1; // overrun error interrupt disable <channel no.>
    uint8_t ovre4                  :  1; // overrun error interrupt disable <channel no.>
    uint8_t ovre5                  :  1; // overrun error interrupt disable <channel no.>
    uint8_t ovre6                  :  1; // overrun error interrupt disable <channel no.>
    uint8_t ovre7                  :  1; // overrun error interrupt disable <channel no.>
    uint8_t drdy                   :  1; // data ready interrupt disable
    uint8_t govre                  :  1; // general overrun error interrupt disable
    uint8_t endrx                  :  1; // end of rx buffer interrupt disable
    uint8_t rxbuff                 :  1; // rx buffer full interrupt disable
    uint8_t reserved0              :  4;
    uint8_t reserved1              :  8;
  } __attribute__((__packed__)) bits;
} adc12b_idr_t;

/**
 *  ADC12B Interrupt Mask Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1113
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint8_t eoc0                   :  1; // end of conversion interrupt mask <channel no.>
    uint8_t eoc1                   :  1; // end of conversion interrupt mask <channel no.>
    uint8_t eoc2                   :  1; // end of conversion interrupt mask <channel no.>
    uint8_t eoc3                   :  1; // end of conversion interrupt mask <channel no.>
    uint8_t eoc4                   :  1; // end of conversion interrupt mask <channel no.>
    uint8_t eoc5                   :  1; // end of conversion interrupt mask <channel no.>
    uint8_t eoc6                   :  1; // end of conversion interrupt mask <channel no.>
    uint8_t eoc7                   :  1; // end of conversion interrupt mask <channel no.>
    uint8_t ovre0                  :  1; // overrun error interrupt mask <channel no.>
    uint8_t ovre1                  :  1; // overrun error interrupt mask <channel no.>
    uint8_t ovre2                  :  1; // overrun error interrupt mask <channel no.>
    uint8_t ovre3                  :  1; // overrun error interrupt mask <channel no.>
    uint8_t ovre4                  :  1; // overrun error interrupt mask <channel no.>
    uint8_t ovre5                  :  1; // overrun error interrupt mask <channel no.>
    uint8_t ovre6                  :  1; // overrun error interrupt mask <channel no.>
    uint8_t ovre7                  :  1; // overrun error interrupt mask <channel no.>
    uint8_t drdy                   :  1; // data ready interrupt mask
    uint8_t govre                  :  1; // general overrun error interrupt mask
    uint8_t endrx                  :  1; // end of rx buffer interrupt mask
    uint8_t rxbuff                 :  1; // rx buffer full interrupt mask
    uint8_t reserved0              :  4;
    uint8_t reserved1              :  8;
  } __attribute__((__packed__)) bits;
} adc12b_imr_t;

/**
 *  ADC12B Channel Data Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 1114
 */
typedef union
{
  uint32_t flat;
  struct
  {
    uint16_t data                  : 12; // converted data 
    uint16_t reserved0             :  4;
    uint16_t reserved1             : 16;
  } __attribute__((__packed__)) bits;
} adc12b_cdr_t;

/**
 * ADC12B Register definitions, AT91 ARM Cortex-M3 based Microcontrollers SAM3U
 * Series, Preliminary, p. 1104
 */
typedef struct adc12b
{
  volatile adc12b_cr_t cr; // Control Register
  volatile adc12b_mr_t mr; // Mode Register
  uint32_t reserved0[2];
  volatile adc12b_cher_t cher; // Channel Enable Register
  volatile adc12b_chdr_t chdr; // Channel Disable Register
  volatile adc12b_chsr_t chsr; // Channel Status Register
  volatile adc12b_sr_t sr; // Status Register
  volatile adc12b_lcdr_t lcdr; // Last Converted Data Register
  volatile adc12b_ier_t ier; // Interrupt Enable Register
  volatile adc12b_idr_t idr; // Interrupt Disable Register
  volatile adc12b_imr_t imr; // Interrupt Mask Register
  volatile adc12b_cdr_t cdr0; // Channal Data Register <channel no.>
  volatile adc12b_cdr_t cdr1; // Channal Data Register <channel no.>
  volatile adc12b_cdr_t cdr2; // Channal Data Register <channel no.>
  volatile adc12b_cdr_t cdr3; // Channal Data Register <channel no.>
  volatile adc12b_cdr_t cdr4; // Channal Data Register <channel no.>
  volatile adc12b_cdr_t cdr5; // Channal Data Register <channel no.>
  volatile adc12b_cdr_t cdr6; // Channal Data Register <channel no.>
  volatile adc12b_cdr_t cdr7; // Channal Data Register <channel no.>
  uint32_t reserved1[5];
  volatile adc12b_acr_t acr; // Analog Control Register
  volatile adc12b_emr_t emr; // Extended Mode Register
} adc12b_t;

/**
 * Memory mapping for the ADC12B
 */
volatile adc12b_t* ADC12B = (volatile adc12b_t *) 0x400A8000; // ADC12B Base Address

#define SAM3UADC12_RESOURCE "Sam3uAdc12bC.Resource"
#define ADCC_SERVICE "AdcC.Service"
#define ADCC_READ_STREAM_SERVICE "AdcC.ReadStream.Client"

typedef struct { 
  unsigned int channel: 3;
  unsigned int diff: 1;
  unsigned int prescal: 8;
  unsigned int lowres: 1;
  unsigned int shtim: 4;
  unsigned int ibctl: 2;
  unsigned int sleep: 1;
  unsigned int startup: 8;
  unsigned int trgen: 1;
  unsigned int trgsel: 1;
  unsigned int : 0;
} sam3u_adc12_channel_config_t;


#endif // _SAM3UADC12BHARDWARE_H
