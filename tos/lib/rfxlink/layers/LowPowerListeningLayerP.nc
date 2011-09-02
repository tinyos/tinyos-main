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

#include <RadioAssert.h>
#include <LowPowerListeningLayer.h>
#include <Lpl.h>

generic module LowPowerListeningLayerP()
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

		interface Leds;
	}
}

implementation
{
	enum
	{
		MIN_SLEEP = 2,		// the minimum sleep interval in milliseconds
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

		LISTEN_SUBSTART = 10,			// must have consecutive indices
		LISTEN_SUBSTART_DONE = 11,		// must have consecutive indices
		LISTEN_TIMER = 12,			// must have consecutive indices
		LISTEN_WAIT = 13,			// must have consecutive indices

		SLEEP_SUBSTOP = 20,			// must have consecutive indices
		SLEEP_SUBSTOP_DONE = 21,		// must have consecutive indices
		SLEEP_TIMER = 22,			// must have consecutive indices
		SLEEP_WAIT = 23,			// must have consecutive indices

		SLEEP_SUBSTOP_DONE_TOSEND = 29,		// must have consecutive indices
		SEND_SUBSTART = 30,			// must have consecutive indices
		SEND_SUBSTART_DONE = 31,		// must have consecutive indices
		SEND_TIMER = 32,			// must have consecutive indices
		SEND_SUBSEND= 33,
		SEND_SUBSEND_DONE = 34,
		SEND_SUBSEND_DONE_LAST = 35,
		SEND_DONE = 36,
	};

	uint8_t state;

	task void transition()
	{
		error_t error;
		uint16_t transmitInterval;

		if( state == LISTEN_SUBSTART || state == SEND_SUBSTART )
		{
			error = call SubControl.start();
			RADIO_ASSERT( error == SUCCESS || error == EBUSY );

			if( error == SUCCESS )
			{
				call Leds.led2On();
				++state;
			}
			else
				post transition();
		}
		else if( state == SLEEP_SUBSTOP || state == OFF_SUBSTOP )
		{
			error = call SubControl.stop();
			RADIO_ASSERT( error == SUCCESS || error == EBUSY );

			if( error == SUCCESS )
			{
				++state;
				call Leds.led2Off();
			}
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
			state = LISTEN_WAIT;
			if( sleepInterval > 0 )
				call Timer.startOneShot(call Config.getListenLength());
		}
		else if( state == SLEEP_TIMER )
		{
			if( sleepInterval > 0 )
			{
				state = SLEEP_WAIT;
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
				call Timer.startOneShot(transmitInterval 
					+ 2 * call Config.getListenLength());

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
			state = LISTEN_WAIT;
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
		RADIO_ASSERT( error == SUCCESS || error == EBUSY );
		RADIO_ASSERT( state == LISTEN_SUBSTART_DONE || state == SEND_SUBSTART_DONE );

		if( error == SUCCESS )
			++state;
		else
			--state;

		post transition();
	}

	command error_t SplitControl.stop()
	{
		if( state == SLEEP_WAIT || state == LISTEN_WAIT )
		{
			call Timer.stop();
			post transition();
		}

		if( state == LISTEN_TIMER || state == LISTEN_WAIT || state == SLEEP_SUBSTOP )
			state = OFF_SUBSTOP;
		else if( state == SLEEP_SUBSTOP_DONE )
			state = OFF_SUBSTOP_DONE;
		else if( state == LISTEN_SUBSTART || state == SLEEP_TIMER || state == SLEEP_WAIT )
			state = OFF_STOP_END;
		else if( state == OFF )
			return EALREADY;
		else
			return EBUSY;

		return SUCCESS;
	}

	event void SubControl.stopDone(error_t error)
	{
		RADIO_ASSERT( error == SUCCESS || error == EBUSY );
		RADIO_ASSERT( state == SLEEP_SUBSTOP_DONE || state == OFF_SUBSTOP_DONE || state == SLEEP_SUBSTOP_DONE_TOSEND );

		if( error == SUCCESS )
			++state;
		else if( state != SLEEP_SUBSTOP_DONE_TOSEND )
			--state;
		else
			state = SEND_TIMER;

		post transition();
	}

	event void Timer.fired()
	{
		if( state == LISTEN_WAIT )
			state = SLEEP_SUBSTOP;
		else if( state == SLEEP_WAIT )
			state = LISTEN_SUBSTART;
		else if( state == SEND_SUBSEND_DONE )
			state = SEND_SUBSEND_DONE_LAST;
		else if( state == SEND_SUBSEND)
			state = SEND_DONE;
		else
			RADIO_ASSERT(FALSE);

		post transition();
	}

	event message_t* SubReceive.receive(message_t* msg)
	{
		call Leds.led0Toggle();

		if( state == SLEEP_SUBSTOP )
			state = LISTEN_WAIT;

		if( state == LISTEN_WAIT && sleepInterval > 0 )
			call Timer.startOneShot(call SystemLowPowerListening.getDelayAfterReceive());

		return signal Receive.receive(msg);
	}

	command error_t Send.send(message_t* msg)
	{
		if( state == LISTEN_WAIT || state == SLEEP_WAIT )
		{
			call Timer.stop();
			post transition();
		}

		if( state == LISTEN_SUBSTART || state == SLEEP_TIMER || state == SLEEP_WAIT )
			state = SEND_SUBSTART;
		else if( state == LISTEN_SUBSTART_DONE )
			state = SEND_SUBSTART_DONE;
		else if( state == LISTEN_TIMER || state == SLEEP_SUBSTOP || state == LISTEN_WAIT )
			state = SEND_TIMER;
		else if( state == SLEEP_SUBSTOP_DONE )
			state = SLEEP_SUBSTOP_DONE_TOSEND;
		else
			return EBUSY;

		if( call Config.needsAutoAckRequest(msg) )
			call PacketAcknowledgements.requestAck(msg);

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
		RADIO_ASSERT( state == SEND_SUBSEND_DONE || state == SEND_SUBSEND_DONE_LAST );
		RADIO_ASSERT( msg == txMsg );

		txError = error;

		// TODO: extend the PacketAcknowledgements interface with getAckRequired
		if( error != SUCCESS
			|| call LowPowerListening.getRemoteWakeupInterval(msg) == 0
			|| state == SEND_SUBSEND_DONE_LAST
			|| (call Config.ackRequested(msg) && call PacketAcknowledgements.wasAcked(msg)) )
		{
			call Timer.stop();
			state = SEND_DONE;
		}
		else
			state = SEND_SUBSEND;

		post transition();

		if( error == SUCCESS )
			call Leds.led1Toggle();
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

		sleepInterval = interval;

		if( state == LISTEN_WAIT || state == SLEEP_WAIT )
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

		getMeta(msg)->sleepint = interval;
	}

	command uint16_t LowPowerListening.getRemoteWakeupInterval(message_t *msg)
	{
		return getMeta(msg)->sleepint;
	}

	default event void SplitControl.startDone(error_t error) { }
	default event void SplitControl.stopDone(error_t error) { }

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
