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

interface AtmegaCounter<size_type>
{
// ----- timer counter register (TCNT) 

	/* Returns the current counter value */
	async command size_type get();

	/* Sets the current counter value */
	async command void set(size_type value);

// ----- timer interrupt flag register (TIFR), timer overflow flag (TOV)

	/* Signalled when the counter is going from 0xFF to 0x00.
	   WARNING: This event MUST be executed in atomic context */
	async event void overflow();

	/* Tests if there is a pending overflow interrupt
	   WARNING: This command MUST be executed in atomic context */
	async command bool test();

	/* Resets a pending interrupt */
	async command void reset();

// ----- timer interrupt mask register (TIMSK), timer overflow interrupt enable (TOIE)

	/* Enables the overflow interrupt */
	async command void start();

	/* Disables the overflow interrupt */
	async command void stop();

	/* Checks is the overflow interrupt is enabled */
	async command bool isOn();

// ----- timer control registers (TCCR), clock select bits (CS) and waveform generation mode (WGM)

	/* Sets the clock select and waveform generation mode bits */
	async command void setMode(uint8_t mode);

	/* Returns the clock select andwaveform generation mode bits */
	async command uint8_t getMode();
}
