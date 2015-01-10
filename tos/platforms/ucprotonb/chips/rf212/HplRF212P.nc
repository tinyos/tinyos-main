/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 */

#include "atm128hardware.h"

module HplRF212P
{
	provides
	{
		interface GpioCapture as IRQ;
	}

	uses
	{
		interface GpioInterrupt as Interrupt;
		interface LocalTime<TRadio>;
	}
}

implementation
{
	
	async event void Interrupt.fired() {
		uint16_t time = call LocalTime.get();
		signal IRQ.captured(time);
	}
	
	async command error_t IRQ.captureRisingEdge()
	{
		return call Interrupt.enableRisingEdge();
	}

	async command error_t IRQ.captureFallingEdge()
	{
		return call Interrupt.enableFallingEdge();
	}

	async command void IRQ.disable()
	{
		call Interrupt.disable();
	}
	
	default async event void IRQ.captured(uint16_t time){}
}
