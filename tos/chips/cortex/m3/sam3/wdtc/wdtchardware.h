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
 * Watchdog Timer register definitions.
 *
 * @author Thomas Schmid
 */

#ifndef _WDTCHARDWARE_H
#define _WDTCHARDWARE_H

/**
 *  WDTC Control Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 275
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t wdrstt         :  1; // watchdog restart
        uint8_t reserved0      :  7;
        uint16_t reserved1     : 16;
        uint8_t key            :  8; // password, should be written as 0xA5
    } __attribute__((__packed__)) bits;
} wdtc_cr_t; 

#define WDTC_CR_KEY 0xA5

/**
 *  WDTC Mode Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 276
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint16_t wdv          : 12; // counter value
        uint8_t wdfien        :  1; // fault interrupt enable
        uint8_t wdrsten       :  1; // reset enable
        uint8_t wdrproc       :  1; // reset processor
        uint8_t wddis         :  1; // watchdog disable
        uint16_t wdd          : 12; // delta value
        uint8_t wddbghlt      :  1; // debug halt
        uint8_t wdidlehlt     :  1; // idle halt
        uint8_t reserved0     :  2;
    } __attribute__((__packed__)) bits;
} wdtc_mr_t; 

/**
 *  WDTC Timer Status Register, AT91 ARM Cortex-M3 based Microcontrollers
 *  SAM3U Series, Preliminary, p. 277
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t wdunf        :  1; // underflow
        uint8_t wderr        :  1; // error
        uint8_t reserved0    :  6;
        uint8_t reserved1    :  8;
        uint16_t reserved2   : 16;
    } __attribute__((__packed__)) bits;
} wdtc_sr_t; 

/**
 * WDTC Register definitions, AT91 ARM Cortex-M3 based Microcontrollers SAM3U
 * Series, Preliminary, p. 274
 */
typedef struct wdtc
{
    volatile wdtc_cr_t cr; // Control Register
    volatile wdtc_mr_t mr; // Mode Register
    volatile wdtc_sr_t sr; // Status Register
} wdtc_t;

#endif // _WDTCHARDWARE_H
