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
