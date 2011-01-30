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
 * Sam3s specific PMC registers
 *
 * @author Thomas Schmid
 */

#ifndef SAM3SPMCHARDWARE_H
#define SAM3SPMCHARDWARE_H

#include "pmchardware.h"

/**
 * PMC Peripheral Clock Enable Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3S Series,
 * 0: no effect
 * 1: enable corresponding peripheral clock
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t b0     : 1; 
        uint8_t b1     : 1; 
        uint8_t b2     : 1; 
        uint8_t b3     : 1; 
        uint8_t b4     : 1; 
        uint8_t b5     : 1; 
        uint8_t b6     : 1; 
        uint8_t b7     : 1; 
        uint8_t b8     : 1; 
        uint8_t b9     : 1;
        uint8_t b10    : 1;
        uint8_t b11    : 1;
        uint8_t b12    : 1;
        uint8_t b13    : 1;
        uint8_t b14    : 1;
        uint8_t b15    : 1;
        uint8_t b16    : 1;
        uint8_t b17    : 1;
        uint8_t b18    : 1;
        uint8_t b19    : 1;
        uint8_t b20    : 1;
        uint8_t b21    : 1;
        uint8_t b22    : 1;
        uint8_t b23    : 1;
        uint8_t b24    : 1;
        uint8_t b25    : 1;
        uint8_t b26    : 1;
        uint8_t b27    : 1;
        uint8_t b28    : 1;
        uint8_t b29    : 1;
        uint8_t b30    : 1; 
        uint8_t b31    : 1; 
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
        uint8_t b0     : 1; 
        uint8_t b1     : 1; 
        uint8_t b2     : 1; 
        uint8_t b3     : 1; 
        uint8_t b4     : 1; 
        uint8_t b5     : 1; 
        uint8_t b6     : 1; 
        uint8_t b7     : 1; 
        uint8_t b8     : 1; 
        uint8_t b9     : 1;
        uint8_t b10    : 1;
        uint8_t b11    : 1;
        uint8_t b12    : 1;
        uint8_t b13    : 1;
        uint8_t b14    : 1;
        uint8_t b15    : 1;
        uint8_t b16    : 1;
        uint8_t b17    : 1;
        uint8_t b18    : 1;
        uint8_t b19    : 1;
        uint8_t b20    : 1;
        uint8_t b21    : 1;
        uint8_t b22    : 1;
        uint8_t b23    : 1;
        uint8_t b24    : 1;
        uint8_t b25    : 1;
        uint8_t b26    : 1;
        uint8_t b27    : 1;
        uint8_t b28    : 1;
        uint8_t b29    : 1;
        uint8_t b30    : 1; 
        uint8_t b31    : 1; 
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
        uint8_t b0     : 1; 
        uint8_t b1     : 1; 
        uint8_t b2     : 1; 
        uint8_t b3     : 1; 
        uint8_t b4     : 1; 
        uint8_t b5     : 1; 
        uint8_t b6     : 1; 
        uint8_t b7     : 1; 
        uint8_t b8     : 1; 
        uint8_t b9     : 1;
        uint8_t b10    : 1;
        uint8_t b11    : 1;
        uint8_t b12    : 1;
        uint8_t b13    : 1;
        uint8_t b14    : 1;
        uint8_t b15    : 1;
        uint8_t b16    : 1;
        uint8_t b17    : 1;
        uint8_t b18    : 1;
        uint8_t b19    : 1;
        uint8_t b20    : 1;
        uint8_t b21    : 1;
        uint8_t b22    : 1;
        uint8_t b23    : 1;
        uint8_t b24    : 1;
        uint8_t b25    : 1;
        uint8_t b26    : 1;
        uint8_t b27    : 1;
        uint8_t b28    : 1;
        uint8_t b29    : 1;
        uint8_t b30    : 1; 
        uint8_t b31    : 1; 
    } __attribute__((__packed__)) bits;
} pmc_pcsr_t;

typedef struct
{
    volatile pmc_pcer_t pcer; // Peripheral Clock Enable Register
    volatile pmc_pcdr_t pcdr; // Peripheral Clock Disable Register
    volatile pmc_pcsr_t pcsr; // Peripheral Clock Status Register
} pmc_pc_t;

/**
 * PMC Clock Generator PLLA Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 491
 * Note: bit 29 must always be set to 1 when writing this register! 
 */ 
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t divb       :  8; // divider
        uint8_t pllbcount  :  6; // pllb counter, specifies the number of slow clock cycles times 8
        uint8_t stmode     :  2; // start mode
        uint16_t mulb      : 11; // PLLB Multiplier
        uint8_t reserved0  :  5;
    } __attribute__((__packed__)) bits;
} pmc_pllbr_t;

#define PMC_PLLBR_STMODE_FAST_STARTUP 0
#define PMC_PLLBR_STMODE_NORMAL_STARTUP 2

/**
 * PMC USB Clock Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t usbs      :  1; // USB Input Clock Selection
        uint32_t reserved0 :  7;
        uint32_t usbdiv    :  4; // Divider for USB Clock
        uint32_t reserved1 : 20;
    } __attribute__((__packed__)) bits;
} pmc_usb_t;

/**
 * PMC Oscillator Calibration Register.
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t cal4       : 7; // RC Oscillator Calibration bits for 4MHz
        uint32_t sel4       : 1; // Selection of RC Oscillator Calibration bits for 4 MHz
        uint32_t cal8       : 7; // RC Oscillator Calibration bits for 8MHz
        uint32_t sel8       : 1; // Selection of RC Oscillator Calibration bits for 8 MHz
        uint32_t cal12      : 7; // RC Oscillator Calibration bits for 12MHz
        uint32_t sel12      : 1; // Selection of RC Oscillator Calibration bits for 12 MHz
        uint32_t reserved0  : 8;
    } __attribute__((__packed__)) bits;
} pmc_ocr_t;


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
    volatile pmc_pc_t     pc;    // Peripheral Clock Control Registers 0
    uint32_t reserved1;
    volatile pmc_mor_t    mor;   // Main Oscillator Register
    volatile pmc_mcfr_t   mcfr;  // Main Clock Frequency Register
    volatile pmc_pllar_t  pllar; // PLLA Register
    volatile pmc_pllbr_t  pllbr; // PLLB Register
    volatile pmc_mckr_t   mckr;  // Master Clock Register
    uint32_t reserved2;
    volatile pmc_usb_t    usb;   // USB Clock Register
    uint32_t reserved3;
    volatile pmc_pck_t   pck0;  // Programmable Clock 0 Register
    volatile pmc_pck_t   pck1;  // Programmable Clock 1 Register
    volatile pmc_pck_t   pck2;  // Programmable Clock 2 Register
    uint32_t reserved4[5];
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
    uint32_t reserved6[5];
    volatile pmc_pc_t     pc1;   // Peripheral Clock Control Registers 1
    uint32_t reserved7;
    volatile pmc_ocr_t    ocr;   // Oscillator Calibration Register
} pmc_t;

/**
 * Memory mapping for the PMC
 */
volatile pmc_t* PMC = (volatile pmc_t *) 0x400E0400; // PMC Base Address

#endif //SAM3UPMCHARDWARE_H


