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

#include "sam3uarthardware.h"

/**
 * The hardware presentation layer for the SAM3U UART.
 *
 * @author Wanja Hofer <wanja@cs.fau.de>
 */

module HplSam3UartP
{
	provides
	{
		interface HplSam3UartConfig;
		interface HplSam3UartControl;
		interface HplSam3UartInterrupts;
		interface HplSam3UartStatus;
	}
        uses {
		interface FunctionWrapper as UartInterruptWrapper;
#ifdef THREADS
		interface PlatformInterrupt;
#endif
	}
}
implementation
{
	/**
	 * cd = 0: baud rate generator disabled
	 * cd = 0: baud rate = MCK
	 * cd = 2--65535: baud rate = MCK / (cd * 16)
	 */
	async command error_t HplSam3UartConfig.setClockDivisor(uint16_t cd)
	{
		UART_BRGR->bits.cd = cd;
		return SUCCESS;
	}

	/**
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
	async command error_t HplSam3UartConfig.setChannelModeAndParityType(uint8_t chmode, uint8_t par)
	{
		uart_mr_t reg;

		if (chmode > 0x3) return FAIL;
		if (par > 0x4) return FAIL;

		reg.flat = 0;
		reg.bits.par = par;
		reg.bits.chmode = chmode;
		*UART_MR = reg;

		return SUCCESS;
	}

	async command void HplSam3UartInterrupts.disableAllUartIrqs()
	{
		call HplSam3UartInterrupts.disableRxrdyIrq();
		call HplSam3UartInterrupts.disableTxrdyIrq();
		call HplSam3UartInterrupts.disableEndrxIrq();
		call HplSam3UartInterrupts.disableEndtxIrq();
		call HplSam3UartInterrupts.disableOvreIrq();
		call HplSam3UartInterrupts.disableFrameIrq();
		call HplSam3UartInterrupts.disablePareIrq();
		call HplSam3UartInterrupts.disableTxemptyIrq();
		call HplSam3UartInterrupts.disableTxbufeIrq();
		call HplSam3UartInterrupts.disableRxbuffIrq();
	}

	async command void HplSam3UartControl.resetReceiver()
	{
		UART_CR->bits.rstrx = 1;
	}
	async command void HplSam3UartControl.resetTransmitter()
	{
		UART_CR->bits.rsttx = 1;
	}
	async command void HplSam3UartControl.enableReceiver()
	{
		UART_CR->bits.rxen = 1;
	}
	async command void HplSam3UartControl.disableReceiver()
	{
		UART_CR->bits.rxdis = 1;
	}
	async command void HplSam3UartControl.enableTransmitter()
	{
		UART_CR->bits.txen = 1;
	}
	async command void HplSam3UartControl.disableTransmitter()
	{
		UART_CR->bits.txdis = 1;
	}
	async command void HplSam3UartControl.resetStatusBits()
	{
		UART_CR->bits.rststa = 1;
	}

	__attribute__((interrupt)) void UartIrqHandler() @C() @spontaneous()
	{
		call UartInterruptWrapper.preamble();
		if ((call HplSam3UartInterrupts.isEnabledRxrdyIrq() == TRUE) &&
				(call HplSam3UartStatus.isReceiverReady() == TRUE)) {
			uint8_t data = call HplSam3UartStatus.getReceivedChar();
			signal HplSam3UartInterrupts.receivedByte(data);
		}
		if ((call HplSam3UartInterrupts.isEnabledTxrdyIrq() == TRUE) &&
				(call HplSam3UartStatus.isTransmitterReady() == TRUE)) {
			signal HplSam3UartInterrupts.transmitterReady();
		}
		call UartInterruptWrapper.postamble();
#ifdef THREADS
		call PlatformInterrupt.postAmble();
#endif
	}

	// Rxrdy
	async command void HplSam3UartInterrupts.enableRxrdyIrq()
	{
		UART_IER->bits.rxrdy = 1;
	}
	async command void HplSam3UartInterrupts.disableRxrdyIrq()
	{
		UART_IDR->bits.rxrdy = 1;
	}
	async command bool HplSam3UartInterrupts.isEnabledRxrdyIrq()
	{
		return (UART_IMR->bits.rxrdy == 0x1);
	}

	// Txrdy
	async command void HplSam3UartInterrupts.enableTxrdyIrq()
	{
		UART_IER->bits.txrdy = 1;
	}
	async command void HplSam3UartInterrupts.disableTxrdyIrq()
	{
		UART_IDR->bits.txrdy = 1;
	}
	async command bool HplSam3UartInterrupts.isEnabledTxrdyIrq()
	{
		return (UART_IMR->bits.txrdy == 0x1);
	}

	// Endrx
	async command void HplSam3UartInterrupts.enableEndrxIrq()
	{
		UART_IER->bits.endrx = 1;
	}
	async command void HplSam3UartInterrupts.disableEndrxIrq()
	{
		UART_IDR->bits.endrx = 1;
	}
	async command bool HplSam3UartInterrupts.isEnabledEndrxIrq()
	{
		return (UART_IMR->bits.endrx == 0x1);
	}

	// Endtx
	async command void HplSam3UartInterrupts.enableEndtxIrq()
	{
		UART_IER->bits.endtx = 1;
	}
	async command void HplSam3UartInterrupts.disableEndtxIrq()
	{
		UART_IDR->bits.endtx = 1;
	}
	async command bool HplSam3UartInterrupts.isEnabledEndtxIrq()
	{
		return (UART_IMR->bits.endtx == 0x1);
	}

	// Ovre
	async command void HplSam3UartInterrupts.enableOvreIrq()
	{
		UART_IER->bits.ovre = 1;
	}
	async command void HplSam3UartInterrupts.disableOvreIrq()
	{
		UART_IDR->bits.ovre = 1;
	}
	async command bool HplSam3UartInterrupts.isEnabledOvreIrq()
	{
		return (UART_IMR->bits.ovre == 0x1);
	}

	// Frame
	async command void HplSam3UartInterrupts.enableFrameIrq()
	{
		UART_IER->bits.frame = 1;
	}
	async command void HplSam3UartInterrupts.disableFrameIrq()
	{
		UART_IDR->bits.frame = 1;
	}
	async command bool HplSam3UartInterrupts.isEnabledFrameIrq()
	{
		return (UART_IMR->bits.frame == 0x1);
	}

	// Pare
	async command void HplSam3UartInterrupts.enablePareIrq()
	{
		UART_IER->bits.pare = 1;
	}
	async command void HplSam3UartInterrupts.disablePareIrq()
	{
		UART_IDR->bits.pare = 1;
	}
	async command bool HplSam3UartInterrupts.isEnabledPareIrq()
	{
		return (UART_IMR->bits.pare == 0x1);
	}

	// Txempty
	async command void HplSam3UartInterrupts.enableTxemptyIrq()
	{
		UART_IER->bits.txempty = 1;
	}
	async command void HplSam3UartInterrupts.disableTxemptyIrq()
	{
		UART_IDR->bits.txempty = 1;
	}
	async command bool HplSam3UartInterrupts.isEnabledTxemptyIrq()
	{
		return (UART_IMR->bits.txempty == 0x1);
	}

	// Txbufe
	async command void HplSam3UartInterrupts.enableTxbufeIrq()
	{
		UART_IER->bits.txbufe = 1;
	}
	async command void HplSam3UartInterrupts.disableTxbufeIrq()
	{
		UART_IDR->bits.txbufe = 1;
	}
	async command bool HplSam3UartInterrupts.isEnabledTxbufeIrq()
	{
		return (UART_IMR->bits.txbufe == 0x1);
	}

	// Rxbuff
	async command void HplSam3UartInterrupts.enableRxbuffIrq()
	{
		UART_IER->bits.rxbuff = 1;
	}
	async command void HplSam3UartInterrupts.disableRxbuffIrq()
	{
		UART_IDR->bits.rxbuff = 1;
	}
	async command bool HplSam3UartInterrupts.isEnabledRxbuffIrq()
	{
		return (UART_IMR->bits.rxbuff == 0x1);
	}

	async command uint8_t HplSam3UartStatus.getReceivedChar()
	{
		return UART_RHR->bits.rxchr;
	}
	async command void HplSam3UartStatus.setCharToTransmit(uint8_t txchr)
	{
		UART_THR->bits.txchr = txchr;
	}

	async command bool HplSam3UartStatus.isReceiverReady()
	{
		return (UART_SR->bits.rxrdy == 0x1);
	}
	async command bool HplSam3UartStatus.isTransmitterReady()
	{
		return (UART_SR->bits.txrdy == 0x1);
	}
	async command bool HplSam3UartStatus.isEndOfReceiverTransfer()
	{
		return (UART_SR->bits.endrx == 0x1);
	}
	async command bool HplSam3UartStatus.isEndOfTransmitterTransfer()
	{
		return (UART_SR->bits.endtx == 0x1);
	}
	async command bool HplSam3UartStatus.isOverrunError()
	{
		return (UART_SR->bits.ovre == 0x1);
	}
	async command bool HplSam3UartStatus.isFramingError()
	{
		return (UART_SR->bits.frame == 0x1);
	}
	async command bool HplSam3UartStatus.isParityError()
	{
		return (UART_SR->bits.pare == 0x1);
	}
	async command bool HplSam3UartStatus.isTransmitterEmpty()
	{
		return (UART_SR->bits.txempty == 0x1);
	}
	async command bool HplSam3UartStatus.isTransmissionBufferEmpty()
	{
		return (UART_SR->bits.txbufe == 0x1);
	}
	async command bool HplSam3UartStatus.isReceiveBufferFull()
	{
		return (UART_SR->bits.rxbuff == 0x1);
	}
}
