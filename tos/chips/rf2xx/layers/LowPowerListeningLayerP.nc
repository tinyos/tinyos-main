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

#include <RadioAssert.h>
#include <LowPowerListeningLayer.h>

module LowPowerListeningLayerP
{
	provides
	{
		interface SplitControl;
		interface Send;
		interface Receive;

		interface LowPowerListening;
	}

	uses
	{
		interface SplitControl as SubControl;
		interface Send as SubSend;
		interface Receive as SubReceive;

		interface PacketData<lpl_metadata_t> as PacketLplMetadata;
		interface IEEE154PacketLayer;
		interface PacketAcknowledgements;
		interface Timer<TMilli>;
	}
}

implementation
{
	enum
	{
		// minimum wakeup time to catch a transmission in milliseconds
		LISTEN_WAKEUP = 6U,	// use xxxL if LISTEN_WAKEUP * 10000 > 65535

		// extra wakeup time after receiving a message in milliseconds
		AFTER_RECEIVE = 10U,

		// extra wakeup time after transmitting a message in milliseconds
		AFTER_TRANSMIT = 10U,

		MIN_SLEEP = 2,		// the minimum sleep interval in milliseconds
		MAX_SLEEP = 30000,	// the maximum sleep interval in milliseconds
		MIN_DUTY = 2,		// the minimum duty cycle
	};

	uint16_t sleepInterval;

	message_t* txMsg;
	uint8_t txLen;
	error_t txError;

/*----------------- state machine -----------------*/

	enum
	{
		OFF = 0,					
		OFF_SUBSTOP = 1,			// must have consecutive indices
		OFF_SUBSTOP_DONE = 2,			// must have consecutive indices
		OFF_STOP_END = 3,			// must have consecutive indices
		OFF_START_END = 4,

		LISTEN_SUBSTART = 5,			// must have consecutive indices
		LISTEN_SUBSTART_DONE = 6,		// must have consecutive indices
		LISTEN_TIMER = 7,			// must have consecutive indices
		LISTEN = 8,				// must have consecutive indices

		SLEEP_SUBSTOP = 9,			// must have consecutive indices
		SLEEP_SUBSTOP_DONE = 10,		// must have consecutive indices
		SLEEP_TIMER = 11,			// must have consecutive indices
		SLEEP = 12,				// must have consecutive indices

		SEND_SUBSTART = 13,			// must have consecutive indices
		SEND_SUBSTART_DONE = 14,		// must have consecutive indices
		SEND_TIMER = 15,			// must have consecutive indices
		SEND_SUBSEND= 16,
		SEND_SUBSEND_DONE = 17,
		SEND_SUBSEND_DONE_LAST = 18,
		SEND_DONE = 19,
	};

	uint8_t state;

	task void transition()
	{
		error_t error;
		uint16_t transmitInterval;

		if( state == LISTEN_SUBSTART || state == SEND_SUBSTART )
		{
			error = call SubControl.start();
			ASSERT( error == SUCCESS || error == EBUSY );

			if( error == SUCCESS )
				++state;
			else
				post transition();
		}
		else if( state == SLEEP_SUBSTOP || state == OFF_SUBSTOP )
		{
			error = call SubControl.stop();
			ASSERT( error == SUCCESS || error == EBUSY );

			if( error == SUCCESS )
				++state;
			else
				post transition();
		}
		else if( state == OFF_START_END )
		{
			state = LISTEN_SUBSTART;
			post transition();

			signal SplitControl.startDone(SUCCESS);
		}
		else if( state == OFF_STOP_END )
		{
			state = OFF;
			signal SplitControl.stopDone(SUCCESS);
		}
		else if( state == LISTEN_TIMER )
		{
			state = LISTEN;
			if( sleepInterval > 0 )
				call Timer.startOneShot(LISTEN_WAKEUP);
		}
		else if( state == SLEEP_TIMER )
		{
			if( sleepInterval > 0 )
			{
				state = SLEEP;
				call Timer.startOneShot(sleepInterval);
			}
			else
			{
				state = LISTEN_SUBSTART;
				post transition();
			}
		}
		else if( state == SEND_TIMER )
		{
			transmitInterval = call LowPowerListening.getRxSleepInterval(txMsg);

			if( transmitInterval > 0 )
				call Timer.startOneShot(transmitInterval);

			state = SEND_SUBSEND;
			post transition();
		}
		else if( state == SEND_SUBSEND)
		{
			txError = call SubSend.send(txMsg, txLen);

			if( txError == SUCCESS )
				state = SEND_SUBSEND_DONE;
			else
			{
				state = SEND_DONE;
				post transition();
			}
		}
		else if( state == SEND_DONE )
		{
			state = LISTEN;
			if( sleepInterval > 0 )
				call Timer.startOneShot(AFTER_TRANSMIT);

			signal Send.sendDone(txMsg, txError);
		}
	}

	command error_t SplitControl.start()
	{
		if( state == OFF_START_END )
			return EBUSY;
		else if( state != OFF )
			return EALREADY;

		state = OFF_START_END;
		post transition();

		return SUCCESS;
	}

	event void SubControl.startDone(error_t error)
	{
		ASSERT( error == SUCCESS || error == EBUSY );
		ASSERT( state == LISTEN_SUBSTART_DONE || state == SEND_SUBSTART_DONE );

		if( error == SUCCESS )
			++state;
		else
			--state;

		post transition();
	}

	command error_t SplitControl.stop()
	{
		if( state == SLEEP || state == LISTEN )
		{
			call Timer.stop();
			post transition();
		}

		if( state == LISTEN_TIMER || state == LISTEN || state == SLEEP_SUBSTOP )
			state = OFF_SUBSTOP;
		else if( state == SLEEP_SUBSTOP_DONE )
			state = OFF_SUBSTOP_DONE;
		else if( state == LISTEN_SUBSTART || state == SLEEP_TIMER || state == SLEEP )
			state = OFF_STOP_END;
		else if( state == OFF )
			return EALREADY;
		else
			return EBUSY;

		return SUCCESS;
	}

	event void SubControl.stopDone(error_t error)
	{
		ASSERT( error == SUCCESS || error == EBUSY );
		ASSERT( state == SLEEP_SUBSTOP_DONE || state == OFF_SUBSTOP_DONE );

		if( error == SUCCESS )
			++state;
		else
			--state;

		post transition();
	}

	event void Timer.fired()
	{
		ASSERT( state == LISTEN || state == SLEEP || state == SEND_SUBSEND || state == SEND_SUBSEND_DONE );

		if( state == LISTEN )
			state = SLEEP_SUBSTOP;
		else if( state == SLEEP )
			state = LISTEN_SUBSTART;
		else if( state == SEND_SUBSEND_DONE )
			state = SEND_SUBSEND_DONE_LAST;
		else if( state == SEND_SUBSEND)
			state = SEND_DONE;

		post transition();
	}

	event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len)
	{
		if( state == SLEEP_SUBSTOP )
			state = LISTEN;

		if( state == LISTEN && sleepInterval > 0 )
			call Timer.startOneShot(AFTER_RECEIVE);

		return signal Receive.receive(msg, payload, len);
	}

	command error_t Send.send(message_t* msg, uint8_t len)
	{
		if( state == LISTEN || state == SLEEP )
		{
			call Timer.stop();
			post transition();
		}

		if( state == LISTEN_SUBSTART || state == SLEEP_TIMER || state == SLEEP )
			state = SEND_SUBSTART;
		else if( state == LISTEN_SUBSTART_DONE )
			state = SEND_SUBSTART_DONE;
		else if( state == LISTEN_TIMER || state == SLEEP_SUBSTOP || state == LISTEN )
			state = SEND_TIMER;
		else
			return EBUSY;

		txMsg = msg;
		txLen = len;
		txError = FAIL;

		return SUCCESS;
	}

	command error_t Send.cancel(message_t* msg)
	{
		if( state == SEND_SUBSEND )
		{
			call Timer.stop();
			state = SEND_DONE;
			txError = ECANCEL;
			post transition();

			return SUCCESS;
		}
		else if( state == SEND_SUBSEND_DONE )
		{
			// we stop sending the message even if SubSend.cancel was not succesfull
			state = SEND_SUBSEND_DONE_LAST;

			return call SubSend.cancel(txMsg);
		}
		else
			return FAIL;
	}

	event void SubSend.sendDone(message_t* msg, error_t error)
	{
		ASSERT( state == SEND_SUBSEND_DONE || state == SEND_SUBSEND_DONE_LAST );
		ASSERT( msg == txMsg );

		txError = error;

		// TODO: extend the PacketAcknowledgements interface with getAckRequired
		if( error != SUCCESS
			|| call LowPowerListening.getRxSleepInterval(msg) == 0
			|| state == SEND_SUBSEND_DONE_LAST
			|| (call IEEE154PacketLayer.getAckRequired(msg) && call PacketAcknowledgements.wasAcked(msg)) )
		{
			call Timer.stop();
			state = SEND_DONE;
		}
		else
			state = SEND_SUBSEND;

		post transition();
	}

	command uint8_t Send.maxPayloadLength()
	{
		return call SubSend.maxPayloadLength();
	}

	command void* Send.getPayload(message_t* msg, uint8_t len)
	{
		return call SubSend.getPayload(msg, len);
	}

