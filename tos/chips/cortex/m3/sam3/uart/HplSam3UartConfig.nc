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
 * Interface to configure the SAM3U UART.
 *
 * @author Wanja Hofer <wanja@cs.fau.de>
 */

interface HplSam3UartConfig
{
	/**
	 * cd = 0: baud rate generator disabled
	 * cd = 0: baud rate = MCK
	 * cd = 2--65535: baud rate = MCK / (cd * 16)
	 */
	async command error_t setClockDivisor(uint16_t cd);

	/**
	 * Have to be set together since they are in the same register.
	 *
	 * chmode = 0x0/UART_MR_CHMODE_NORMAL: normal
	 * chmode = 0x1/UART_MR_CHMODE_AUTOECHO: automatic echo
	 * chmode = 0x2/UART_MR_CHMODE_LOCALLOOP: local loopback
	 * chmode = 0x3/UART_MR_CHMODE_REMOTELOOP: remote loopback
	 *
	 * par = 0x0/UART_MR_PAR_EVEN: even
	 * par = 0x1/UART_MR_PAR_ODD: odd
	 * par = 0x2/UART_MR_PAR_SPACE: space (forced to 0)
	 * par = 0x3/UART_MR_PAR_MARK: mark (forced to 1)
	 * par = 0x4/UART_MR_PAR_NONE: none
	 */
	async command error_t setChannelModeAndParityType(uint8_t chmode, uint8_t par);
}
