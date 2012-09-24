/*
 * Copyright (c) 2010, University of Szeged
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Author: Miklos Maroti
 */

generic module AtmegaRtcCounterP(typedef precision, uint8_t mode)
{
	provides
	{
		interface Init @exactlyonce();
		interface Counter<precision, uint16_t>;

		// for the alarm
		async command uint8_t getCounterHigh();
	}

	uses
	{
		interface HplAtmegaCounter<uint8_t>;
	}
}

implementation
{
	command error_t Init.init()
	{
		call HplAtmegaCounter.setMode(mode);
		call HplAtmegaCounter.start();

		return SUCCESS;
	}

	volatile uint8_t high;

	/*
	 * Without prescaler the interrupt occurs when the Timer goes from 0 to 1,
	 * so we can have two posible sequences of events
	 *
	 *	TST=0, CNT=0, TST=1, CNT=1, TST=1 ... TST=1, CNT=1, TST=0
	 *	TST=0, CNT=0, TST=0, CNT=1, TST=1 ... TST=1, CNT=1, TST=0
	 *
	 * With the prescaler enabled the interrupt occurs while the Timer is 0
	 * (one 32768 HZ tick after the Timer became 0), so we have one possibility:
	 *
	 *	TST=0, CNT=0, TST=1, CNT=0, TST=1 ... TST=1, CNT=0, TST=0
	 */

	async command uint16_t Counter.get()
	{
		uint8_t a, b;
		bool c;

		atomic
		{
			b = call HplAtmegaCounter.get();
			c = call HplAtmegaCounter.test();
			a = high;
		}

		if( c && b != 0 )
			a += 1;

		// overflow occurs when switching from 0 to 1.
		b -= 1;

		return (((uint16_t)a) << 8) + b;
	}

	async command bool Counter.isOverflowPending()
	{
		atomic return high == 0xFF && call HplAtmegaCounter.test();
	}

	async command void Counter.clearOverflow()
	{
		call HplAtmegaCounter.reset();
	}

	default async event void Counter.overflow() { }

	// called in atomic context
	async event void HplAtmegaCounter.overflow()
	{
		++high;

		if( high == 0 )
			signal Counter.overflow();
	}

	// used by the alarm
	async command uint8_t getCounterHigh()
	{
		uint8_t h = high;
		if( call HplAtmegaCounter.test() )
			h += 1;

		return h;
	}
}
