/**
 * Copyright (c) 2009 The Regents of the University of California.
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
