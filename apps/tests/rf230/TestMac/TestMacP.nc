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
