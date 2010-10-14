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
