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

module SerialDispatcherP
{
	provides
	{
		interface SplitControl;
		interface Receive[uart_id_t];
		interface Send[uart_id_t];
	}

	uses
	{
		interface SplitControl as SubControl;
		interface SerialComm as SubSend;
		interface Receive as SubReceive;
		interface SerialPacketInfo[uart_id_t id];
	}
}

implementation
{
	enum
	{
		STATE_OFF = 0,
		STATE_ON = 1,
		STATE_SEND = 2,
	};

	norace uint8_t state;

	task void signalDone();

// ------- SplitControl

	command error_t SplitControl.start()
	{
		if( state != STATE_OFF )
			return EALREADY;

		return call SubControl.start();
	}

	command error_t SplitControl.stop()
	{
		if( state != STATE_ON )
			return EALREADY;

		return call SubControl.stop();
	}

	event void SubControl.startDone(error_t error)
	{
		SERIAL_ASSERT( state == STATE_OFF );

		if( error == SUCCESS )
			state = STATE_ON;

		signal SplitControl.startDone(error);
	}

	event void SubControl.stopDone(error_t error)
	{
		SERIAL_ASSERT( state == STATE_ON );

		if( error == SUCCESS )
			state = STATE_OFF;

		signal SplitControl.stopDone(error);
	}

	default event void SplitControl.startDone(error_t error) { }
	default event void SplitControl.stopDone(error_t error) { }

// ------- Send

	message_t *txMsg;
	norace uint8_t *txPtr;
	norace uint8_t *txEnd;
	norace uint8_t txUart;
	norace uint8_t txError;

	command error_t Send.send[uart_id_t id](message_t* msg, uint8_t len)
	{
		if( state != STATE_ON )
			return EOFF;

		txMsg = msg;
		txPtr = ((uint8_t*)msg) + call SerialPacketInfo.offset[id]();
		txEnd = txPtr + call SerialPacketInfo.dataLinkLength[id](msg, len);
		txUart = id;

		call SubSend.start();
		return SUCCESS;
	}

	async event void SubSend.startDone()
	{
		SERIAL_ASSERT( state == STATE_ON );

		state = STATE_SEND;
		call SubSend.data(txUart);
	}
	
	async event void SubSend.dataDone()
	{
		SERIAL_ASSERT( state == STATE_SEND );

		if( txPtr != txEnd )
			call SubSend.data( *(txPtr++) );
		else
			call SubSend.stop();
	}

	async event void SubSend.stopDone(error_t error)
	{
		SERIAL_ASSERT( state == STATE_SEND );

		txError = error;
		post signalDone();
	}

	command error_t Send.cancel[uart_id_t id](message_t *msg)
	{
		return FAIL;
	}
	
	command uint8_t Send.maxPayloadLength[uart_id_t id]()
	{
		return 0;
	}

	command void* Send.getPayload[uart_id_t id](message_t* msg, uint8_t len)
	{
		return NULL;
	}

	default event void Send.sendDone[uart_id_t id](message_t *msg, error_t error)
	{
	}

// ------- Receive

	inline serial_metadata_t* getMeta(message_t *msg)
	{
		return (serial_metadata_t*)(msg->metadata);
	}

	event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t length)
	{
		uint8_t uart = getMeta(msg)->protocol[2];
		uint8_t newLength = call SerialPacketInfo.upperLength[uart](msg, length);

		SERIAL_ASSERT( ((uint8_t*)msg) + call SerialPacketInfo.offset[uart]() == payload );

		return signal Receive.receive[uart](msg, payload + (length - newLength), newLength);
	}

	default event message_t* Receive.receive[uart_id_t id](message_t* msg, void* payload, uint8_t length)
	{
		return msg;
	}

// ------- SignalDone

	task void signalDone()
	{
		SERIAL_ASSERT( state == STATE_SEND );

		if( state == STATE_SEND )
		{
			state = STATE_ON;
			signal Send.sendDone[txUart](txMsg, txError);
		}
	}

	default async command uint8_t SerialPacketInfo.offset[uart_id_t id]()
	{
		return 0;
	}

	default async command uint8_t SerialPacketInfo.dataLinkLength[uart_id_t id](message_t *msg, uint8_t len)
	{
		return len;
	}

	default async command uint8_t SerialPacketInfo.upperLength[uart_id_t id](message_t* msg, uint8_t len)
	{
		return len;
	}
}
