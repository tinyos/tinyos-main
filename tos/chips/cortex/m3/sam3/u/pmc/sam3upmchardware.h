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
 * Sam3u specific PMC registers
 *
 * @author Thomas Schmid
 */

#ifndef SAM3UPMCHARDWARE_H
#define SAM3UPMCHARDWARE_H

#include "pmchardware.h"


/**
 * PMC Peripheral Clock Enable Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 485
 * 0: no effect
 * 1: enable corresponding peripheral clock
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t reserved0 : 2;
        uint8_t rtc       : 1; // not used after datasheet
        uint8_t rtt       : 1; // not used after datasheet
        uint8_t wdg       : 1; // not used after datasheet
        uint8_t pmc       : 1; // not used after datasheet
        uint8_t efc0      : 1; // not used after datasheet
        uint8_t efc1      : 1; // not used after datasheet
        uint8_t dbgu      : 1;
        uint8_t hsmc4     : 1;
        uint8_t pioa      : 1;
        uint8_t piob      : 1;
        uint8_t pioc      : 1;
        uint8_t us0       : 1;
        uint8_t us1       : 1;
        uint8_t us2       : 1;
        uint8_t us3       : 1;
        uint8_t mci0      : 1;
        uint8_t twi0      : 1;
        uint8_t twi1      : 1;
        uint8_t spi0      : 1;
        uint8_t ssc0      : 1;
        uint8_t tc0       : 1;
        uint8_t tc1       : 1;
        uint8_t tc2       : 1;
        uint8_t pwmc      : 1;
        uint8_t adc12b    : 1;
        uint8_t adc       : 1;
        uint8_t hdma      : 1;
        uint8_t udphs     : 1;
        uint8_t pid30     : 1; // not used on sam3u
        uint8_t pid31     : 1; // not use don sam3u
    } __attribute__((__packed__)) bits;
} pmc_pcer_t;

/**
 * PMC Peripheral Clock Disable Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 486
 * 0: no effect
 * 1: disable corresponding peripheral clock
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t reserved0 : 2;
        uint8_t rtc       : 1; // not used after datasheet
        uint8_t rtt       : 1; // not used after datasheet
        uint8_t wdg       : 1; // not used after datasheet
        uint8_t pmc       : 1; // not used after datasheet
        uint8_t efc0      : 1; // not used after datasheet
        uint8_t efc1      : 1; // not used after datasheet
        uint8_t dbgu      : 1;
        uint8_t hsmc4     : 1;
        uint8_t pioa      : 1;
        uint8_t piob      : 1;
        uint8_t pioc      : 1;
        uint8_t us0       : 1;
        uint8_t us1       : 1;
        uint8_t us2       : 1;
        uint8_t us3       : 1;
        uint8_t mci0      : 1;
        uint8_t twi0      : 1;
        uint8_t twi1      : 1;
        uint8_t spi0      : 1;
        uint8_t ssc0      : 1;
        uint8_t tc0       : 1;
        uint8_t tc1       : 1;
        uint8_t tc2       : 1;
        uint8_t pwmc      : 1;
        uint8_t adc12b    : 1;
        uint8_t adc       : 1;
        uint8_t hdma      : 1;
        uint8_t udphs     : 1;
        uint8_t pid30     : 1; // not used on sam3u
        uint8_t pid31     : 1; // not use don sam3u
    } __attribute__((__packed__)) bits;
} pmc_pcdr_t;

/**
 * PMC Peripheral Clock Status Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 487
 * 0: peripheral clock disabled
 * 1: peripheral clock enabled
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t reserved0 : 2;
        uint8_t rtc       : 1; // not used after datasheet
        uint8_t rtt       : 1; // not used after datasheet
        uint8_t wdg       : 1; // not used after datasheet
        uint8_t pmc       : 1; // not used after datasheet
        uint8_t efc0      : 1; // not used after datasheet
        uint8_t efc1      : 1; // not used after datasheet
        uint8_t dbgu      : 1;
        uint8_t hsmc4     : 1;
        uint8_t pioa      : 1;
        uint8_t piob      : 1;
        uint8_t pioc      : 1;
        uint8_t us0       : 1;
        uint8_t us1       : 1;
        uint8_t us2       : 1;
        uint8_t us3       : 1;
        uint8_t mci0      : 1;
        uint8_t twi0      : 1;
        uint8_t twi1      : 1;
        uint8_t spi0      : 1;
        uint8_t ssc0      : 1;
        uint8_t tc0       : 1;
        uint8_t tc1       : 1;
        uint8_t tc2       : 1;
        uint8_t pwmc      : 1;
        uint8_t adc12b    : 1;
        uint8_t adc       : 1;
        uint8_t hdma      : 1;
        uint8_t udphs     : 1;
        uint8_t pid30     : 1; // not used on sam3u
        uint8_t pid31     : 1; // not use don sam3u
    } __attribute__((__packed__)) bits;
} pmc_pcsr_t;

/**
 * PMC UTMI Clock Configuration Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 488
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint16_t reserved0: 16;
        uint8_t upllen    :  1; // UTMI PLL enable
        uint8_t reserved1 :  3;
        uint8_t upllcount :  4; // UTMI PLL Start-up Time (in number of slow clock cycles times 8
        uint8_t reserved2 :  8; 
    } __attribute__((__packed__)) bits;
} pmc_uckr_t;

typedef struct
{
    volatile pmc_pcer_t pcer; // Peripheral Clock Enable Register
    volatile pmc_pcdr_t pcdr; // Peripheral Clock Disable Register
    volatile pmc_pcsr_t pcsr; // Peripheral Clock Status Register
} pmc_pc_t;

/**
 * PMC Register definitions, AT91 ARM Cortex-M3 based Microcontrollers SAM3U
 * Series, Preliminary, p. 481
 */
