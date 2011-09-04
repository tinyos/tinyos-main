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

interface HighBits<to_size_t, from_size_t>
{
	async command to_size_t getXXX(from_size_t low, int8_t increment);

	/**
	 * Returns the stored high bits.
	 */
	async command to_size_t get();

	/**
	 * Increments the stored high bits, and returns TRUE
	 * if the high bits become 0.
	 */
	async command bool add(int8_t high);

	/**
	 * Returns TRUE if the high bits plus the increment is zero
	 */
	async command bool equals(int8_t high);

	/**
	 * Takes the low bits from the parameter and returns it
	 */
	async command to_size_t convertLow(from_size_t low);

	/**
	 * Takes the parameter and interprets it as high bits.
	 */
	async command to_size_t convertHigh(int8_t high);

	/**
	 * Takes the high bits from the parameter and stores it in
	 * memory, then it returns the low bits. You should not
	 * use this method to increment the high bits.
	 */
	async command from_size_t set(to_size_t value);
}
