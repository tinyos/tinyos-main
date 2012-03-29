/*
 * Copyright (c) 2011, University of Szeged
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

module HplAtmegaExtInterruptSigP
{
	provides
	{
		interface HplAtmegaExtInterruptSig[uint8_t vector];
		interface McuPowerOverride;
	}

	uses interface McuPowerState;
}

implementation
{
	AVR_ATOMIC_HANDLER( INT0_vect )	{
		signal HplAtmegaExtInterruptSig.fired[0]();
	}

	AVR_ATOMIC_HANDLER( INT1_vect )	{
		signal HplAtmegaExtInterruptSig.fired[1]();
	}

	AVR_ATOMIC_HANDLER( INT2_vect )	{
		signal HplAtmegaExtInterruptSig.fired[2]();
	}

	AVR_ATOMIC_HANDLER( INT3_vect )	{
		signal HplAtmegaExtInterruptSig.fired[3]();
	}

	AVR_ATOMIC_HANDLER( INT4_vect )	{
		signal HplAtmegaExtInterruptSig.fired[4]();
	}

	AVR_ATOMIC_HANDLER( INT5_vect )	{
		signal HplAtmegaExtInterruptSig.fired[5]();
	}

	AVR_ATOMIC_HANDLER( INT6_vect )	{
		signal HplAtmegaExtInterruptSig.fired[6]();
	}

	AVR_ATOMIC_HANDLER( INT7_vect )	{
		signal HplAtmegaExtInterruptSig.fired[7]();
	}

	default async event void HplAtmegaExtInterruptSig.fired[uint8_t vector]() { }

	async command void HplAtmegaExtInterruptSig.update[uint8_t vector]()
	{
		if( vector >= 4 )
			call McuPowerState.update();
	}

	async command mcu_power_t McuPowerOverride.lowestState()
	{
		uint8_t eimsk = EIMSK;
		uint8_t eicrb = EICRB;

		if( (eimsk & (1<<INT4)) == 0 )
			eicrb &= ~(3<<ISC40);
		if( (eimsk & (1<<INT5)) == 0 )
			eicrb &= ~(3<<ISC50);
		if( (eimsk & (1<<INT6)) == 0 )
			eicrb &= ~(3<<ISC60);
		if( (eimsk & (1<<INT7)) == 0 )
			eicrb &= ~(3<<ISC70);

		return eicrb == 0 ? ATM128_POWER_DOWN : ATM128_POWER_IDLE;
	}
}
