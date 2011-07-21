/** Copyright (c) 2011, University of Szeged
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

#include "Timer.h"
#include "TestTimeStamping.h"

module TestTimeStampingP
{
	uses
	{
		interface Boot;
		interface Leds;
		interface Timer<TMilli>;
		interface SplitControl as RadioControl;
		interface AMSend;
		interface Receive;
		interface Packet;
		interface AMPacket;
		interface PacketTimeStamp<test_precision_t, uint32_t>;
	}
}

implementation
{
	message_t test_packet;

	event void Boot.booted()
	{
		call Packet.clear(&test_packet);
		call RadioControl.start();
		call Timer.startPeriodic(512);
	}

	event void RadioControl.startDone(error_t error) { }
	event void RadioControl.stopDone(error_t error) { }

	event void Timer.fired()
	{
		uint8_t i;

		test_msg_t *test_msg = call Packet.getPayload(&test_packet, sizeof(test_msg_t));
		history_t *history = &(test_msg->history[TOS_NODE_ID]);

		history->seqno += 1;

		if( call AMSend.send(AM_BROADCAST_ADDR, &test_packet, sizeof(test_msg_t)) != SUCCESS )
			call Leds.led0On();

		for(i = HISTORY_SIZE-1; i > 0; --i)
			history->times[i] = history->times[i-1];

		history->times[0] = 0;
	}

	event void AMSend.sendDone(message_t *msg, error_t error)
	{
		if( error == SUCCESS && msg == &test_packet && TOS_NODE_ID < NUMBER_OF_MOTES )
		{
			test_msg_t *test_msg = call Packet.getPayload(&test_packet, sizeof(test_msg_t));
			history_t *history = &(test_msg->history[TOS_NODE_ID]);

			history->times[0] = call PacketTimeStamp.isValid(&test_packet) ? 
				call PacketTimeStamp.timestamp(&test_packet) : 0;

			call Leds.led2Toggle();
		}
		else
			call Leds.led0On();

	}

	event message_t* Receive.receive(message_t *msg, void *data, uint8_t length)
	{
		uint8_t sender = call AMPacket.source(msg);

		if( sender < NUMBER_OF_MOTES && sender != TOS_NODE_ID && length == sizeof(test_msg_t) )
		{
			test_msg_t *my_test_msg = call Packet.getPayload(&test_packet, sizeof(test_msg_t));
			history_t *my_history = &(my_test_msg->history[sender]);

			test_msg_t *his_test_msg = data;
			history_t *his_history = &(his_test_msg->history[sender]);

			while( my_history->seqno != his_history->seqno )
			{
				uint8_t i;

				my_history->seqno += 1;

				for(i = HISTORY_SIZE-1; i > 0; --i)
					my_history->times[i] = my_history->times[i-1];

				my_history->times[0] = 0;
			}

			my_history->times[0] = call PacketTimeStamp.isValid(msg) ? 
				call PacketTimeStamp.timestamp(msg) : 0;

			call Leds.led1Toggle();
		}

		return msg;
	}
}
