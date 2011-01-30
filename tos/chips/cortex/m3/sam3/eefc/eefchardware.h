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
 * Enhanced Embedded Flash Controller register definitions.
 *
 * @author Thomas Schmid
 */

#ifndef _EFFCHARDWARE_H
#define _EFFCHARDWARE_H

/**
 * EEFC Flash Mode Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 315
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t frdy        :  1; // ready interrupt enable
        uint8_t reserved0   :  7;
        uint8_t fws         :  4; // flash wait state
        uint8_t reserved1   :  4;
        uint8_t reserved2   :  8;
        uint8_t fam         :  1; // flash access mode
        uint8_t reserved3   :  7;
    } __attribute__((__packed__)) bits;
} eefc_fmr_t;

/**
 * EEFC Flash Command Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 316
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t  fcmd       :  8; // flash command
        uint16_t farg       : 16; // flash command argument
        uint8_t  fkey       :  8; // flash writing protection key, has to be written as 0x5A!
    } __attribute__((__packed__)) bits;
} eefc_fcr_t;

// For more details on the flash commands, see AT91 ARM Cortex-M3 based
// Microcontrollers SAM3U Series, Preliminary, p. 309
#define EFFC_FCMD_GET_FLASH_DESCRIPTOR         0x0
#define EFFC_FCMD_WRITE_PAGE                   0x1
#define EFFC_FCMD_WRITE_PAGE_LOCK              0x2
#define EFFC_FCMD_ERASE_PAGE_WRITE_PAGE        0x3
#define EFFC_FCMD_ERASE_PAGE_WRITE_PAGE_LOCK   0x4
#define EFFC_FCMD_ERASE_ALL                    0x5
#define EFFC_FCMD_SET_LOCK                     0x8
#define EFFC_FCMD_CLEAR_LOCK                   0x9
#define EFFC_FCMD_GET_LOCK                     0xA
#define EFFC_FCMD_SET_GPNVM                    0xB
#define EFFC_FCMD_CLEAR_GPNVM                  0xC
#define EFFC_FCMD_GET_GPNVM                    0xD
#define EFFC_FCMD_START_READ_UNIQUE_ID         0xE
#define EFFC_FCMD_STOP_READ_UNIQUE_ID          0xF

#define EFFC_FCR_KEY                           0x5A
 
/**
 * EEFC Flash Status Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 317
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint8_t frdy              :  1; // flash ready status
        uint8_t fcmde             :  1; // flash command error status
        uint8_t flocke            :  1; // flash lock error status
        uint8_t reserved0         :  5;
        uint8_t reserved1         :  8;
        uint16_t reserved2        : 16;
    } __attribute__((__packed__)) bits;
} eefc_fsr_t;
 
/**
 * EEFC Flash Result Register, AT91 ARM Cortex-M3 based Microcontrollers
 * SAM3U Series, Preliminary, p. 318
 */
typedef union
{
    uint32_t flat;
    struct
    {
        uint32_t fvalue  : 32; // flash result value
    } __attribute__((__packed__)) bits;
} eefc_frr_t;
 
/**
 * EEFC Register definition, AT91 ARM Cortex-M3 based Microcontrollers SAM3U
 * Series, Preliminary, p. 314
 */

typedef struct effc
{
    volatile eefc_fmr_t fmr; // EEFC Flash Mode Register
    volatile eefc_fcr_t fcr; // EEFC Flash Command Register
    volatile eefc_fsr_t fsr; // EEFC Flash Status Register
    volatile eefc_frr_t frr; // EEFC Flash Result Register
} eefc_t;


#endif // _EFFCHARDWARE_H
