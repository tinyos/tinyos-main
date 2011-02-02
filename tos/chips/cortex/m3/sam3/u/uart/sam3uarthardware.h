/*
 * Copyright (c) 2009 Stanford University.
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
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Definitions specific to the SAM3U UART chip.
 *
 * @author Wanja Hofer <wanja@cs.fau.de>
 */

#ifndef SAM3UUARTHARDWARE_H
#define SAM3UUARTHARDWARE_H

#include "uarthardware.h"

// Defined in AT91 ARM Cortex-M3 based Microcontrollers, SAM3U Series, Preliminary, p. 667
volatile uint32_t*    UART_BASE = (volatile uint32_t *)   0x400e0600;
volatile uart_cr_t*   UART_CR   = (volatile uart_cr_t*)   0x400e0600; // control, wo
volatile uart_mr_t*   UART_MR   = (volatile uart_mr_t*)   0x400e0604; // mode, rw, reset 0x0
volatile uart_ier_t*  UART_IER  = (volatile uart_ier_t*)  0x400e0608; // interrupt enable, wo
volatile uart_idr_t*  UART_IDR  = (volatile uart_idr_t*)  0x400e060c; // interrupt disable, wo
volatile uart_imr_t*  UART_IMR  = (volatile uart_imr_t*)  0x400e0610; // interrupt mask, ro, reset 0x0
volatile uart_sr_t*   UART_SR   = (volatile uart_sr_t*)   0x400e0614; // status, ro
volatile uart_rhr_t*  UART_RHR  = (volatile uart_rhr_t*)  0x400e0618; // receive holding, ro, reset 0x0
volatile uart_thr_t*  UART_THR  = (volatile uart_thr_t*)  0x400e061c; // transmit holding, wo
volatile uart_brgr_t* UART_BRGR = (volatile uart_brgr_t*) 0x400e0620; // baud rate generator, rw, reset 0x0

#endif // SAM3UUARTHARDWARE_H
