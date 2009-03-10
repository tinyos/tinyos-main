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
