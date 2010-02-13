/*
 * Copyright (c) 2002-2007, Vanderbilt University
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

#include <message.h>

module DiagMsgP
{
	provides 
	{
		interface DiagMsg;
		interface Init;
	}

	uses 
	{
		interface AMSend;
		interface Packet;
	}
}

#ifndef DIAGMSG_BASE_STATION
#define	DIAGMSG_BASE_STATION	AM_BROADCAST_ADDR
#endif

#ifndef DIAGMSG_RETRY_COUNT
#define	DIAGMSG_RETRY_COUNT	2
#endif

#ifndef DIAGMSG_RECORDED_MSGS
#define DIAGMSG_RECORDED_MSGS	10
#endif

implementation
{
	enum
	{
		STATE_READY = 1,
		STATE_RECORDING_FIRST = 2,	// recording the first 4-bit descriptor
		STATE_RECORDING_SECOND = 3,	// recording the second 4-bit descriptor
		STATE_MSG_FULL = 4,
		STATE_BUFFER_FULL = 5,
	};

	norace volatile uint8_t state;	// the state of the recording

	message_t msgs[DIAGMSG_RECORDED_MSGS];	// circular buffer of messages

	norace message_t *recording;	// the message that is beeing or going to be recorded
	message_t *sending;	// the message that is beeing sent, or the null pointer

	norace uint8_t nextData;	// points to the next unsued byte
	norace uint8_t prevType;	// points to the type descriptor
	norace uint8_t retries;	// number of remaining retries

	command error_t Init.init()
	{
		state = STATE_READY;
		recording = msgs;
		sending = 0;

		return SUCCESS;
	}

	// two type fields are stored in on byte
	enum
	{
		TYPE_END = 0,
		TYPE_INT8 = 1,
		TYPE_UINT8 = 2,
		TYPE_HEX8 = 3,
		TYPE_INT16 = 4,
		TYPE_UINT16 = 5,
		TYPE_HEX16 = 6,
		TYPE_INT32 = 7,
		TYPE_UINT32 = 8,
		TYPE_HEX32 = 9,
		TYPE_FLOAT = 10,
		TYPE_CHAR = 11,
		TYPE_INT64 = 12,
		TYPE_UINT64 = 13,
		TYPE_ARRAY = 15,
	};

/*
	The format of the payload is as follows: 
	
	Each value has an associated data type descriptor. The descriptor takes 4-bits,
	and two descriptors are packed into one byte. The double-descriptor is followed
	by the data bytes needed to store the corresponding value. Two sample layouts are:

	[D2, D1] [V1] ... [V1] [V2] ... [V2]
	[D2, D1] [V1] ... [V1] [V2] ... [V2] [0, D3] [V3] ... [V3]

	where D1, D2, D3 denotes the data type descriptors, and V1, V2 and V3
	denotes the bytes where the corresponding values are stored. If there is an odd
	number of data descriptors, then a zero data descriptor <code>TYPE_END</code> 
	is inserted.

	Each data type (except arrays) uses a fixed number of bytes to store the value.
	For arrays, the first byte of the array holds the data type of the array (higer
	4 bits) and the length of the array (lower 4 bits). The actual data follows 
	this first byte.
*/

	async command bool DiagMsg.record()
	{
		atomic
		{
			// currently recording or no more space
			if( state != STATE_READY )
				return FALSE;

			state = STATE_RECORDING_FIRST;
			nextData = 0;
		}

		return TRUE;
	}

	/**
	 * Allocates space in the message for <code>size</code> bytes
	 * and sets the type information to <code>type</code>. 
	 * Returns the index in <code>msg.data</code> where the data 
	 * should be stored or <code>-1</code> if no more space is avaliable.
	 */
	int8_t allocate(uint8_t size, uint8_t type)
	{
		int8_t ret = -1;

		if( state == STATE_RECORDING_FIRST )
		{
			if( nextData + 1 + size <= TOSH_DATA_LENGTH )
			{
				state = STATE_RECORDING_SECOND;

				prevType = nextData++;
				((uint8_t*) &(recording->data))[prevType] = type;
				ret = nextData;
				nextData += size;
			}
			else
				state = STATE_MSG_FULL;
		}
		else if( state == STATE_RECORDING_SECOND )
		{
			if( nextData + size <= TOSH_DATA_LENGTH )
			{
				state = STATE_RECORDING_FIRST;

				((uint8_t*) &(recording->data))[prevType] += (type << 4);
				ret = nextData;
				nextData += size;
			}
			else
				state = STATE_MSG_FULL;
		}

		return ret;
	}

	void copyData(uint8_t size, uint8_t type2, const void* data)
	{
		int8_t start = allocate(size, type2);
		if( start >= 0 )
			memcpy(&(recording->data[start]), data, size);
	}

	void copyArray(uint8_t size, uint8_t type2, const void* data, uint8_t len)
	{
		int8_t start;

		if( len > 15 )
			len = 15;

		start = allocate(size*len + 1, TYPE_ARRAY);
		if( start >= 0 )
		{
			recording->data[start] = (type2 << 4) + len;
			memcpy(&(recording->data[start + 1]), data, size*len);
		}
	}
	
