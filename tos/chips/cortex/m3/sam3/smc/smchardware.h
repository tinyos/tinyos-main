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
