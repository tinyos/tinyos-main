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
 * Bus Matrix register definitions.
 *
 * @author Thomas Schmid
 */

#ifndef _MATRIXHARDWARE_H
#define _MATRIXHARDWARE_H


/**
 * Bus Matrix Master Configuration Register, AT91 ARM Cortex-M3 based
 * Microcontrollers SAM3U Series, Preliminary, p. 341
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t ulbt       :  3; // undefined length burst type
        uint8_t reserved0  :  5;
        uint8_t reserved1  :  8;
        uint16_t reserved2 : 16;
    }__attribute__((__packed__)) bits;
} matrix_mcfg_t;

#define MATRIX_MCFG_ULBT_INFINITE_BURST      0x0
#define MATRIX_MCFG_ULBT_SINGLE_ACCESS       0x1
#define MATRIX_MCFG_ULBT_FOUR_BEAT_BURST     0x2
#define MATRIX_MCFG_ULBT_EIGHT_BEAT_BURST    0x3
#define MATRIX_MCFG_ULBT_SIXTEEN_BEAT_BURST  0x4

/**
 * Bus Matrix Slave Configuration Register, AT91 ARM Cortex-M3 based
 * Microcontrollers SAM3U Series, Preliminary, p. 342
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t slot_cycle   :  8; // maximum number of allowed cycles for a burst
        uint8_t reserved0    :  8;
        uint8_t defmstr_type :  2; // default master type
        uint8_t fixed_defmstr:  3; // fixed default master
        uint8_t reserved1    :  3;
        uint8_t arbt         :  2; // arbitration type
        uint8_t reserved2    :  6;
    }__attribute__((__packed__)) bits;
} matrix_scfg_t;

#define MATRIX_SCFG_MASTER_TYPE_NO_DEFAULT     0x0
#define MATRIX_SCFG_MASTER_TYPE_LAST_DEFAULT   0x1
#define MATRIX_SCFG_MASTER_TYPE_FIXED_DEFAULT  0x2

#define MATRIX_SCFG_ARBT_ROUND_ROBINT          0x0
#define MATRIX_SCFG_ARBT_FIXED_PRIO            0x1


/**
 * Bus Matrix Priority Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 343
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t m0pr         : 2; // master 0 priority
        uint8_t reserved0    : 2;
        uint8_t m1pr         : 2; // master 1 priority
        uint8_t reserved1    : 2;
        uint8_t m2pr         : 2; // master 2 priority
        uint8_t reserved2    : 2;
        uint8_t m3pr         : 2; // master 3 priority
        uint8_t reserved3    : 2;
        uint8_t m4pr         : 2; // master 4 priority
        uint8_t reserved4    : 6;
        uint8_t reserved5    : 8;
    }__attribute__((__packed__)) bits;
} matrix_pras_t;

/**
 * Bus Matrix Master Remap Control Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 344
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t rcb0        :  1; // remap command bit for ahb master 0
        uint8_t rcb1        :  1; // remap command bit for ahb master 1
        uint8_t rcb2        :  1; // remap command bit for ahb master 2
        uint8_t rcb3        :  1; // remap command bit for ahb master 3
        uint8_t rcb4        :  1; // remap command bit for ahb master 4
        uint8_t reserved0   :  3;
        uint8_t reserved1   :  8;
        uint16_t reserved2  : 16;
    }__attribute__((__packed__)) bits;
} matrix_mrcr_t;

/**
 * Bus Matrix Write Protection Mode Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 350
 */
typedef union
{
    uint32_t flat;
    struct
    {
      uint32_t wpen       :  1;
      uint32_t reserved0  :  7;
      uint32_t wpkey      : 24;
    }__attribute__((__packed__)) bits;
} matrix_wpmr_t;

/**
 * Bus Matrix Write Protection Mode Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 350
 */
typedef union
{
    uint32_t flat;
    struct
    {
      uint8_t wpvs       :  1;
      uint8_t reserved0  :  7;
      uint16_t wpkey     : 16;
      uint8_t reserved1  :  8;
    }__attribute__((__packed__)) bits;
} matrix_wpsr_t;



#endif // _MATRIXHARDWARE_H