typedef struct pmc
{
    volatile pmc_scer_t   scer;  // System Clock Enable Register
    volatile pmc_scdr_t   scdr;  // System Clock Disable Register
    volatile pmc_scsr_t   scsr;  // System Clock Status Register
    uint32_t reserved0;
    volatile pmc_pc_t     pc;    // Peripheral Clock Control Registers
    volatile pmc_uckr_t   uckr;  // UTMI Clock Register
    volatile pmc_mor_t    mor;   // Main Oscillator Register
    volatile pmc_mcfr_t   mcfr;  // Main Clock Frequency Register
    volatile pmc_pllar_t  pllar; // PLLA Register
    uint32_t reserved1;
    volatile pmc_mckr_t   mckr;  // Master Clock Register
    uint32_t reserved2[3];
    volatile pmc_pck_t   pck0;  // Programmable Clock 0 Register
    volatile pmc_pck_t   pck1;  // Programmable Clock 1 Register
    volatile pmc_pck_t   pck2;  // Programmable Clock 2 Register
    uint32_t reserved3[5];
    volatile pmc_ier_t    ier;   // Interrupt Enable Register
    volatile pmc_idr_t    idr;   // Interrupt Disable Register
    volatile pmc_sr_t     sr;    // Status Register
    volatile pmc_imr_t    imr;   // Interrupt Mask Register
    volatile pmc_fsmr_t   fsmr;  // Fast Startup Mode Register
    volatile pmc_fspr_t   fspr;  // Fast Startup Polarity Register
    volatile pmc_focr_t   focr;  // Fault Output Clear Register
    uint32_t reserved5[26];
    volatile pmc_wpmr_t   wpmr;  // Write Protect Mode Register
    volatile pmc_wpsr_t   wpsr;  // Write Protect Status Register   
} pmc_t;

/**
 * Memory mapping for the PMC
 */
volatile pmc_t* PMC = (volatile pmc_t *) 0x400E0400; // PMC Base Address

#endif //SAM3UPMCHARDWARE_H


