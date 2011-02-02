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
 * Interface to control and query SAM3U UART interrupts.
 *
 * @author Wanja Hofer <wanja@cs.fau.de>
 */

interface HplSam3UartInterrupts
{
	async event void receivedByte(uint8_t data);

	async event void transmitterReady();

	async command void disableAllUartIrqs();

	async command void enableRxrdyIrq();
	async command void disableRxrdyIrq();
	async command bool isEnabledRxrdyIrq();

	async command void enableTxrdyIrq();
	async command void disableTxrdyIrq();
	async command bool isEnabledTxrdyIrq();

	async command void enableEndrxIrq();
	async command void disableEndrxIrq();
	async command bool isEnabledEndrxIrq();

	async command void enableEndtxIrq();
	async command void disableEndtxIrq();
	async command bool isEnabledEndtxIrq();

	async command void enableOvreIrq();
	async command void disableOvreIrq();
	async command bool isEnabledOvreIrq();

	async command void enableFrameIrq();
	async command void disableFrameIrq();
	async command bool isEnabledFrameIrq();

	async command void enablePareIrq();
	async command void disablePareIrq();
	async command bool isEnabledPareIrq();

	async command void enableTxemptyIrq();
	async command void disableTxemptyIrq();
	async command bool isEnabledTxemptyIrq();

	async command void enableTxbufeIrq();
	async command void disableTxbufeIrq();
	async command bool isEnabledTxbufeIrq();

	async command void enableRxbuffIrq();
	async command void disableRxbuffIrq();
	async command bool isEnabledRxbuffIrq();
}
