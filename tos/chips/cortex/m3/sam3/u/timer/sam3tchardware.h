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

