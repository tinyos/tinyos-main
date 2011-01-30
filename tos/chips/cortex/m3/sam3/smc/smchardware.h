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

#ifndef _SAM3SMCHARDWARE_H
#define _SAM3SMCHARDWARE_H

/**
 *  SMC SETUP Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t nwe_setup     : 6; // NWE Setup length
        uint32_t reserved0     : 2;
        uint32_t ncs_wr_setup  : 6; // ncs setup length in write access
        uint32_t reserved1     : 2;
        uint32_t nrd_setup     : 6; // nrd setup length
        uint32_t reserved2     : 2;
        uint32_t ncs_rd_setup  : 6; // ncs setup length in read access
        uint32_t reserved3     : 2;
    } __attribute__((__packed__)) bits;
} smc_setup_t;

/**
 *  SMC PULSE Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t nwe_pulse     : 6; // NWE setup length
        uint32_t reserved0     : 2;
        uint32_t ncs_wr_pulse  : 6; // ncs setup length in write access
        uint32_t reserved1     : 2;
        uint32_t nrd_pulse     : 6; // nrd setup length
        uint32_t reserved2     : 2;
        uint32_t ncs_rd_pulse  : 6; // ncs setup length in read access
        uint32_t reserved3     : 2;
    } __attribute__((__packed__)) bits;
} smc_pulse_t;

/**
 *  SMC CYCLE Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary 9/1/09, p. 
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t nwe_cycle    : 9; // total write cycle length
        uint32_t reserved0    : 7;
        uint32_t nrd_cycle    : 9; // total read cycle length
        uint32_t reserved1    : 7;
    } __attribute__((__packed__)) bits;
} smc_cycle_t;


#endif //_SAM3SMCHARDWARE_H
