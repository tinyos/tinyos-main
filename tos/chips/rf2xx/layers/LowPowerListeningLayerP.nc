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
		interface BareSend as Send;
		interface BareReceive as Receive;
		interface RadioPacket;

		interface LowPowerListening;
	}

	uses
	{
		interface SplitControl as SubControl;
		interface BareSend as SubSend;
		interface BareReceive as SubReceive;
		interface RadioPacket as SubPacket;

		interface PacketAcknowledgements;
		interface LowPowerListeningConfig as Config;
		interface Timer<TMilli>;
		interface SystemLowPowerListening;
	}
}

implementation
{
	enum
	{
		// minimum wakeup time to catch a transmission in milliseconds
		LISTEN_WAKEUP = 6U,	// use xxxL if LISTEN_WAKEUP * 10000 > 65535

		MIN_SLEEP = 2,		// the minimum sleep interval in milliseconds
		MAX_SLEEP = 30000,	// the maximum sleep interval in milliseconds
		MIN_DUTY = 2,		// the minimum duty cycle
	};

	uint16_t sleepInterval = LPL_DEF_LOCAL_WAKEUP;

	message_t* txMsg;
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
			transmitInterval = call LowPowerListening.getRemoteWakeupInterval(txMsg);

			if( transmitInterval > 0 )
				call Timer.startOneShot(transmitInterval);

			state = SEND_SUBSEND;
			post transition();
		}
		else if( state == SEND_SUBSEND)
		{
			txError = call SubSend.send(txMsg);

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
				call Timer.startOneShot(call SystemLowPowerListening.getDelayAfterReceive());

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

	event message_t* SubReceive.receive(message_t* msg)
	{
		if( state == SLEEP_SUBSTOP )
			state = LISTEN;

		if( state == LISTEN && sleepInterval > 0 )
			call Timer.startOneShot(call SystemLowPowerListening.getDelayAfterReceive());

		return signal Receive.receive(msg);
	}

	command error_t Send.send(message_t* msg)
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
			|| call LowPowerListening.getRemoteWakeupInterval(msg) == 0
			|| state == SEND_SUBSEND_DONE_LAST
			|| (call Config.getAckRequired(msg) && call PacketAcknowledgements.wasAcked(msg)) )
		{
			call Timer.stop();
			state = SEND_DONE;
		}
		else
			state = SEND_SUBSEND;

		post transition();
	}

/*----------------- LowPowerListening -----------------*/

	lpl_metadata_t* getMeta(message_t* msg)
	{
		return ((void*)msg) + sizeof(message_t) - call RadioPacket.metadataLength(msg);
	}

	command void LowPowerListening.setLocalWakeupInterval(uint16_t interval)
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

	command uint16_t LowPowerListening.getLocalWakeupInterval()
	{	
		return sleepInterval;
	}

	command void LowPowerListening.setRemoteWakeupInterval(message_t *msg, uint16_t interval)
	{
		if( interval < MIN_SLEEP )
			interval = 0;
		else if( interval > MAX_SLEEP )
			interval = MAX_SLEEP;

		getMeta(msg)->sleepint = interval;
	}

	command uint16_t LowPowerListening.getRemoteWakeupInterval(message_t *msg)
	{
		return getMeta(msg)->sleepint;
	}

/*----------------- RadioPacket -----------------*/
	
	async command uint8_t RadioPacket.headerLength(message_t* msg)
	{
		return call SubPacket.headerLength(msg);
	}

	async command uint8_t RadioPacket.payloadLength(message_t* msg)
	{
		return call SubPacket.payloadLength(msg);
	}

	async command void RadioPacket.setPayloadLength(message_t* msg, uint8_t length)
	{
		call SubPacket.setPayloadLength(msg, length);
	}

	async command uint8_t RadioPacket.maxPayloadLength()
	{
		return call SubPacket.maxPayloadLength();
	}

	async command uint8_t RadioPacket.metadataLength(message_t* msg)
	{
		return call SubPacket.metadataLength(msg) + sizeof(lpl_metadata_t);
	}

	async command void RadioPacket.clear(message_t* msg)
	{
		getMeta(msg)->sleepint = 0;
		call SubPacket.clear(msg);
	}
}
