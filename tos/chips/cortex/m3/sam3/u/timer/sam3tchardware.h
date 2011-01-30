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
 * Timer Counter register definitions.
 *
 * @author Thomas Schmid
 */

#ifndef SAM3UTCHARDWARE_H
#define SAM3UTCHARDWARE_H

#include "tchardware.h"

/**
 * TC definition capture mode
 */
typedef struct
{
    volatile tc_channel_capture_t ch0;
    uint32_t reserved0[4];
    volatile tc_channel_capture_t ch1;
    uint32_t reserved1[4];
    volatile tc_channel_capture_t ch2;
    uint32_t reserved2[4];
    volatile tc_bcr_t bcr;
    volatile tc_bmr_t bmr;
    volatile tc_qier_t qier;
    volatile tc_qidr_t qidr;
    volatile tc_qimr_t qimr;
    volatile tc_qisr_t qisr;
} tc_t;

/**
 * TC Register definitions, AT91 ARM Cortex-M3 based Microcontrollers SAM3U
 * Series, Preliminary 9/1/09, p. 827
 */
#define TC_BASE     0x40080000
#define TC_CH0_BASE 0x40080000
#define TC_CH1_BASE 0x40080040
#define TC_CH2_BASE 0x40080080

volatile tc_t* TC = (volatile tc_t*)TC_BASE;

#endif //SAM3UTCHARDWARE_H

