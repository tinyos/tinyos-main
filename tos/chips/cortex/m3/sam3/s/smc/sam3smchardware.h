/**
 * "Copyright (c) 2009 The Regents of the University of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * Static Memory Controller Register Definitions
 *
 * @author Thomas Schmid
 */

#ifndef _SAM3SSMCHARDWARE_H
#define _SAM3SSMCHARDWARE_H

#include "smchardware.h"

/**
 *  SMC MODE Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3S Series, Preliminary 
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t read_mode    : 1; // read mode
        uint32_t write_mode   : 1; // write mode
        uint32_t reserved0    : 2;
        uint32_t exnw_mode    : 2; // nwait mode
        uint32_t reserved1    : 2;
        uint32_t reserved2    : 4;
        uint32_t dbw          : 2; // data bus width
        uint32_t reserved3    : 2;
        uint32_t tdf_cycles   : 4; // data float time
        uint32_t tdf_mode     : 1; // tdf optimization
        uint32_t reserved4    : 3;
        uint32_t pmen         : 1; // page mode enable (note, not in documentation, but in code at91lib!)
        uint32_t reserved5    : 3;
        uint32_t ps           : 2; // page mode size (note: not in documentation, but in code at91lib!)
        uint32_t reserved6    : 2;
    } __attribute__((__packed__)) bits;
} smc_mode_t;

typedef struct
{
    volatile smc_setup_t setup;
    volatile smc_pulse_t pulse;
    volatile smc_cycle_t cycle;
    volatile smc_mode_t mode;
} smc_cs_t;

volatile smc_cs_t* SMC_CS0 = (volatile smc_cs_t*)0x400E0000; 
volatile smc_cs_t* SMC_CS1 = (volatile smc_cs_t*)0x400E0010; 
volatile smc_cs_t* SMC_CS2 = (volatile smc_cs_t*)0x400E0020; 
volatile smc_cs_t* SMC_CS3 = (volatile smc_cs_t*)0x400E0030; 
volatile smc_cs_t* SMC_CS4 = (volatile smc_cs_t*)0x400E0040; // questionable...  

#endif //_SAM3USMCHARDWARE_H
