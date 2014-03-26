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

#include "SerialDebug.h"

module SerialBufferP
{
	provides
	{
		interface SerialComm as SubReceive;
		interface Receive;
	}

	uses
	{
		interface SerialPacketInfo[uart_id_t id];
	}
}

implementation
{
	inline serial_metadata_t* getMeta(message_t *msg)
	{
		return (serial_metadata_t*)(msg->metadata);
	}

	inline uint8_t* getPayload(message_t *msg)
	{
		uint8_t uart = getMeta(msg)->protocol[2];

		return ((uint8_t*)msg) + call SerialPacketInfo.offset[uart]();
	}

// ------- State

	enum
	{
		RXSTATE_OFF = 0,
		RXSTATE_NOBUFFER = 1,
		RXSTATE_PROTOCOL = 2,
		RXSTATE_PROTOCOL2 = 3,
		RXSTATE_PAYLOAD = 4,
		RXSTATE_ERROR = 5,
	};

	message_t rxMsgBuffer;	
	norace message_t *rxMsg = &rxMsgBuffer;

	norace uint8_t *rxPtr;
	norace uint8_t *rxEnd;
	norace uint8_t rxState;

	void setReceiveBuffer(message_t *msg)
	{
		SERIAL_ASSERT( rxMsg == NULL && msg != NULL );
		SERIAL_ASSERT( rxPtr == rxEnd );

		rxMsg = msg;

		// if started without a buffer and no data has been received
		if( rxState == RXSTATE_NOBUFFER )
		{
			rxPtr = (uint8_t*) getMeta(msg)->protocol;
			rxEnd = rxPtr;
			rxState = RXSTATE_PROTOCOL;
		}
	}

	async command void SubReceive.start()
	{
		SERIAL_ASSERT( rxState == RXSTATE_OFF );
		SERIAL_ASSERT( rxPtr == rxEnd );

		if( rxMsg != NULL )
		{
			rxPtr = (uint8_t*) getMeta(rxMsg)->protocol;
			rxEnd = rxPtr;
			rxState = RXSTATE_PROTOCOL;
		}
		else
			rxState = RXSTATE_NOBUFFER;

		signal SubReceive.startDone();
	}

	async command void SubReceive.data(uint8_t byte)
	{
		SERIAL_ASSERT( rxState != RXSTATE_OFF );
		
		// make the fall through case fast
		if( rxPtr != rxEnd )
		{
			SERIAL_ASSERT( rxState == RXSTATE_PROTOCOL || rxState == RXSTATE_PAYLOAD );
			SERIAL_ASSERT( rxPtr != NULL );

			*(rxPtr++) = byte;
		}
		else if( rxState == RXSTATE_PROTOCOL ){
			*(rxPtr++) = byte;
			rxEnd = rxPtr+1;
			if( byte == SERIAL_PROTO_PACKET_NOACK )
				rxPtr++;
			rxState = RXSTATE_PROTOCOL2;
		}
		else if( rxState == RXSTATE_PROTOCOL2 )
		{
			SERIAL_ASSERT( (nx_uint8_t*)rxPtr == getMeta(rxMsg)->protocol + 2 ); 

			// store the last byte
			*rxPtr = byte;

			rxPtr = getPayload(rxMsg);
			rxEnd = & getMeta(rxMsg)->length;
			rxState = RXSTATE_PAYLOAD;
		}
		else
			rxState = RXSTATE_ERROR;

		signal SubReceive.dataDone();
	}

	message_t* deliverBuffer(message_t* msg);

	async command void SubReceive.stop()
	{
		SERIAL_ASSERT( rxState != RXSTATE_OFF );

		if( rxState == RXSTATE_PAYLOAD )
		{
			SERIAL_ASSERT( rxMsg != NULL );

			getMeta(rxMsg)->length = rxPtr - getPayload(rxMsg);
			rxMsg = deliverBuffer(rxMsg);
		}

		rxPtr = NULL;
		rxEnd = NULL;
		rxState = RXSTATE_OFF;

		signal SubReceive.stopDone(SUCCESS);
	}

	default async command uint8_t SerialPacketInfo.offset[uart_id_t id]()
	{
		return 0;
	}

// ------- Buffer

	norace message_t* deliverMsg;

	task void deliverTask()
	{
		message_t *msg = deliverMsg;
		msg = signal Receive.receive(msg, getPayload(msg), getMeta(msg)->length);
		setReceiveBuffer(msg);
	}

	/*
	 * If there is free buffer, then return that, otherwise return 
	 * NULL and from a task call setReceiveBuffer with a free buffer.
	 */
	message_t* deliverBuffer(message_t *msg)
	{
		deliverMsg = msg;
		post deliverTask();
		return NULL;
	}
}
