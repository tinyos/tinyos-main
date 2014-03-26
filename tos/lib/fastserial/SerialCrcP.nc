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
#include "crc.h"

module SerialCrcP
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
		TXSTATE_DATA = 0,
		TXSTATE_CRC1 = 1,
		TXSTATE_CRC2 = 2,
	};

	norace uint8_t txState;
	norace uint16_t crc;

	async command void SerialSend.start()
	{
		SERIAL_ASSERT( txState == TXSTATE_DATA );

		call SubSend.start();
	}

	async event void SubSend.startDone()
	{
		SERIAL_ASSERT( txState == TXSTATE_DATA );

		crc = 0;

		signal SerialSend.startDone();
	}

	async command void SerialSend.data(uint8_t byte)
	{
		SERIAL_ASSERT( txState == TXSTATE_DATA );

		// start transmitting, then we have time to calculate
		call SubSend.data(byte);

		crc = crcByte(crc, byte);
	}

	async event void SubSend.dataDone()
	{
		// make fast path fall through
		if( txState == TXSTATE_DATA )
			signal SerialSend.dataDone();
		else if( txState == TXSTATE_CRC1 )
		{
			txState = TXSTATE_CRC2;
			call SubSend.data((uint8_t)(crc >> 8));
		}
		else
		{
			SERIAL_ASSERT( txState == TXSTATE_CRC2 );
			call SubSend.stop();
		}
	}

	async command void SerialSend.stop()
	{
		SERIAL_ASSERT( txState == TXSTATE_DATA );

		txState = TXSTATE_CRC1;
		call SubSend.data((uint8_t)crc);
	}

	async event void SubSend.stopDone(error_t error)
	{
		SERIAL_ASSERT( txState == TXSTATE_CRC2 );

		txState = TXSTATE_DATA;
		signal SerialSend.stopDone(error);
	}

// ------- Receive

	inline serial_metadata_t* getMeta(message_t *msg)
	{
		return (serial_metadata_t*)(msg->metadata);
	}

	event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t length)
	{
		if( length >= 2 )
		{
			uint16_t c = 0;
			uint8_t i;
			uint8_t *p;

			// the first 3 bytes are in the protocol header
			p = (uint8_t*) getMeta(msg)->protocol;
			c = crcByte(c, *(p++));
			if( getMeta(msg)->protocol[0] == SERIAL_PROTO_PACKET_ACK) // seq nr is missing if there's no ACK
				c = crcByte(c, *(p++));
			else
				p++;
			c = crcByte(c, *p);

			p = payload;
			i = length - 1;
			while( --i > 0 )
				c = crcByte(c, *(p++));

			/*
			 * TODO: The CRC bytes come in the wrong order, this prevents
			 * the easy calculation within the while loop, this should be 
			 * fixed on the PC side. Also, this would automatically support
			 * short packets (length = 1 for ACK packet).
			 */
			c = crcByte(c, p[1]);
			c = crcByte(c, p[0]);

			if( c == 0 )
				msg = signal Receive.receive(msg, payload, length-2);
		}

		return msg;
	}
}
