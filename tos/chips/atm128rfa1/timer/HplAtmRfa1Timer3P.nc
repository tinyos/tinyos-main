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

module HplAtmRfa1Timer3P @safe()
{
	provides
	{
		interface AtmegaCounter<uint16_t> as Timer;
		interface AtmegaCompare<uint16_t> as CompareA;
		interface AtmegaCompare<uint16_t> as CompareB;
		interface AtmegaCompare<uint16_t> as CompareC;
		interface AtmegaCapture<uint16_t> as Capture;
		interface McuPowerOverride;
	}

	uses
	{
		interface McuPowerState;
	}
}

implementation
{
// ----- TIMER: timer counter register (TCNT)

	async command uint16_t Timer.get()
	{
		atomic return TCNT3;
	}

	async command void Timer.set(uint16_t value)
	{
		atomic TCNT3 = value;
	}

// ----- TIMER: timer interrupt flag register (TIFR), timer overflow flag (TOV)

	default async event void Timer.overflow() { }

	AVR_ATOMIC_HANDLER(TIMER3_OVF_vect) { signal Timer.overflow(); }

	async command bool Timer.test() { return TIFR3 & (1 << TOV3); }

	async command void Timer.reset() { TIFR3 = 1 << TOV3; }

// ----- TIMER: timer interrupt mask register (TIMSK), timer overflow interrupt enable (TOIE)

	async command void Timer.start()
	{
		SET_BIT(TIMSK3, TOIE3);
	}

	async command void Timer.stop()
	{
		CLR_BIT(TIMSK3, TOIE3);
	}

	async command bool Timer.isOn() { return TIMSK3 & (1 << TOIE3); }

// ----- TIMER: timer control register (TCCR), clock select (CS) and waveform generation mode (WGM) bits

	async command void Timer.setMode(uint8_t mode)
	{
		atomic
		{
			TCCR3A = (TCCR3A & ~(0x3 << WGM30))
				| ((mode >> 3) & 0x3) << WGM30;

			TCCR3B = (TCCR3B & ~(0x3 << WGM32 | 0x7 << CS30))
				| ((mode >> 5) & 0x3) << WGM32
				| ((mode >> 0) & 0x7) << CS30;
		}
	}

	async command uint8_t Timer.getMode()
	{
		uint8_t a, b;

		atomic
		{
			a = TCCR3A;
			b = TCCR3B;
		}

		return ((a >> WGM30) & 0x3) << 3
			| ((b >> WGM32) & 0x3) << 5
			| ((b >> CS30) & 0x7) << 0;
	}


// ----- COMPARE A: output compare register (OCR)

	async command uint16_t CompareA.get()
	{
		atomic return OCR3A;
	}

	async command void CompareA.set(uint16_t value)
	{
		atomic OCR3A = value;
	}
	
// ----- COMPARE B: output compare register (OCR)

	async command uint16_t CompareB.get()
	{
		atomic return OCR3B;
	}

	async command void CompareB.set(uint16_t value)
	{
		atomic OCR3B = value;
	}
	
// ----- COMPARE C: output compare register (OCR)

	async command uint16_t CompareC.get()
	{
		atomic return OCR3C;
	}

	async command void CompareC.set(uint16_t value)
	{
		atomic OCR3C = value;
	}

// ----- COMPARE A: timer interrupt flag register (TIFR), output comare match flag (OCF)

	default async event void CompareA.fired() { }

	AVR_ATOMIC_HANDLER(TIMER3_COMPA_vect) { signal CompareA.fired(); }

	async command bool CompareA.test() { return TIFR3 & (1 << OCF3A); }

	async command void CompareA.reset() { TIFR3 = 1 << OCF3A; }

// ----- COMPARE B: timer interrupt flag register (TIFR), output comare match flag (OCF)

	default async event void CompareB.fired() { }

	AVR_ATOMIC_HANDLER(TIMER3_COMPB_vect) { signal CompareB.fired(); }

	async command bool CompareB.test() { return TIFR3 & (1 << OCF3B); }

	async command void CompareB.reset() { TIFR3 = 1 << OCF3B; }
	
// ----- COMPARE C: timer interrupt flag register (TIFR), output comare match flag (OCF)

	default async event void CompareC.fired() { }

	AVR_ATOMIC_HANDLER(TIMER3_COMPC_vect) { signal CompareC.fired(); }

	async command bool CompareC.test() { return TIFR3 & (1 << OCF3C); }

	async command void CompareC.reset() { TIFR3 = 1 << OCF3C; }
	

// ----- COMPARE A: timer interrupt mask register (TIMSK), output compare interrupt enable (OCIE)

	async command void CompareA.start()
	{
		SET_BIT(TIMSK3, OCIE3A);
		call McuPowerState.update();
	}

	async command void CompareA.stop()
	{
		CLR_BIT(TIMSK3, OCIE3A);
		call McuPowerState.update();
	}

	async command bool CompareA.isOn() { return TIMSK3 & (1 << OCIE3A); }
	
// ----- COMPARE B: timer interrupt mask register (TIMSK), output compare interrupt enable (OCIE)

	async command void CompareB.start()
	{
		SET_BIT(TIMSK3, OCIE3B);
		call McuPowerState.update();
	}

	async command void CompareB.stop()
	{
		CLR_BIT(TIMSK3, OCIE3B);
		call McuPowerState.update();
	}

	async command bool CompareB.isOn() { return TIMSK3 & (1 << OCIE3B); }
	
// ----- COMPARE C: timer interrupt mask register (TIMSK), output compare interrupt enable (OCIE)

	async command void CompareC.start()
	{
		SET_BIT(TIMSK3, OCIE3C);
		call McuPowerState.update();
	}

	async command void CompareC.stop()
	{
		CLR_BIT(TIMSK3, OCIE3C);
		call McuPowerState.update();
	}

	async command bool CompareC.isOn() { return TIMSK3 & (1 << OCIE3C); }

// ----- COMPARE A: timer control register (TCCR), compare output mode (COM)

	async command void CompareA.setMode(uint8_t mode)
	{
		atomic
		{
			TCCR3A = (TCCR3A & ~(0x3 << COM3A0))
				| (mode & 0x3) << COM3A0;
		}
	}

	async command uint8_t CompareA.getMode()
	{
		return (TCCR3A >> COM3A0) & 0x3;
	}
	
// ----- COMPARE B: timer control register (TCCR), compare output mode (COM)

	async command void CompareB.setMode(uint8_t mode)
	{
		atomic
		{
			TCCR3B = (TCCR3B & ~(0x3 << COM3B0))
				| (mode & 0x3) << COM3B0;
		}
	}

	async command uint8_t CompareB.getMode()
	{
		return (TCCR3B >> COM3B0) & 0x3;
	}
	
// ----- COMPARE C: timer control register (TCCR), compare output mode (COM)

	async command void CompareC.setMode(uint8_t mode)
	{
		atomic
		{
			TCCR3C = (TCCR3C & ~(0x3 << COM3C0))
				| (mode & 0x3) << COM3C0;
		}
	}

	async command uint8_t CompareC.getMode()
	{
		return (TCCR3C >> COM3C0) & 0x3;
	}

// ----- COMPARE A: timer control register (TCCR), force output compare (FOC)

	async command void CompareA.force()
	{
		SET_BIT(TCCR3C, FOC3A);
	}

// ----- COMPARE B: timer control register (TCCR), force output compare (FOC)

	async command void CompareB.force()
	{
		SET_BIT(TCCR3C, FOC3B);
	}
	
// ----- COMPARE C: timer control register (TCCR), force output compare (FOC)

	async command void CompareC.force()
	{
		SET_BIT(TCCR3C, FOC3C);
	}
	
// ----- CAPTURE: input capture register (ICR)

	async command uint16_t Capture.get()
	{
		atomic return ICR3;
	}

	async command void Capture.set(uint16_t value)
	{
		atomic ICR3 = value;
	}

// ----- CAPTURE: timer interrupt flag register (TIFR), input capture flag (ICF)

	default async event void Capture.fired() { }

	AVR_ATOMIC_HANDLER(TIMER3_CAPT_vect) { signal Capture.fired(); }

	async command bool Capture.test() { return TIFR3 & (1 << ICF3); }

	async command void Capture.reset() { TIFR3 = 1 << ICF3; }

// ----- CAPTURE: timer interrupt mask register (TIMSK), input capture interrupt enable (ICIE)

	async command void Capture.start()
	{
		SET_BIT(TIMSK3, ICIE3);
		call McuPowerState.update();
	}

	async command void Capture.stop()
	{
		CLR_BIT(TIMSK3, ICIE3);
		call McuPowerState.update();
	}

	async command bool Capture.isOn() { return TIMSK3 & (1 << ICIE3); }

// ----- CAPTURE: timer control register (TCCR), input capture mode (COM)

	async command void Capture.setMode(uint8_t mode)
	{
		atomic
		{
			TCCR3B = (TCCR3B & ~(0x3 << ICES3))
				| (mode & 0x3) << ICES3;
		}
	}

	async command uint8_t Capture.getMode()
	{
		return (TCCR3B >> ICES3) & 0x3;
	}

// ----- MCUPOWER

	async command mcu_power_t McuPowerOverride.lowestState()
	{
		// if we need to wake up by this clock
		if( TIMSK3 & (1 << OCIE3A | 1 << OCIE3B | 1 << OCIE3C | 1 << ICIE3) )
			return ATM128_POWER_IDLE;
		else
			return ATM128_POWER_DOWN;
	}
}
