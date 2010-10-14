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
