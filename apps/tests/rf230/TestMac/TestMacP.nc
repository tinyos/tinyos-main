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

#include "TestMac.h"

module TestMacP
{
	uses
	{
		interface Boot;
		interface DiagMsg;

		interface Timer<TMilli> as SendTimer;
		interface Timer<TMilli> as ReportTimer;

		interface Receive;
		interface Receive as Snoop;
		interface AMSend;
		interface PacketAcknowledgements;

		interface SplitControl as SerialControl;
		interface SplitControl as RadioControl;
	}
}

implementation
{
	task void serialPowerUp()
	{
		if( call SerialControl.start() != SUCCESS )
			post serialPowerUp();
	}

	event void Boot.booted()
	{
		post serialPowerUp();
	}

	task void radioPowerUp()
	{
		if( call RadioControl.start() != SUCCESS )
			post radioPowerUp();
	}

	event void SerialControl.startDone(error_t error)
	{
		if( error != SUCCESS )
			post serialPowerUp();
		else
			post radioPowerUp();
	}

	void send();

	task void sendTask()
	{
		send();
	}

	event void RadioControl.startDone(error_t error)
	{
		if( error != SUCCESS )
			post radioPowerUp();
		else
		{
			if( SEND_RATE > 0 )
				call SendTimer.startPeriodic(SEND_RATE);
			else if( SEND_RATE == 0 )
				post sendTask();
			
			call ReportTimer.startPeriodic(1000);
		}
	}

	event void SendTimer.fired()
	{
		send();
	}

	event void RadioControl.stopDone(error_t error)	{ }
	event void SerialControl.stopDone(error_t error) { }

	typedef struct source_t
	{
		uint16_t sequence;
		uint16_t failures;
		uint16_t errors;
	} source_t;

	source_t sources[SOURCE_COUNT];

	message_t txMsg;

	typedef struct source_msg_t
	{
		uint8_t source;
		uint16_t sequence;
		uint8_t failures;
		uint8_t errors;
		uint8_t stuff[23];
	} source_msg_t;

	void send()
	{
		source_msg_t* data = (source_msg_t*)txMsg.data;
		data->source = SEND_SOURCE;
		data->sequence = sources[SEND_SOURCE].sequence;
		data->failures = sources[SEND_SOURCE].failures;
		data->errors = sources[SEND_SOURCE].errors;

		if( SEND_ACK )
			call PacketAcknowledgements.requestAck(&txMsg);
		else
			call PacketAcknowledgements.noAck(&txMsg);

		if( call AMSend.send(SEND_TARGET, &txMsg, sizeof(source_msg_t)) != SUCCESS )
			post sendTask();
	}

	event void AMSend.sendDone(message_t* msg, error_t error)
	{
		if( error != SUCCESS )
		{
			sources[SEND_SOURCE].errors += 1;
			post sendTask();
		}
		else
		{
			if( SEND_ACK )
			{
				if( ! call PacketAcknowledgements.wasAcked(msg) )
					sources[SEND_SOURCE].failures += 1;
			}

			sources[SEND_SOURCE].sequence += 1;

			if( SEND_RATE == 0 )
				post sendTask();
		}
	}

	event void ReportTimer.fired()
	{
		if( call DiagMsg.record() )
		{
			uint8_t i;

			call DiagMsg.uint8(TOS_NODE_ID);

			for(i = 0; i < SOURCE_COUNT; ++i)
			{
				call DiagMsg.uint16(sources[i].sequence);
				call DiagMsg.uint16(sources[i].failures);
				call DiagMsg.uint16(sources[i].errors);
			}

			call DiagMsg.send();
		}
	}

	message_t* receive(message_t* msg)
	{
		source_msg_t* data = (source_msg_t*)(msg->data);

		if( data->source < SOURCE_COUNT && data->source != SEND_SOURCE )
		{
			uint8_t source = data->source;

			if( sources[source].sequence == data->sequence )
				sources[source].errors += 1;
			else 
				sources[source].failures += (uint16_t)(data->sequence - sources[source].sequence - 1);

			sources[source].sequence = data->sequence;
		}

		return msg;
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len)
	{
		return receive(msg);
	}

	event message_t* Snoop.receive(message_t* msg, void* payload, uint8_t len)
	{
		return receive(msg);
	}
}
