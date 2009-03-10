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
#include <RadioAssert.h>

module RadioAlarmP
{
	provides
	{
		interface RadioAlarm[uint8_t id];
	}

	uses
	{
		interface Alarm<TRadio, uint16_t>;
		interface Tasklet;
	}
}

implementation
{
	norace uint8_t state;
	enum
	{
		STATE_READY = 0,
		STATE_WAIT = 1,
		STATE_FIRED = 2,
	};

	tasklet_norace uint8_t alarm;

	async event void Alarm.fired()
	{
		atomic
		{
			if( state == STATE_WAIT )
				state = STATE_FIRED;
		}

		call Tasklet.schedule();
	}

	inline async command uint16_t RadioAlarm.getNow[uint8_t id]()
	{
		return call Alarm.getNow();
	}

	tasklet_async event void Tasklet.run()
	{
		if( state == STATE_FIRED )
		{
			state = STATE_READY;
			signal RadioAlarm.fired[alarm]();
		}
	}

	default tasklet_async event void RadioAlarm.fired[uint8_t id]()
	{
	}

	inline tasklet_async command bool RadioAlarm.isFree[uint8_t id]()
	{
		return state == STATE_READY;
	}

	tasklet_async command void RadioAlarm.wait[uint8_t id](uint16_t timeout)
	{
		ASSERT( state == STATE_READY );

		alarm = id;
		state = STATE_WAIT;
		call Alarm.start(timeout);
	}

	tasklet_async command void RadioAlarm.cancel[uint8_t id]()
	{
		ASSERT( alarm == id );
		ASSERT( state != STATE_READY );

		call Alarm.stop();
		state = STATE_READY;
	}
}
