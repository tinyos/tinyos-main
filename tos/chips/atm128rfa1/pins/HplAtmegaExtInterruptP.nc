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

generic module HplAtmegaExtInterruptP(
	uint8_t EIFR_ADDR, uint8_t EIFR_PIN,
	uint8_t EIMSK_ADDR, uint8_t EIMSK_PIN,
	uint8_t EICR_ADDR, uint8_t EICR_PIN)
{
	provides interface HplAtmegaExtInterrupt;
	uses interface HplAtmegaExtInterruptSig;
}

implementation
{
#define EIFR_REG (*(volatile uint8_t*)(EIFR_ADDR))
#define EIMSK_REG (*(volatile uint8_t*)(EIMSK_ADDR))
#define EICR_REG (*(volatile uint8_t*)(EICR_ADDR))

// ----- external interrupt flag register (EIFR)

	async event void HplAtmegaExtInterruptSig.fired() {
		signal HplAtmegaExtInterrupt.fired();
	}

	default async event void HplAtmegaExtInterrupt.fired() { }

	async command bool HplAtmegaExtInterrupt.test() {
		return (EIFR_REG & (1<<EIFR_PIN)) != 0;
	}

	async command void HplAtmegaExtInterrupt.reset() {
		EIFR_REG = 1<<EIFR_PIN;
	}

// ----- external interrupt mask register (EIMSK)

	async command void HplAtmegaExtInterrupt.enable() {
		EIMSK_REG |= 1<<EIMSK_PIN;
		call HplAtmegaExtInterruptSig.update();
	}

	async command void HplAtmegaExtInterrupt.disable() {
		EIMSK_REG &= ~(1<<EIMSK_PIN);
		call HplAtmegaExtInterruptSig.update();
	}

	async command bool HplAtmegaExtInterrupt.isEnabled() {
		return (EIMSK_REG & (1<<EIMSK_PIN)) != 0;
	}

// ----- external interrupt control register (EICR)

	inline async command void HplAtmegaExtInterrupt.setMode(uint8_t mode) {
		uint8_t a = EICR_REG & ~(3 << EICR_PIN);
		EICR_REG = a | ((mode & 3) << EICR_PIN);
	}

	async command uint8_t HplAtmegaExtInterrupt.getMode() {
		return (EICR_REG >> EICR_PIN) & 3;
	}
}
