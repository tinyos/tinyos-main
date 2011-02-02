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

#ifndef UARTHARDWARE_H
#define UARTHARDWARE_H

// Defined in AT91 ARM Cortex-M3 based Microcontrollers, SAM3U Series, Preliminary, p. 668
typedef union
{
	uint32_t flat;
	struct
	{
		uint8_t reserved3 : 2;
		uint8_t rstrx     : 1; // reset receiver
		uint8_t rsttx     : 1; // reset transmitter
		uint8_t rxen      : 1; // receiver enable
		uint8_t rxdis     : 1; // receiver disable
		uint8_t txen      : 1; // transmitter enable
		uint8_t txdis     : 1; // transmitter disable
		uint8_t rststa    : 1; // reset status bits
		uint8_t reserved2 : 7;
		uint8_t reserved1 : 8;
		uint8_t reserved0 : 8;
	} bits;
} uart_cr_t;

// Defined in AT91 ARM Cortex-M3 based Microcontrollers, SAM3U Series, Preliminary, p. 669
typedef union
{
	uint32_t flat;
	struct
	{
		uint8_t reserved4 : 8;
		uint8_t reserved3 : 1;
		uint8_t par       : 3; // parity type
		uint8_t reserved2 : 2;
		uint8_t chmode    : 2; // channel mode
		uint8_t reserved1 : 8;
		uint8_t reserved0 : 8;
	} bits;
} uart_mr_t;

enum
{
	UART_MR_PAR_EVEN  = 0x0,
	UART_MR_PAR_ODD   = 0x1,
	UART_MR_PAR_SPACE = 0x2,
	UART_MR_PAR_MARK  = 0x3,
	UART_MR_PAR_NONE  = 0x4
};

enum
{
	UART_MR_CHMODE_NORMAL     = 0x0,
	UART_MR_CHMODE_AUTOECHO   = 0x1,
	UART_MR_CHMODE_LOCALLOOP  = 0x2,
	UART_MR_CHMODE_REMOTELOOP = 0x3
};

// Defined in AT91 ARM Cortex-M3 based Microcontrollers, SAM3U Series, Preliminary, p. 670
typedef union
{
	uint32_t flat;
	struct
	{
		uint8_t rxrdy     : 1; // receiver ready
		uint8_t txrdy     : 1; // transmitter ready
		uint8_t reserved5 : 1;
		uint8_t endrx     : 1; // end of receiver transfer
		uint8_t endtx     : 1; // end of transmitter transfer
		uint8_t ovre      : 1; // overrun error
		uint8_t frame     : 1; // framing error
		uint8_t pare      : 1; // parity error
		uint8_t reserved4 : 1;
		uint8_t txempty   : 1; // transmitter empty
		uint8_t reserved3 : 1;
		uint8_t txbufe    : 1; // transmission buffer empty
		uint8_t rxbuff    : 1; // receive buffer full
		uint8_t reserved2 : 3;
		uint8_t reserved1 : 8;
		uint8_t reserved0 : 8;
	} bits;
} uart_ier_t;

// Defined in AT91 ARM Cortex-M3 based Microcontrollers, SAM3U Series, Preliminary, p. 671
typedef uart_ier_t uart_idr_t;

// Defined in AT91 ARM Cortex-M3 based Microcontrollers, SAM3U Series, Preliminary, p. 672
typedef uart_ier_t uart_imr_t;

// Defined in AT91 ARM Cortex-M3 based Microcontrollers, SAM3U Series, Preliminary, p. 673
typedef uart_ier_t uart_sr_t;

// Defined in AT91 ARM Cortex-M3 based Microcontrollers, SAM3U Series, Preliminary, p. 675
typedef union
{
	uint32_t flat;
	struct
	{
		uint8_t rxchr     : 8; // received character
		uint8_t reserved2 : 8;
		uint8_t reserved1 : 8;
		uint8_t reserved0 : 8;
	} bits;
} uart_rhr_t;

// Defined in AT91 ARM Cortex-M3 based Microcontrollers, SAM3U Series, Preliminary, p. 675
typedef union
{
	uint32_t flat;
	struct
	{
		uint8_t txchr     : 8; // character to be transmitted
		uint8_t reserved2 : 8;
		uint8_t reserved1 : 8;
		uint8_t reserved0 : 8;
	} bits;
} uart_thr_t;

// Defined in AT91 ARM Cortex-M3 based Microcontrollers, SAM3U Series, Preliminary, p. 676
typedef union
{
	uint32_t flat;
	struct
	{
		uint16_t cd        : 16; // clock divisor
		uint8_t  reserved1 :  8;
		uint8_t  reserved0 :  8;
	} bits;
} uart_brgr_t;

#endif // UARTHARDWARE_H
