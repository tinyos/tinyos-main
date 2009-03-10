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

#include <Tasklet.h>

interface RadioState
{
	/**
	 * Moves to radio into sleep state with the lowest power consumption but 
	 * highest wakeup time. The radio cannot send or receive in this state 
	 * and releases all access to shared resources (e.g. SPI bus). 
	 */
	tasklet_async command error_t turnOff();

	/**
	 * The same as the turnOff command, except it is not as deep sleep, and
	 * it is quicker to recover from this state.
	 */
	tasklet_async command error_t standby();

	/**
	 * Goes into receive state. The radio continuously receive messages 
	 * and able to transmit.
	 */
	tasklet_async command error_t turnOn();

	/**
	 * Sets the current channel. Returns EBUSY if the stack is unable
	 * to change the channel this time (some other operation is in progress)
	 * SUCCESS otherwise.
	 */
	tasklet_async command error_t setChannel(uint8_t channel);

	/**
	 * This event is signaled exactly once for each sucessfully posted state 
	 * transition and setChannel command when it is completed.
	 */
	tasklet_async event void done();

	/**
	 * Returns the currently selected channel.
	 */
	tasklet_async command uint8_t getChannel();
}
