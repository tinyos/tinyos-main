/** Copyright (c) 2010, University of Szeged
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Author: Miklos Maroti
*/

#include "Serial.h"
#include "SerialDebug.h"

module SerialProtocolP
{
	provides
	{
		interface SerialComm as SerialSend;
		interface Receive;
	}

	uses
	{
		interface SerialComm as SubSend;
		interface Receive as SubReceive;
	}
}

implementation
{
// ------- Send	

	enum
	{
		STATE_OFF = 0,

		STATE_STARTED = 0x01,		// currently sending a DATA or ACK frame
		STATE_PACKET_ACK = 0x02,	// transmit an ACK frame after the protocol byte
		STATE_PACKET_DATA = 0x04,	// sending the payload of a DATA frame
		STATE_PACKET_END = 0x08,	// finish the transmission after and ACK frame

		STATE_PENDING_ACK = 0x10,	// start ACK frame after the currently transmitted frame
		STATE_PENDING_DATA = 0x20,	// start DATA frame after the currently transmitted frame
	};

	norace uint8_t state;
	norace uint8_t ackToken;

	void sendAckFrame(uint8_t token)
	{
		SERIAL_ASSERT( (state & STATE_PACKET_ACK) == 0 );
		SERIAL_ASSERT( (state & STATE_PENDING_ACK) == 0 );

		ackToken = token;

		if( (state & STATE_STARTED) == 0 )
		{
			state |= STATE_STARTED | STATE_PACKET_ACK;
			call SubSend.start();
		}
		else
			state |= STATE_PENDING_ACK;
	}

	async command void SerialSend.start()
	{
		SERIAL_ASSERT( (state & STATE_PACKET_DATA) == 0 );
		SERIAL_ASSERT( (state & STATE_PENDING_DATA) == 0 );

		if( (state & STATE_STARTED) == 0 )
		{
			state |= STATE_STARTED;
			call SubSend.start();
		}
		else
			state |= STATE_PENDING_DATA;
	}

	async event void SubSend.startDone()
	{
		uint8_t byte;

		SERIAL_ASSERT( (state & STATE_STARTED) != 0 );
		SERIAL_ASSERT( (state & STATE_PACKET_DATA) == 0 );
		SERIAL_ASSERT( (state & STATE_PACKET_END) == 0 );

		if( (state & STATE_PACKET_ACK) != 0 )
			byte = SERIAL_PROTO_ACK;
		else
			byte = SERIAL_PROTO_PACKET_NOACK;

		call SubSend.data(byte);
	}

	async command void SerialSend.data(uint8_t byte)
	{
		SERIAL_ASSERT( (state & STATE_STARTED) != 0 );
		SERIAL_ASSERT( (state & STATE_PACKET_DATA) != 0 );
		SERIAL_ASSERT( (state & STATE_PACKET_ACK) == 0 );
		SERIAL_ASSERT( (state & STATE_PACKET_END) == 0 );

		call SubSend.data(byte);
	}

	async event void SubSend.dataDone()
	{
		SERIAL_ASSERT( (state & STATE_STARTED) != 0 );

		// make fast path fall through
		if( (state & STATE_PACKET_DATA) != 0 )
			signal SerialSend.dataDone();
		else if( (state & STATE_PACKET_ACK) == 0 )
		{
			state |= STATE_PACKET_DATA;
			signal SerialSend.startDone();
		}
		else if( (state & STATE_PACKET_END) == 0 )
		{
			state |= STATE_PACKET_END;
			call SubSend.data(ackToken);
		}
		else
			call SubSend.stop();
	}

	async command void SerialSend.stop()
	{
		SERIAL_ASSERT( (state & STATE_STARTED) != 0 );
		SERIAL_ASSERT( (state & STATE_PACKET_DATA) != 0 );
		SERIAL_ASSERT( (state & STATE_PACKET_ACK) == 0 );
		SERIAL_ASSERT( (state & STATE_PACKET_END) == 0 );

		call SubSend.stop();
	}

	async event void SubSend.stopDone(error_t error)
	{
		bool oldState = state;

		if( (state & STATE_PENDING_ACK) != 0 )
		{
			SERIAL_ASSERT( state == (STATE_STARTED | STATE_PACKET_DATA | STATE_PENDING_ACK) );
			state = STATE_STARTED | STATE_PACKET_ACK;
		}
		else if( (state & STATE_PENDING_DATA) != 0 )
		{
			SERIAL_ASSERT( state == (STATE_STARTED | STATE_PACKET_ACK | STATE_PACKET_END | STATE_PENDING_DATA) );
			state = STATE_STARTED;
		}
		else
			state = STATE_OFF;

		if( state != STATE_OFF )
			call SubSend.start();

		if( (oldState & STATE_PACKET_DATA) != 0 )
			signal SerialSend.stopDone(error);
	}

// ------- Receive

	inline serial_metadata_t* getMeta(message_t *msg)
	{
		return (serial_metadata_t*)(msg->metadata);
	}

	event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t length)
	{
		uint8_t proto = getMeta(msg)->protocol[0];
		if( proto == SERIAL_PROTO_PACKET_ACK )
		{
			sendAckFrame(getMeta(msg)->protocol[1]);
		}
		if( proto == SERIAL_PROTO_PACKET_NOACK || proto == SERIAL_PROTO_PACKET_ACK ){
			msg = signal Receive.receive(msg, payload, length);
		}

		return msg;
	}
}
