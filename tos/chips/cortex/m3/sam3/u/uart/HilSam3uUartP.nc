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
 * UART implementation for the SAM3U chip. Does not use DMA (PDC) at this
 * point, but does use IRQs for operation.
 *
 * @author Wanja Hofer <wanja@cs.fau.de>
 */

#include "sam3uuarthardware.h"

module HilSam3uUartP
{
	provides
	{
		interface Init;
		interface StdControl;
		interface UartByte;
		interface UartStream;
	}
	uses
	{
		interface HplSam3uUartControl;
		interface HplSam3uUartInterrupts;
		interface HplSam3uUartStatus;
		interface HplSam3uUartConfig;
		interface HplNVICInterruptCntl as UartIrqControl;
		interface HplSam3uGeneralIOPin as UartPin1;
		interface HplSam3uGeneralIOPin as UartPin2;
		interface HplSam3uPeripheralClockCntl as UartClockControl;
		interface HplSam3uClock as ClockConfig;
	}
}
implementation
{
	uint8_t *receiveBuffer; // pointer to current receive buffer or 0 if none
	uint16_t receiveBufferLength; // length of the current receive buffer
	uint16_t receiveBufferPosition; // position of the next character to receive in the buffer

	uint8_t *transmitBuffer; // pointer to current transmit buffer or 0 if none
	uint16_t transmitBufferLength; // length of the current transmit buffer
	uint16_t transmitBufferPosition; // position of the next character to transmit from the buffer

	void setClockDivisor()
	{
		uint32_t mck;
		uint16_t cd;

		mck = call ClockConfig.getMainClockSpeed(); // in kHz (e.g., 48,000)

		// set to 9,600 baud
		// baudrate = mck / (cd * 16)
		// cd = mck / (16 * baudrate)
		// here: cd = mck / 16 * 1000 / baudrate
		cd = (uint16_t) (((mck / 16) * 1000) / PLATFORM_BAUDRATE);

		//call HplSam3uUartConfig.setClockDivisor(312); // 9,600 baud with MCK = 48 MHz
		call HplSam3uUartConfig.setClockDivisor(cd);
	}

	command error_t Init.init()
	{
		// turn off all UART IRQs
		call HplSam3uUartInterrupts.disableAllUartIrqs();

		// configure NVIC
		call UartIrqControl.configure(IRQ_PRIO_UART);
		call UartIrqControl.enable();

		// configure PIO
		call UartPin1.disablePioControl();
		call UartPin1.selectPeripheralA();
		call UartPin2.disablePioControl();
		call UartPin2.selectPeripheralA();

		// configure mode and parity
		call HplSam3uUartConfig.setChannelModeAndParityType(UART_MR_CHMODE_NORMAL, UART_MR_PAR_NONE);

		// configure baud rate
		setClockDivisor();

		// initialize buffer pointers
		// important because this determines if UartStream is busy or not
		receiveBuffer = NULL;
		transmitBuffer = NULL;

		return SUCCESS;
	}

	async event void ClockConfig.mainClockChanged()
	{
		// adapt clock divisor to accommodate for PLATFORM_BAUDRATE
		setClockDivisor();
	}

	command error_t StdControl.start()
	{
		// enable peripheral clock
		call UartClockControl.enable();

		// enable receiver and transmitter
		call HplSam3uUartControl.enableReceiver();
		call HplSam3uUartControl.enableTransmitter();

		// enable receive IRQ
		call HplSam3uUartInterrupts.enableRxrdyIrq();

		return SUCCESS;
	}

	command error_t StdControl.stop()
	{
		// will finish any ongoing receptions and transmissions
		call HplSam3uUartControl.disableReceiver();
		call HplSam3uUartControl.disableTransmitter();

		// disable peripheral clock
		call UartClockControl.disable();

		return SUCCESS;
	}

	async command error_t UartStream.enableReceiveInterrupt()
	{
		call HplSam3uUartInterrupts.enableRxrdyIrq();
		return SUCCESS;
	}

	async command error_t UartStream.disableReceiveInterrupt()
	{
		call HplSam3uUartInterrupts.disableRxrdyIrq();
		return SUCCESS;
	}

	async command error_t UartStream.receive(uint8_t* buffer, uint16_t length)
	{
		if (length == 0) {
			return FAIL;
		}
		atomic {
			if (receiveBuffer != NULL) {
				return EBUSY; // in the middle of a reception
			} else {
				receiveBuffer = buffer;
				receiveBufferLength = length;
				receiveBufferPosition = 0;

				call HplSam3uUartInterrupts.enableRxrdyIrq();
			}
		}
		return SUCCESS;
	}

	async event void HplSam3uUartInterrupts.receivedByte(uint8_t data)
	{
		atomic {
			if (receiveBuffer != NULL) {
				// receive into buffer
				receiveBuffer[receiveBufferPosition] = data;
				receiveBufferPosition++;

				if (receiveBufferPosition >= receiveBufferLength) {
					// buffer is full
					uint8_t *bufferToSignal = receiveBuffer;
					atomic {
						receiveBuffer = NULL;
						call HplSam3uUartInterrupts.disableRxrdyIrq();
					}

					// signal reception of complete buffer
					signal UartStream.receiveDone(bufferToSignal, receiveBufferLength, SUCCESS);
				}
			} else {
				// signal single byte reception
				signal UartStream.receivedByte(data);
			}
		}
	}

	async command error_t UartStream.send(uint8_t *buffer, uint16_t length)
	{
		if (length == 0) {
			return FAIL;
		}
		atomic {
			if (transmitBuffer != NULL) {
				return EBUSY;
			} else {
				transmitBufferLength = length;
				transmitBuffer = buffer;
				transmitBufferPosition = 0;

				// enable ready-to-transmit IRQ
				call HplSam3uUartInterrupts.enableTxrdyIrq();

				return SUCCESS;
			}
		}
	}

	async event void HplSam3uUartInterrupts.transmitterReady()
	{
		atomic {
			if (transmitBufferPosition < transmitBufferLength) {
				// characters to transfer in the buffer
				call HplSam3uUartStatus.setCharToTransmit(transmitBuffer[transmitBufferPosition]);
				transmitBufferPosition++;
			} else {
				// all characters transmitted
				uint8_t *bufferToSignal = transmitBuffer;

				transmitBuffer = NULL;
				call HplSam3uUartInterrupts.disableTxrdyIrq();
				signal UartStream.sendDone(bufferToSignal, transmitBufferLength, SUCCESS);
			}
		}
	}

	async command error_t UartByte.send(uint8_t byte)
	{
		if (call HplSam3uUartInterrupts.isEnabledTxrdyIrq() == TRUE) {
			return FAIL; // in the middle of a stream transmission
		}

		// transmit synchronously
		call HplSam3uUartStatus.setCharToTransmit(byte);
		while (call HplSam3uUartStatus.isTransmitterReady() == FALSE);

		return SUCCESS;
	}

	async command error_t UartByte.receive(uint8_t *byte, uint8_t timeout)
	{
		// FIXME timeout currently ignored
		if (call HplSam3uUartInterrupts.isEnabledRxrdyIrq() == TRUE) {
			return FAIL; // in the middle of a stream reception
		}

		// receive synchronously
		while (call HplSam3uUartStatus.isReceiverReady() == FALSE);
		*byte = call HplSam3uUartStatus.getReceivedChar();

		return SUCCESS;
	}

	default async event void UartStream.sendDone(uint8_t *buffer, uint16_t length, error_t error) {}
	default async event void UartStream.receivedByte(uint8_t byte) {}
	default async event void UartStream.receiveDone(uint8_t *buffer, uint16_t length, error_t error) {}
}
