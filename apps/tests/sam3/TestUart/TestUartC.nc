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
 * Basic application that tests the SAM3U UART.
 *
 * @author Wanja Hofer <wanja@cs.fau.de>
 **/

module TestUartC
{
	uses interface Leds;
	uses interface Boot;
	uses interface HplNVICInterruptCntl as UartIrqControl;
	uses interface StdControl as UartControl;
	uses interface UartByte;
	uses interface UartStream;
}
implementation
{
	uint8_t buffer[10];

	task void sendTask();
	task void receiveTask();

	event void Boot.booted()
	{
		call UartIrqControl.configure(0xff);
		call UartIrqControl.enable();
		call UartControl.start();

//		__nesc_enable_interrupt();

		post receiveTask();
	}

	task void receiveTask()
	{
		call UartStream.receive(buffer, 10);
	}

	async event void UartStream.receiveDone(uint8_t* buf, uint16_t len, error_t error)
	{
		call Leds.led0Toggle(); // Led 0 (green) = received something
		post sendTask();
	}

	task void sendTask()
	{
		// send out received buffer
		call UartStream.send(buffer, 10);
	}

	async event void UartStream.sendDone(uint8_t* buf, uint16_t len, error_t error)
	{
		call Leds.led1Toggle(); // Led 1 (green) = sent something
		post receiveTask();
	}

	async event void UartStream.receivedByte(uint8_t byte)
	{
		call Leds.led2Toggle(); // Led 2 (red) = received something w/o a buffer
	}
}
