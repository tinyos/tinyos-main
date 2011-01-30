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

#include "sam3uuarthardware.h"

/**
 * The hardware presentation layer for the SAM3U UART.
 *
 * @author Wanja Hofer <wanja@cs.fau.de>
 */

module HplSam3uUartP
{
	provides
	{
		interface HplSam3uUartConfig;
		interface HplSam3uUartControl;
		interface HplSam3uUartInterrupts;
		interface HplSam3uUartStatus;
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
	async command error_t HplSam3uUartConfig.setClockDivisor(uint16_t cd)
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
	async command error_t HplSam3uUartConfig.setChannelModeAndParityType(uint8_t chmode, uint8_t par)
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

	async command void HplSam3uUartInterrupts.disableAllUartIrqs()
	{
		call HplSam3uUartInterrupts.disableRxrdyIrq();
		call HplSam3uUartInterrupts.disableTxrdyIrq();
		call HplSam3uUartInterrupts.disableEndrxIrq();
		call HplSam3uUartInterrupts.disableEndtxIrq();
		call HplSam3uUartInterrupts.disableOvreIrq();
		call HplSam3uUartInterrupts.disableFrameIrq();
		call HplSam3uUartInterrupts.disablePareIrq();
		call HplSam3uUartInterrupts.disableTxemptyIrq();
		call HplSam3uUartInterrupts.disableTxbufeIrq();
		call HplSam3uUartInterrupts.disableRxbuffIrq();
	}

	async command void HplSam3uUartControl.resetReceiver()
	{
		UART_CR->bits.rstrx = 1;
	}
	async command void HplSam3uUartControl.resetTransmitter()
	{
		UART_CR->bits.rsttx = 1;
	}
	async command void HplSam3uUartControl.enableReceiver()
	{
		UART_CR->bits.rxen = 1;
	}
	async command void HplSam3uUartControl.disableReceiver()
	{
		UART_CR->bits.rxdis = 1;
	}
	async command void HplSam3uUartControl.enableTransmitter()
	{
		UART_CR->bits.txen = 1;
	}
	async command void HplSam3uUartControl.disableTransmitter()
	{
		UART_CR->bits.txdis = 1;
	}
	async command void HplSam3uUartControl.resetStatusBits()
	{
		UART_CR->bits.rststa = 1;
	}

	__attribute__((interrupt)) void UartIrqHandler() @C() @spontaneous()
	{
		call UartInterruptWrapper.preamble();
		if ((call HplSam3uUartInterrupts.isEnabledRxrdyIrq() == TRUE) &&
				(call HplSam3uUartStatus.isReceiverReady() == TRUE)) {
			uint8_t data = call HplSam3uUartStatus.getReceivedChar();
			signal HplSam3uUartInterrupts.receivedByte(data);
		}
		if ((call HplSam3uUartInterrupts.isEnabledTxrdyIrq() == TRUE) &&
				(call HplSam3uUartStatus.isTransmitterReady() == TRUE)) {
			signal HplSam3uUartInterrupts.transmitterReady();
		}
		call UartInterruptWrapper.postamble();
#ifdef THREADS
		call PlatformInterrupt.postAmble();
#endif
	}

	// Rxrdy
	async command void HplSam3uUartInterrupts.enableRxrdyIrq()
	{
		UART_IER->bits.rxrdy = 1;
	}
	async command void HplSam3uUartInterrupts.disableRxrdyIrq()
	{
		UART_IDR->bits.rxrdy = 1;
	}
	async command bool HplSam3uUartInterrupts.isEnabledRxrdyIrq()
	{
		return (UART_IMR->bits.rxrdy == 0x1);
	}

	// Txrdy
	async command void HplSam3uUartInterrupts.enableTxrdyIrq()
	{
		UART_IER->bits.txrdy = 1;
	}
	async command void HplSam3uUartInterrupts.disableTxrdyIrq()
	{
		UART_IDR->bits.txrdy = 1;
	}
	async command bool HplSam3uUartInterrupts.isEnabledTxrdyIrq()
	{
		return (UART_IMR->bits.txrdy == 0x1);
	}

	// Endrx
	async command void HplSam3uUartInterrupts.enableEndrxIrq()
	{
		UART_IER->bits.endrx = 1;
	}
	async command void HplSam3uUartInterrupts.disableEndrxIrq()
	{
		UART_IDR->bits.endrx = 1;
	}
	async command bool HplSam3uUartInterrupts.isEnabledEndrxIrq()
	{
		return (UART_IMR->bits.endrx == 0x1);
	}

	// Endtx
	async command void HplSam3uUartInterrupts.enableEndtxIrq()
	{
		UART_IER->bits.endtx = 1;
	}
	async command void HplSam3uUartInterrupts.disableEndtxIrq()
	{
		UART_IDR->bits.endtx = 1;
	}
	async command bool HplSam3uUartInterrupts.isEnabledEndtxIrq()
	{
		return (UART_IMR->bits.endtx == 0x1);
	}

	// Ovre
	async command void HplSam3uUartInterrupts.enableOvreIrq()
	{
		UART_IER->bits.ovre = 1;
	}
	async command void HplSam3uUartInterrupts.disableOvreIrq()
	{
		UART_IDR->bits.ovre = 1;
	}
	async command bool HplSam3uUartInterrupts.isEnabledOvreIrq()
	{
		return (UART_IMR->bits.ovre == 0x1);
	}

	// Frame
	async command void HplSam3uUartInterrupts.enableFrameIrq()
	{
		UART_IER->bits.frame = 1;
	}
	async command void HplSam3uUartInterrupts.disableFrameIrq()
	{
		UART_IDR->bits.frame = 1;
	}
	async command bool HplSam3uUartInterrupts.isEnabledFrameIrq()
	{
		return (UART_IMR->bits.frame == 0x1);
	}

	// Pare
	async command void HplSam3uUartInterrupts.enablePareIrq()
	{
		UART_IER->bits.pare = 1;
	}
	async command void HplSam3uUartInterrupts.disablePareIrq()
	{
		UART_IDR->bits.pare = 1;
	}
	async command bool HplSam3uUartInterrupts.isEnabledPareIrq()
	{
		return (UART_IMR->bits.pare == 0x1);
	}

	// Txempty
	async command void HplSam3uUartInterrupts.enableTxemptyIrq()
	{
		UART_IER->bits.txempty = 1;
	}
	async command void HplSam3uUartInterrupts.disableTxemptyIrq()
	{
		UART_IDR->bits.txempty = 1;
	}
	async command bool HplSam3uUartInterrupts.isEnabledTxemptyIrq()
	{
		return (UART_IMR->bits.txempty == 0x1);
	}

	// Txbufe
	async command void HplSam3uUartInterrupts.enableTxbufeIrq()
	{
		UART_IER->bits.txbufe = 1;
	}
	async command void HplSam3uUartInterrupts.disableTxbufeIrq()
	{
		UART_IDR->bits.txbufe = 1;
	}
	async command bool HplSam3uUartInterrupts.isEnabledTxbufeIrq()
	{
		return (UART_IMR->bits.txbufe == 0x1);
	}

	// Rxbuff
	async command void HplSam3uUartInterrupts.enableRxbuffIrq()
	{
		UART_IER->bits.rxbuff = 1;
	}
	async command void HplSam3uUartInterrupts.disableRxbuffIrq()
	{
		UART_IDR->bits.rxbuff = 1;
	}
	async command bool HplSam3uUartInterrupts.isEnabledRxbuffIrq()
	{
		return (UART_IMR->bits.rxbuff == 0x1);
	}

	async command uint8_t HplSam3uUartStatus.getReceivedChar()
	{
		return UART_RHR->bits.rxchr;
	}
	async command void HplSam3uUartStatus.setCharToTransmit(uint8_t txchr)
	{
		UART_THR->bits.txchr = txchr;
	}

	async command bool HplSam3uUartStatus.isReceiverReady()
	{
		return (UART_SR->bits.rxrdy == 0x1);
	}
	async command bool HplSam3uUartStatus.isTransmitterReady()
	{
		return (UART_SR->bits.txrdy == 0x1);
	}
	async command bool HplSam3uUartStatus.isEndOfReceiverTransfer()
	{
		return (UART_SR->bits.endrx == 0x1);
	}
	async command bool HplSam3uUartStatus.isEndOfTransmitterTransfer()
	{
		return (UART_SR->bits.endtx == 0x1);
	}
	async command bool HplSam3uUartStatus.isOverrunError()
	{
		return (UART_SR->bits.ovre == 0x1);
	}
	async command bool HplSam3uUartStatus.isFramingError()
	{
		return (UART_SR->bits.frame == 0x1);
	}
	async command bool HplSam3uUartStatus.isParityError()
	{
		return (UART_SR->bits.pare == 0x1);
	}
	async command bool HplSam3uUartStatus.isTransmitterEmpty()
	{
		return (UART_SR->bits.txempty == 0x1);
	}
	async command bool HplSam3uUartStatus.isTransmissionBufferEmpty()
	{
		return (UART_SR->bits.txbufe == 0x1);
	}
	async command bool HplSam3uUartStatus.isReceiveBufferFull()
	{
		return (UART_SR->bits.rxbuff == 0x1);
	}
}
