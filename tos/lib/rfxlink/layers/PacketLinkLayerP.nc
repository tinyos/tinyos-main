/*
 * Copyright (c) 2010, University of Szeged
 * Copyright (c) 2010, Aarhus Universitet
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
 * Author: Miklos Maroti,
 * Author: Morten Tranberg Hansen
 */

#include <PacketLinkLayer.h>
#include <RadioAssert.h>

generic module PacketLinkLayerP()
{
	provides
	{
		interface BareSend as Send;
		interface PacketLink;
		interface RadioPacket;
	}

	uses
	{
		interface BareSend as SubSend;
		interface PacketAcknowledgements;
		interface Timer<TMilli> as DelayTimer;
		interface RadioPacket as SubPacket;
	}
}

implementation
{
	enum
	{
		STATE_READY = 0,
		STATE_SENDING = 1,
		STATE_SENDDONE = 2,
		STATE_SIGNAL = 4,	// add error code
	};

	uint8_t state = STATE_READY;
	message_t *currentMsg;
	uint16_t totalRetries;

	/**
	 * We do everything from a single task in order to call SubSend.send 
	 * and Send.sendDone only once. This helps inlining the code and
	 * reduces the code size.
	 */
	task void send()
	{
		uint16_t retries;
	
		RADIO_ASSERT( state != STATE_READY );

		retries = call PacketLink.getRetries(currentMsg);

		if( state == STATE_SENDDONE )
		{
			if( retries == 0 || call PacketAcknowledgements.wasAcked(currentMsg) )
				state = STATE_SIGNAL + SUCCESS;
			else if( ++totalRetries < retries )
			{
				uint16_t delay;

				state = STATE_SENDING;
				delay = call PacketLink.getRetryDelay(currentMsg);

				if( delay > 0 )
				{
					call DelayTimer.startOneShot(delay);
					return;
				}
			}
			else
				state = STATE_SIGNAL + FAIL;
		}

		if( state == STATE_SENDING )
		{
			state = STATE_SENDDONE;

			if( call SubSend.send(currentMsg) != SUCCESS )
				post send();

			return;
		}

		if( state >= STATE_SIGNAL )
		{
			error_t error = state - STATE_SIGNAL;

			// do not update the retries count for non packet link messages
			if( retries > 0 )
				call PacketLink.setRetries(currentMsg, totalRetries);

			state = STATE_READY;
			signal Send.sendDone(currentMsg, error);
		}
	}

	event void SubSend.sendDone(message_t* msg, error_t error)
	{
		RADIO_ASSERT( state == STATE_SENDDONE || state == STATE_SIGNAL + ECANCEL );
		RADIO_ASSERT( msg == currentMsg );

		if( error != SUCCESS )
			state = STATE_SIGNAL + error;

		post send();
	}

	event void DelayTimer.fired()
	{
		RADIO_ASSERT( state == STATE_SENDING );

		post send();
	}

	command error_t Send.send(message_t *msg)
	{
		if( state != STATE_READY )
			return EBUSY;

		// it is enough to set it only once
		if( call PacketLink.getRetries(msg) > 0 )
			call PacketAcknowledgements.requestAck(msg);

		currentMsg = msg;
		totalRetries = 0;
		state = STATE_SENDING;
		post send();

		return SUCCESS;
	}

	command error_t Send.cancel(message_t *msg)
	{
		if( currentMsg != msg || state == STATE_READY )
			return FAIL;

		// if a send is in progress
		if( state == STATE_SENDDONE )
			call SubSend.cancel(msg);
		else
			post send();

		call DelayTimer.stop();
		state = STATE_SIGNAL + ECANCEL;

		return SUCCESS;
	}

// ------- PacketLink

	link_metadata_t* getMeta(message_t* msg)
	{
		return ((void*)msg) + sizeof(message_t) - call RadioPacket.metadataLength(msg);
	}

	command void PacketLink.setRetries(message_t *msg, uint16_t maxRetries)
	{
		getMeta(msg)->maxRetries = maxRetries;
	}

	command void PacketLink.setRetryDelay(message_t *msg, uint16_t retryDelay)
	{
		getMeta(msg)->retryDelay = retryDelay;
	}

	command uint16_t PacketLink.getRetries(message_t *msg)
	{
		return getMeta(msg)->maxRetries;
	}

	command uint16_t PacketLink.getRetryDelay(message_t *msg)
	{
		return getMeta(msg)->retryDelay;
	}

	command bool PacketLink.wasDelivered(message_t *msg)
	{
		return call PacketAcknowledgements.wasAcked(msg);
	}

// ------- RadioPacket

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
		return call SubPacket.metadataLength(msg) + sizeof(link_metadata_t);
	}

	async command void RadioPacket.clear(message_t* msg)
	{
		getMeta(msg)->maxRetries = 0;
		call SubPacket.clear(msg);
	}
}