/*----------------- LowPowerListening -----------------*/

	command uint16_t LowPowerListening.dutyCycleToSleepInterval(uint16_t dutyCycle)
	{
		if( dutyCycle >= 10000 )
			return 0;
		else if( dutyCycle <= MIN_DUTY  )
			return MAX_SLEEP;

		return ((10000U * LISTEN_WAKEUP) / dutyCycle) - LISTEN_WAKEUP;
	}

	command uint16_t LowPowerListening.sleepIntervalToDutyCycle(uint16_t interval)
	{
		if( interval < MIN_SLEEP )
			return 10000;
		else if( interval >= MAX_SLEEP )
			return MIN_DUTY;

		return (10000U * LISTEN_WAKEUP) / (LISTEN_WAKEUP + interval);
	}

	command void LowPowerListening.setLocalSleepInterval(uint16_t interval)
	{
		if( interval < MIN_SLEEP )
			interval = 0;
		else if( interval > MAX_SLEEP )
			interval = MAX_SLEEP;

		sleepInterval = interval;

		if( (state == LISTEN && sleepInterval == 0) || state == SLEEP )
		{
			call Timer.stop();
			--state;
			post transition();
		}
	}

	command uint16_t LowPowerListening.getLocalSleepInterval()
	{	
		return sleepInterval;
	}

	command void LowPowerListening.setLocalDutyCycle(uint16_t dutyCycle)
	{
		call LowPowerListening.setLocalSleepInterval(
			call LowPowerListening.dutyCycleToSleepInterval(dutyCycle));
	}

	command uint16_t LowPowerListening.getLocalDutyCycle()
	{
		return call LowPowerListening.sleepIntervalToDutyCycle(sleepInterval);
	}

	command void LowPowerListening.setRxSleepInterval(message_t *msg, uint16_t interval)
	{
		if( interval < MIN_SLEEP )
			interval = 0;
		else if( interval > MAX_SLEEP )
			interval = MAX_SLEEP;

		(call PacketLplMetadata.get(msg))->sleepint = interval;
	}

	command uint16_t LowPowerListening.getRxSleepInterval(message_t *msg)
	{
		uint16_t sleepint = (call PacketLplMetadata.get(msg))->sleepint;

		return sleepint != 0 ? sleepint : sleepInterval;
	}

	command void LowPowerListening.setRxDutyCycle(message_t *msg, uint16_t dutyCycle)
	{
		call LowPowerListening.setRxSleepInterval(msg, 
			call LowPowerListening.dutyCycleToSleepInterval(dutyCycle));
	}

	command uint16_t LowPowerListening.getRxDutyCycle(message_t *msg)
	{
		return call LowPowerListening.sleepIntervalToDutyCycle(
			call LowPowerListening.getRxSleepInterval(msg));
	}

	async event void PacketLplMetadata.clear(message_t* msg)
	{
		(call PacketLplMetadata.get(msg))->sleepint = 0;
	}
}