#define IMPLEMENT(NAME, TYPE, TYPE2) \
	async command void DiagMsg.NAME(TYPE value) { copyData(sizeof(TYPE), TYPE2, &value); } \
	async command void DiagMsg.NAME##s(const TYPE *value, uint8_t len) { copyArray(sizeof(TYPE), TYPE2, value, len); }

	IMPLEMENT(int8, int8_t, TYPE_INT8)
	IMPLEMENT(uint8, uint8_t, TYPE_UINT8)
	IMPLEMENT(hex8, uint8_t, TYPE_HEX8)
	IMPLEMENT(int16, int16_t, TYPE_INT16)
	IMPLEMENT(uint16, uint16_t, TYPE_UINT16)
	IMPLEMENT(hex16, uint16_t, TYPE_HEX16)
	IMPLEMENT(int32, int32_t, TYPE_INT32)
	IMPLEMENT(uint32, uint32_t, TYPE_UINT32)
	IMPLEMENT(hex32, uint32_t, TYPE_HEX32)
	IMPLEMENT(int64, int64_t, TYPE_INT64)
	IMPLEMENT(uint64, uint64_t, TYPE_UINT64)
	IMPLEMENT(real, float, TYPE_FLOAT)
	IMPLEMENT(chr, char, TYPE_CHAR)

	async command void DiagMsg.str(const char* str)
	{
		int8_t len = 0;
		while( str[len] != 0 && len < 15 )
			++len;
		
		call DiagMsg.chrs(str, len);
	}

	// TODO: this is a hack because setPayloadLength should be async
	inline void setPayloadLength(message_t* msg, uint8_t length)
	{
		(*(uint8_t*) &(msg->header)) = length;
	}

	inline uint8_t getPayloadLength(message_t* msg)
	{
		return *(uint8_t*) &(msg->header);
	}

	task void send()
	{
		message_t* msg;

		atomic msg = sending;

		if( call AMSend.send(DIAGMSG_BASE_STATION, msg, getPayloadLength(msg)) != SUCCESS )
			post send();
	}

	// calculates the next message_t pointer in the <code>msgs</code> circular buffer
	static inline message_t* nextPointer(message_t* ptr)
	{
		if( ++ptr >= msgs + DIAGMSG_RECORDED_MSGS )
			return msgs;
		else
			return ptr;
	}

	async command void DiagMsg.send()
	{
		// no message recorded
		if( state == STATE_READY )
			return;

		// store the length
		setPayloadLength(recording, nextData);

		atomic
		{
			if( sending == 0 )
			{
				sending = recording;
				retries = DIAGMSG_RETRY_COUNT;
				post send();
			}
	
			recording = nextPointer(recording);

			if( recording == sending )
				state = STATE_BUFFER_FULL;
			else
				state = STATE_READY;
		}
	}

	event void AMSend.sendDone(message_t* p, error_t error)
	{
		atomic
		{
			// retry if not successful
			if( error != SUCCESS && --retries > 0 )
				post send();
			else
			{
				p = nextPointer(sending);
				if( p != recording )
				{
					sending = p;
					retries = DIAGMSG_RETRY_COUNT;
					post send();
				}
				else
				{
					sending = 0;

					if( state == STATE_BUFFER_FULL )
					{
						state = STATE_READY;
						if( call DiagMsg.record() )
						{
							call DiagMsg.str("DiagMsgOverflow");
							call DiagMsg.send();
						}
					}
				}
			}
		}
	}
}
