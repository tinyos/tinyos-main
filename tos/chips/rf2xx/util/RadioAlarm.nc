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

interface RadioAlarm
{
	/**
	 * Returns TRUE if the alarm is free and ready to be used. Once the alarm
	 * is free, it cannot become nonfree in the same tasklet block. Note,
	 * if the alarm is currently set (even if for ourselves) then it is not free.
	 */
	tasklet_async command bool isFree();

	/**
	 * Waits till the specified timeout period expires. The alarm must be free.
	 */
	tasklet_async command void wait(uint16_t timeout);

	/**
	 * Cancels the running alarm. The alarm must be pending.
	 */
	tasklet_async command void cancel();

	/**
	 * This event is fired when the specified timeout period expires.
	 */
	tasklet_async event void fired();

	/**
	 * Returns the current time as measured by the radio stack.
	 */
	async command uint16_t getNow();
}
