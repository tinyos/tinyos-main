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

module SlottedCollisionLayerP
{
	provides
	{
		interface RadioSend;
		interface RadioReceive;
		interface Init;
	}
	uses
	{
		interface RadioSend as SubSend;
		interface RadioReceive as SubReceive;
		interface RadioAlarm;
		interface Random;
		interface SlottedCollisionConfig as Config;
#ifdef RADIO_DEBUG
		interface DiagMsg;
#endif
	}
}

implementation
{
/* ----- random ----- */

	uint16_t nextRandom;

	task void calcNextRandom()
	{
		uint16_t a = call Random.rand16();
		atomic nextRandom = a;
	}

	uint16_t getNextRandom()
	{
		uint16_t a;

		atomic
		{
			a = nextRandom;
			nextRandom += 273;
		}
		post calcNextRandom();

		return a;
	}

/* ----- schedule selection ----- */

	void printStats();

	tasklet_async event bool SubReceive.header(message_t* msg)
	{
		return signal RadioReceive.header(msg);
	}

	// WARNING!!! Do not change these values, the error values can overflow
	enum
	{
		ERROR_DECAY = 3,
		ERROR_SWITCH = 30,		// should be a multiple of (1 << decay)
		ERROR_COLLISION = 20,	// must be less than (255 - switch) >> decay
		ERROR_BUSY = 1,			// must be less than collision
		ERROR_INITIAL = 80,		// must be less than giveup
		ERROR_GIVEUP = 120,		// must be less than collision * (1 << decay)
		ERROR_REPRESS = 40,		// must be more than switch
		ERROR_MAX = 255,
	};

	/**
	 * Returns TRUE if time is between start and start + window 
	 * modulo the schedule size of (1 << exponent)
	 */
	inline bool isBetween(uint8_t exponent, uint16_t time, uint16_t start, uint16_t length)
	{
		return (uint16_t)((time - start) & ((1 << exponent) - 1)) < length;
	}

	tasklet_norace uint16_t schedule1;
	tasklet_norace uint16_t schedule2;

	tasklet_norace uint8_t error1;
	tasklet_norace uint8_t error2;

	tasklet_async event message_t* SubReceive.receive(message_t* msg)
	{
		uint8_t exponent = call Config.getScheduleExponent();
		uint16_t start = call Config.getCollisionWindowStart(msg);
		uint16_t length = call Config.getCollisionWindowLength(msg);

		error1 -= (error1 + (1<<ERROR_DECAY) - 1) >> ERROR_DECAY;
		if( isBetween(exponent, schedule1, start, length) )
			error1 += ERROR_COLLISION; 

		error2 -= (error1 + (1<<ERROR_DECAY) - 1) >> ERROR_DECAY;
		if( isBetween(exponent, schedule2, start, length) )
			error2 += ERROR_COLLISION;

		if( error2 + ERROR_SWITCH <= error1 )
		{
			error1 = error2;
			schedule1 = schedule2;
			error2 = ERROR_GIVEUP;
		}

		if( error2 >= ERROR_GIVEUP )
		{
			error2 = ERROR_INITIAL;
			schedule2 = getNextRandom();
		}

		printStats();

		return signal RadioReceive.receive(msg);
	}

/* ------ transmit ------ */

	tasklet_norace uint8_t state;
	enum
	{
		STATE_READY = 0,
		STATE_PENDING = 1,
		STATE_SENDING = 2,
	};

	enum { DELAY_DECAY = 2 };

	tasklet_norace message_t *txMsg;
	tasklet_norace uint16_t txDelay;	// the averaged delay between schedule and timestamp
	tasklet_norace uint16_t txTime;		// the schedule time of transmission

	tasklet_async event void SubSend.ready()
	{
		if( state == STATE_READY && call RadioAlarm.isFree() )
			signal RadioSend.ready();
	}

	tasklet_async command error_t RadioSend.send(message_t* msg)
	{
		uint16_t backoff;
		uint16_t time;

		// TODO: we could supress transmission while error is large
		if( state != STATE_READY || ! call RadioAlarm.isFree() || error1 >= ERROR_REPRESS )
			return EBUSY;

		txMsg = msg;
		state = STATE_PENDING;

		time = call RadioAlarm.getNow();
		backoff = 1 + ((schedule1 - time - (txDelay >> DELAY_DECAY))
			& ((1 << call Config.getScheduleExponent()) - 1));

		backoff += getNextRandom() & (3 << call Config.getScheduleExponent());

		call RadioAlarm.wait(backoff);
		txTime = time + backoff;

		printStats();

		return SUCCESS;
	}

	tasklet_async event void RadioAlarm.fired()
	{
		error_t error;

		ASSERT( state == STATE_PENDING );

		error = call SubSend.send(txMsg);
		if( error == SUCCESS )
			state = STATE_SENDING;
		else
		{
			if( error2 + ERROR_SWITCH <= error1 )
			{
				error1 = error2;
				schedule1 = schedule2;
				error2 = ERROR_INITIAL;
				schedule2 = getNextRandom();
			}
			else if( error1 < ERROR_MAX - ERROR_BUSY )
				error1 = error1 + ERROR_BUSY;

			state = STATE_READY;
			signal RadioSend.sendDone(error);
		}
	}

	tasklet_async event void SubSend.sendDone(error_t error)
	{
		ASSERT( state == STATE_SENDING );

		if( error == SUCCESS )
		{
			txDelay += (call Config.getTransmitTime(txMsg) - txTime) - (txDelay >> DELAY_DECAY);

			ASSERT( (txDelay >> DELAY_DECAY) < (1 << call Config.getScheduleExponent()) );
		}

		state = STATE_READY;
		signal RadioSend.sendDone(error);
	}

/* ------ init  ------ */

	command error_t Init.init()
	{
		// do not use Random here because it might not be initialized
		schedule1 = (uint16_t)(TOS_NODE_ID * 1973);
		schedule2 = schedule1 + 0117;
		txDelay = call Config.getInitialDelay() << DELAY_DECAY;

		return SUCCESS;
	}

#ifdef RADIO_DEBUG
	tasklet_norace uint8_t count;
	void printStats()
	{
		if( ++count > 50 && call DiagMsg.record() )
		{
			count = 0;

			call DiagMsg.str("slotted");
			call DiagMsg.uint16(txDelay >> DELAY_DECAY);
			call DiagMsg.uint16(schedule1);
			call DiagMsg.uint8(error1);
			call DiagMsg.uint16(schedule2);
			call DiagMsg.uint8(error2);
			call DiagMsg.send();
		}
	}
#else
	void printStats() { }
#endif
}
