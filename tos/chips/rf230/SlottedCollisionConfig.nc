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

	/**
	 * This event should be called periodically to indicate the passing of
	 * time (maybe we should use a timer)
	 */
	tasklet_async event void timerTick();
}
