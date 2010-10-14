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

module RandomCollisionLayerP
{
	provides
	{
		interface RadioSend;
		interface RadioReceive;
	}
	uses
	{
		interface RadioSend as SubSend;
		interface RadioReceive as SubReceive;
		interface RadioAlarm;
		interface Random;
		interface RandomCollisionConfig as Config;
	}
}

implementation
{
	tasklet_norace uint8_t state;
	enum
	{
		STATE_READY = 0,
		STATE_TX_PENDING_FIRST = 1,
		STATE_TX_PENDING_SECOND = 2,
		STATE_TX_SENDING = 3,

		STATE_BARRIER = 0x80,
	};

	tasklet_norace message_t *txMsg;
	tasklet_norace uint16_t txBarrier;

	tasklet_async event void SubSend.ready()
	{
		if( state == STATE_READY && call RadioAlarm.isFree() )
			signal RadioSend.ready();
	}

	uint16_t nextRandom;
	task void calcNextRandom()
	{
		uint16_t a = call Random.rand16();
		atomic nextRandom = a;
	}

	uint16_t getBackoff(uint16_t maxBackoff)
	{
		uint16_t a;

		atomic
		{
			a = nextRandom;
			nextRandom += 273;
		}
		post calcNextRandom();

		return (a % maxBackoff) + call Config.getMinimumBackoff();
	}

	tasklet_async command error_t RadioSend.send(message_t* msg)
	{
		if( state != STATE_READY || ! call RadioAlarm.isFree() )
			return EBUSY;

		txMsg = msg;
		state = STATE_TX_PENDING_FIRST;
		call RadioAlarm.wait(getBackoff(call Config.getInitialBackoff(msg)));

		return SUCCESS;
	}

	tasklet_async event void RadioAlarm.fired()
	{
		error_t error;
		int16_t delay;

		ASSERT( state != STATE_READY );

		delay = (int16_t)txBarrier - call RadioAlarm.getNow();

		if( state == STATE_BARRIER )
		{
			state = STATE_READY;

			signal RadioSend.ready();
			return;
		}
		else if( (state & STATE_BARRIER) && delay > 0 )
			error = EBUSY;
		else
			error = call SubSend.send(txMsg);

		if( error != SUCCESS )
		{
			if( (state & ~STATE_BARRIER) == STATE_TX_PENDING_FIRST )
			{
				state = (state & STATE_BARRIER) | STATE_TX_PENDING_SECOND;
				call RadioAlarm.wait(getBackoff(call Config.getCongestionBackoff(txMsg)));
			}
			else
			{
				if( (state & STATE_BARRIER) && delay > 0 )
				{
					state = STATE_BARRIER;
					call RadioAlarm.wait(delay);
				}
				else
					state = STATE_READY;

				signal RadioSend.sendDone(error);
			}
		}
		else
			state = STATE_TX_SENDING;
	}

	tasklet_async event void SubSend.sendDone(error_t error)
	{
		ASSERT( state == STATE_TX_SENDING );

		state = STATE_READY;
		signal RadioSend.sendDone(error);
	}

	tasklet_async event bool SubReceive.header(message_t* msg)
	{
		return signal RadioReceive.header(msg);
	}

	tasklet_async event message_t* SubReceive.receive(message_t* msg)
	{
		int16_t delay;

		txBarrier = call Config.getTransmitBarrier(msg);
		delay = txBarrier - call RadioAlarm.getNow();

		if( delay > 0 )
		{
			if( state == STATE_READY )
			{
				call RadioAlarm.wait(delay);
				state = STATE_BARRIER;
			}
			else
				state |= STATE_BARRIER;
		}

		return signal RadioReceive.receive(msg);
	}
}
