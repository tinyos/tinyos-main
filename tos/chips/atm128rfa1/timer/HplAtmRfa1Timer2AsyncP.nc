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

#include "HplAtmRfa1Timer.h"

module HplAtmRfa1Timer2AsyncP @safe()
{
	provides
	{
		interface AtmegaCounter<uint8_t> as Counter;
		interface AtmegaCompare<uint8_t> as CompareA;
//		interface AtmegaCompare<uint8_t> as CompareB;
		interface McuPowerOverride;
	}

	uses
	{
		interface McuPowerState;
	}
}

implementation
{
/*
	Updating certain registers takes 1-2 clock ticks at 32768 KHz (regardless of
	the prescaler) if the timer is running asynchronously, so we have to monitor 
	when these updates are propagated. We always check ASSR before updating these 
	registers, and we do not wait for completion after the change to make good use 
	of the processor time. However, we force the mcu power state calculation and 
	before entering power down mode we wait for the completion of these register 
	updates.
*/
// ----- TIMER: timer counter register (TCNT)

	async command uint8_t Counter.get()
	{
		// TODO: make sure we wait at least one 1/32768 clock tick after wakeup
		return TCNT2;
	}

	async command void Counter.set(uint8_t value)
	{
		atomic
		{
			while( ASSR & (1 << TCN2UB) )
				;

			TCNT2 = value;
		}

		call McuPowerState.update();
	}

// ----- TIMER: timer interrupt flag register (TIFR), timer overflow flag (TOV)

	default async event void Counter.overflow() { }

	AVR_ATOMIC_HANDLER(TIMER2_OVF_vect)
	{
		// to keep the MCU from going to sleep too early
		TCCR2A = TCCR2A;
		call McuPowerState.update();

		signal Counter.overflow();
	}

	async command bool Counter.test() { return TIFR2 & (1 << TOV2); }

	async command void Counter.reset() { TIFR2 = 1 << TOV2; }

// ----- TIMER: timer interrupt mask register (TIMSK), timer overflow interrupt enable (TOIE)

	async command void Counter.start()
	{
		SET_BIT(TIMSK2, TOIE2);
		call McuPowerState.update();
	}

	async command void Counter.stop()
	{
		CLR_BIT(TIMSK2, TOIE2);
		call McuPowerState.update();
	}

	async command bool Counter.isOn() { return TIMSK2 & (1 << TOIE2); }

// ----- TIMER: timer control register (TCCR), clock select (CS) and waveform generation mode (WGM) bits

	async command void Counter.setMode(uint8_t mode)
	{
		atomic
		{
			ASSR = (ASSR & ~(0x3 << AS2))
				| ((mode >> 6) & 0x3) << AS2;

			while( ASSR & (1 << TCR2AUB | 1 << TCR2BUB) )
				;

			TCCR2A = (TCCR2A & ~(0x3 << WGM20))
				| ((mode >> 3) & 0x3) << WGM20;

			TCCR2B = (TCCR2B & ~(0x1 << WGM22 | 0x7 << CS20))
				| ((mode >> 5) & 0x1) << WGM22
				| ((mode >> 0) & 0x7) << CS20;
		}

		call McuPowerState.update();
	}

	async command uint8_t Counter.getMode()
	{
		uint8_t a, b, c;

		atomic
		{
			a = ASSR;
			b = TCCR2A;
			c = TCCR2B;
		}

		return ((a >> AS2) & 0x3) << 6
			| ((b >> WGM20) & 0x3) << 3
			| ((c >> WGM22) & 0x1) << 5
			| ((c >> CS20) & 0x7) << 0;
	}

// ----- COMPARE A: output compare register (OCR)

	async command uint8_t CompareA.get() { return OCR2A; }

	async command void CompareA.set(uint8_t value)
	{
		atomic
		{
			while( ASSR & (1 << OCR2AUB) )
				;

			OCR2A = value;
		}

		call McuPowerState.update();
	}

// ----- COMPARE A: timer interrupt flag register (TIFR), output comare match flag (OCF)

	default async event void CompareA.fired() { }

	AVR_ATOMIC_HANDLER(TIMER2_COMPA_vect)
	{ 
		// to keep the MCU from going to sleep too early
		TCCR2A = TCCR2A;
		call McuPowerState.update();

		signal CompareA.fired();
	}

	async command bool CompareA.test() { return TIFR2 & (1 << OCF2A); }

	async command void CompareA.reset() { TIFR2 = 1 << OCF2A; }

// ----- COMPARE A: timer interrupt mask register (TIMSK), output compare interrupt enable (OCIE)

	async command void CompareA.start()
	{
		SET_BIT(TIMSK2, OCIE2A);
		call McuPowerState.update();
	}

	async command void CompareA.stop()
	{
		CLR_BIT(TIMSK2, OCIE2A);
		call McuPowerState.update();
	}

	async command bool CompareA.isOn() { return TIMSK2 & (1 << OCIE2A); }

// ----- COMPARE A: timer control register (TCCR), compare output mode (COM)

	async command void CompareA.setMode(uint8_t mode)
	{
		atomic
		{
			while( ASSR & (1 << TCR2AUB) )
				;

			TCCR2A = (TCCR2A & ~(0x3 << COM2A0))
				| (mode & 0x3) << COM2A0;
		}

		call McuPowerState.update();
	}

	async command uint8_t CompareA.getMode()
	{
		return (TCCR2A >> COM2A0) & 0x3;
	}

// ----- COMPARE A: timer control register (TCCR), force output compare (FOC)

	async command void CompareA.force()
	{
		atomic
		{
			while( ASSR & (1 << TCR2BUB) )
				;

			SET_BIT(TCCR2B, FOC2A);
		}

		call McuPowerState.update();
	}

// ----- MCUPOWER

	async command mcu_power_t McuPowerOverride.lowestState()
	{
		// wait for all changes to propagate
		while( ASSR & (1 << TCN2UB | 1 << OCR2AUB | 1 << OCR2BUB | 1 << TCR2AUB | 1 << TCR2BUB) )
			;

		// if we need to wake up by this clock
		if( TIMSK2 & (1 << TOIE2 | 1 << OCIE2A | 1 << OCIE2B) )
			return ATM128_POWER_SAVE;
		else
			return ATM128_POWER_DOWN;
	}
}
