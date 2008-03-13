/*
 * Copyright (c) 2006, Technische Universitat Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitat Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * - Revision -------------------------------------------------------------
 * $Revision: 1.11 $
 * $Date: 2008-03-13 17:09:07 $
 * ========================================================================
 */

#include "msp430usart.h"

#ifndef TDA5250BUSRESOURCEID_H
#define TDA5250BUSRESOURCEID_H

enum {
    TDA5250_UART_BUS_ID = unique(MSP430_UARTO_BUS)
};

/* frequency of crystal: 18089580 Hz,
   divide by 18 -> 1004976 Hz */

#ifndef TDA5250_UART_BAUDRATE
#define TDA5250_UART_BAUDRATE 23405U
#endif

enum {
    /** use real frequency, use only settings that result in an even byte time */
    UBR_1MHZ_10240=0x0062,  UMCTL_1MHZ_10240=0x08, // 10240 bit/s
    UBR_1MHZ_10922=0x005C,  UMCTL_1MHZ_10922=0x00, // 10922 bit/s
    UBR_1MHZ_11702=0x0055,  UMCTL_1MHZ_11702=0xEF, // 11702 bit/s
    UBR_1MHZ_12603=0x004F,  UMCTL_1MHZ_12603=0xDD, // 12603 bit/s
    UBR_1MHZ_13653=0x0049,  UMCTL_1MHZ_13653=0xB5, // 13653 bit/s
    UBR_1MHZ_14894=0x0043,  UMCTL_1MHZ_14894=0xAA, // 14894 bit/s
    UBR_1MHZ_16384=0x003D,  UMCTL_1MHZ_16384=0x92, // 16384 bit/s
    UBR_1MHZ_18204=0x0037,  UMCTL_1MHZ_18204=0x84, // 18204 bit/s
    UBR_1MHZ_20480=0x0031,  UMCTL_1MHZ_20480=0x80, // 20480 bit/s
    UBR_1MHZ_23405=0x002A,  UMCTL_1MHZ_23405=0x7F, // 23405 bit/s
    UBR_1MHZ_27306=0x0024,  UMCTL_1MHZ_27306=0x7B, // 27306 bit/s
    UBR_1MHZ_32768=0x001E,  UMCTL_1MHZ_32768=0x5B, // 32768 bit/s
    UBR_1MHZ_40960=0x0018,  UMCTL_1MHZ_40960=0x55, // 40960 bit/s
};

#include "eyesIFXBaudrates.h"

msp430_uart_union_config_t tda5250_uart_config = { {ubr: TDA5250_UART_UBR, umctl: TDA5250_UART_UMCTL, ssel: 0x02, pena: 0, pev: 0, spb: 0, clen: 1, listen: 0, mm: 0, ckpl: 0, urxse: 0, urxeie:0, urxwie: 0, urxe: 1, utxe: 0} };

enum {
    TDA5250_32KHZ_BYTE_TIME = (32768UL*10)/TDA5250_UART_BAUDRATE
};

#endif
