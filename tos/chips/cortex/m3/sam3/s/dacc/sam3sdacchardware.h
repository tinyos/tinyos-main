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
 * Sam3s DACC register definitions
 *
 * @author Thomas Schmid
 */

#ifndef SAM3SDACCHARDWARE_H
#define SAM3SDACCHARDWARE_H

#include "pdchardware.h"

/**
 * DACC Control Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t swrst    :  1; // Software Reset
        uint32_t reserved : 31;
    } __attribute__((__packed__)) bits;
} dacc_cr_t;

/**
 * DACC Mode Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t trgen     : 1; // Trigger Enable
        uint32_t trgsel    : 3; // Trigger Selection
        uint32_t word      : 1; // Word Transfer
        uint32_t sleep     : 1; // Sleep Mode
        uint32_t fastwkup  : 1; // Fast Wake Up Mode
        uint32_t reserved0 : 1;
        uint32_t refresh   : 8; // Refresh Period
        uint32_t user_sel  : 2; // User Channel Selection
        uint32_t reserved1 : 2;
        uint32_t tag       : 1; // Tag Selection Mode
        uint32_t maxs      : 1; // Max Speed Mode
        uint32_t reserved2 : 2;
        uint32_t startup   : 6; // Startup Time Selection
        uint32_t reserved3 : 2;
    } __attribute__((__packed__)) bits;
} dacc_mr_t;

/**
 * DACC Channel Enable Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t ch0      :  1; // Channel 0 enable
        uint32_t ch1      :  1; // Channel 1 enable
        uint32_t reserved : 30;
    } __attribute__((__packed__)) bits;
} dacc_cher_t;

/**
 * DACC Channel Disable Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t ch0      :  1; // Channel 0 disable
        uint32_t ch1      :  1; // Channel 1 disable
        uint32_t reserved : 30;
    } __attribute__((__packed__)) bits;
} dacc_chdr_t;

/**
 * DACC Channel Status Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t ch0      :  1; // Channel 0 Status 
        uint32_t ch1      :  1; // Channel 1 Status
        uint32_t reserved : 30;
    } __attribute__((__packed__)) bits;
} dacc_chsr_t;

/**
 * DACC Conversion Data Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t data    : 32; // Data to Convert
    } __attribute__((__packed__)) bits;
} dacc_cdr_t;

/**
 * DACC Interrupt Enable Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t txrdy     :  1; // Transmit Ready Interrupt Enable
        uint32_t eoc       :  1; // End of Conversion Interrupt Enable
        uint32_t endtx     :  1; // End of Transmit Buffer Interrupt Enable
        uint32_t txbufe    :  1; // Transmit Buffer Empty Interrupt Enable
        uint32_t reserved  : 28;
    } __attribute__((__packed__)) bits;
} dacc_ier_t;

/**
 * DACC Interrupt Disable Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t txrdy     :  1; // Transmit Ready Interrupt Disable
        uint32_t eoc       :  1; // End of Conversion Interrupt Disable
        uint32_t endtx     :  1; // End of Transmit Buffer Interrupt Disable
        uint32_t txbufe    :  1; // Transmit Buffer Empty Interrupt Disable
        uint32_t reserved  : 28;
    } __attribute__((__packed__)) bits;
} dacc_idr_t;

/**
 * DACC Interrupt Mask Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t txrdy     :  1; // Transmit Ready Interrupt Mask
        uint32_t eoc       :  1; // End of Conversion Interrupt Mask
        uint32_t endtx     :  1; // End of Transmit Buffer Interrupt Mask
        uint32_t txbufe    :  1; // Transmit Buffer Empty Interrupt Mask
        uint32_t reserved  : 28;
    } __attribute__((__packed__)) bits;
} dacc_imr_t;

/**
 * DACC Interrupt Status Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t txrdy     :  1; // Transmit Ready Interrupt Status
        uint32_t eoc       :  1; // End of Conversion Interrupt Status
        uint32_t endtx     :  1; // End of Transmit Buffer Interrupt Status
        uint32_t txbufe    :  1; // Transmit Buffer Empty Interrupt Status
        uint32_t reserved  : 28;
    } __attribute__((__packed__)) bits;
} dacc_isr_t;

/**
 * DACC Analog Current Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t ibctlch0     :  2; // Analog Output Current Control Channel 0
        uint32_t ibctlch1     :  2; // Analog Output Current Control Channel 1
        uint32_t reserved0    :  4;
        uint32_t ibctldaccore :  2; // Bias Current Control for DAC Core
        uint32_t reserved1    : 22;
    } __attribute__((__packed__)) bits;
} dacc_acr_t;

/**
 * DACC Write Protect Mode Register
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
} dacc_wpmr_t;

#define DACC_WPMR_KEY 0x444143

/**
 * DACC Write Protect Status Register
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t wproterr   :  1; // Write Protection error
        uint32_t reserved0  :  7;
        uint32_t wprotaddr  :  8; // Write protection error address
        uint32_t reserved1  : 16;
    } __attribute__((__packed__)) bits;
} dacc_wpsr_t;

/**
 * DACC Register definitions, AT91 ARM Cortex-M3 based Microcontrollers SAM3S
 * Series, Preliminary, p. 1019
 */
typedef struct dacc
{
    volatile dacc_cr_t   cr;   // Control Register
    volatile dacc_mr_t   mr;   // Mode Register
    uint32_t reserved0;
    uint32_t reserved1;
    volatile dacc_cher_t cher; // Channel Enable Register
    volatile dacc_chdr_t chdr; // Channel Disable Register
    volatile dacc_chsr_t chsr; // Channel Status Register
    uint32_t reserved2;
    volatile dacc_cdr_t  cdr;  // Channel Data Register
    volatile dacc_ier_t  ier;  // Ineterrupt Enable Register
    volatile dacc_idr_t  idr;  // Interrupt Disable Register
    volatile dacc_imr_t  imr;  // Interrupt Mask Register
    volatile dacc_isr_t  isr;  // Interrupt Status Register
    uint32_t reserved3[24];
    volatile dacc_acr_t  acr;  // Analog current Register
    uint32_t reserved4[19];
    volatile dacc_wpmr_t wpmr; // Write Protect Mode Register
    volatile dacc_wpsr_t wpsr; // Write Protect Status Register
    uint32_t reserved5[5];
    volatile periph_rpr_t rpr;
    volatile periph_rcr_t rcr;
    volatile periph_tpr_t tpr;
    volatile periph_tcr_t tcr;
    volatile periph_rnpr_t rnpr;
    volatile periph_rncr_t rncr;
    volatile periph_tnpr_t tnpr;
    volatile periph_tncr_t tncr;
    volatile periph_ptcr_t ptcr;
    volatile periph_ptsr_t ptsr;
} dacc_t;

/**
 * Memory mapping for the DACC
 */
#define DACC_BASE_ADDRESS 0x4003C000
volatile dacc_t* DACC = (volatile dacc_t *) DACC_BASE_ADDRESS; // DACC Base Address

#define DACC_MAX_CHANNELS 2

#endif //SAM3SADCHARDWARE_H


