/*
 * Copyright (c) 2005 Stanford University. All rights reserved.
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
 * - Neither the name of the copyright holders nor the names of
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
 */

/*
 * Copyright (c) 2007, Vanderbilt University
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
 * - Neither the name of the copyright holders nor the names of
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
 */

/**
 * Implementation of TEP 112 (Microcontroller Power Management) for
 * the Atmega128. Power state calculation code copied from Rob
 * Szewczyk's 1.x code in HPLPowerManagementM.nc.
 *
 * <pre>
 *  $Id: McuSleepC.nc,v 1.6 2010-06-29 22:07:43 scipio Exp $
 * </pre>
 *
 * @author Philip Levis
 * @author Robert Szewczyk
 * @author Janos Sallai <janos.sallai@vanderbilt.edu>
 * @date   October 30, 2007
 */

module McuSleepC @safe() {
	provides {
		interface McuSleep;
		interface McuPowerState;
	}
	uses {
		interface McuPowerOverride;
	}
}

implementation {
	/* There is no dirty bit management because the sleep mode depends on
	   the amount of time remaining in timer2. */
 
	/* Note that the power values are maintained in an order
	 * based on their active components, NOT on their values.
	 * Look at atm1281hardware.h and page 54 of the ATmeg1281
	 * manual (Table 25).*/
	const_uint8_t atm128PowerBits[ATM128_POWER_DOWN + 1] = {
		0,
		(1 << SM0),
		(1 << SM2) | (1 << SM1) | (1 << SM0),
		(1 << SM1) | (1 << SM0),
		(1 << SM2) | (1 << SM1),
		(1 << SM1)
	};

	mcu_power_t getPowerState() {
		// Note: we go to sleep even if timer 0, 1, 3, 4,  or 5's overflow
		// interrupt is enabled - this allows using timers 0, 1 and 3 as TinyOS
		// "Alarm"s while still having power management. (see TEP102 Appendix C)
		// Input capture and output compare for timer 4 and 5 are not functional
		// on the atm1281.

		// Are there any input capture or output compare interrupts enabled
		// for timers 0, 1 or 3?
		if (
			TIMSK0 & (1 << OCIE0A | 1 << OCIE0B ) ||
			TIMSK1 & (1 << ICIE1  | 1 << OCIE1A | 1 << OCIE1B | 1 << OCIE1C) ||
			TIMSK3 & (1 << ICIE3  | 1 << OCIE3A | 1 << OCIE3B | 1 << OCIE3C)) {

			return ATM128_POWER_IDLE;
		}

		// SPI (Radio stack)
		if (bit_is_set(SPCR, SPIE)) {
			return ATM128_POWER_IDLE;
		}

		// UARTs are active
		if (UCSR0B & (1 << TXEN0 | 1 << RXEN0)) { // UART
			return ATM128_POWER_IDLE;
		}
		if (UCSR1B & (1 << TXEN1 | 1 << RXEN1)) { // UART
			return ATM128_POWER_IDLE;
		}

		// I2C (Two-wire) is active
		if (bit_is_set(TWCR, TWEN)) {
			return ATM128_POWER_IDLE;
		}

		// ADC is enabled
		if (bit_is_set(ADCSRA, ADEN)) {
			return ATM128_POWER_ADC_NR;
		}

		return ATM128_POWER_DOWN;
	}

	async command void McuSleep.sleep() {
		uint8_t powerState;

		powerState = mcombine(getPowerState(), call McuPowerOverride.lowestState());
		SMCR = (SMCR & 0xf0) | 1 << SE | read_uint8_t(&atm128PowerBits[powerState]);
		sei();
		// All of memory may change at this point...
		asm volatile ("sleep" : : : "memory");
		cli();

		CLR_BIT(SMCR, SE);
	}

        async command void McuSleep.irq_preamble()  { }
        async command void McuSleep.irq_postamble() { }
	async command void McuPowerState.update()   { }

	default async command mcu_power_t McuPowerOverride.lowestState() {
		return ATM128_POWER_DOWN;
	}
}

