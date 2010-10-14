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

interface SlottedCollisionConfig
{
	/**
	 * This command should return the approximate transmit delay between
	 * setting an alarm, waiting for the fire event, calling send and
	 * obtaining the timestamp for the transmitted message.
	 */
	async command uint16_t getInitialDelay();

	/**
	 * Must return a binary exponent so that the collision avoidance layer
	 * can assign slots in the range of [0, 1 << exponent) of size collision
	 * window.
	 */
	async command uint8_t getScheduleExponent();

	/**
	 * This command must return the time when the message was transmitted.
	 */
	async command uint16_t getTransmitTime(message_t* msg);

	/**
	 * Returns the start of the collision window for this received message,
	 * so transmit times in this range would be considered possible collisions.
	 */
	async command uint16_t getCollisionWindowStart(message_t* msg);

	/**
	 * Returns the size of the collision window for this received message.
	 */
	async command uint16_t getCollisionWindowLength(message_t* msg);
}
