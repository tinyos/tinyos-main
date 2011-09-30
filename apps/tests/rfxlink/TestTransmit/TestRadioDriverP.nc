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

#include "Tasklet.h"
#include "RadioAssert.h"
#include "message.h"
#include "RadioConfig.h"

module TestRadioDriverP
{
	uses
	{
		interface Boot;
		interface SplitControl;
		interface Leds;

		interface RadioState;
		interface RadioPacket;
		interface RadioAlarm;
		interface RadioSend;
		interface RadioReceive;
	}
}

implementation
{
	tasklet_norace uint8_t failureCount;
	tasklet_norace uint8_t successCount;
	tasklet_norace uint8_t receiveCount;
	tasklet_norace uint8_t timerCount;

	message_t msgbuffer;

	event void Boot.booted()
	{
		error_t error;
		
		error = call SplitControl.start();
		RADIO_ASSERT( error == SUCCESS );
	}

	event void SplitControl.startDone(error_t error)
	{
		RADIO_ASSERT( error == SUCCESS );

		error = call RadioState.turnOn();
		RADIO_ASSERT( error == SUCCESS );
	}

	event void SplitControl.stopDone(error_t error)
	{
	}

	tasklet_async event void RadioState.done()
	{
		call RadioPacket.clear(&msgbuffer);
		call RadioPacket.setPayloadLength(&msgbuffer, 2);

		RADIO_ASSERT( call RadioAlarm.isFree() );

		call RadioAlarm.wait(1);
	}

	tasklet_norace tradio_size next;

	tasklet_async event void RadioAlarm.fired()
	{
		uint8_t *payload;
		error_t error;
		int32_t delay;

		next += SEND_INTERVAL * RADIO_ALARM_MICROSEC;
		atomic
		{
			delay = next - call RadioAlarm.getNow();
			if( delay <= 0 )
				delay = 1;
			call RadioAlarm.wait(delay);
		}
		RADIO_ASSERT( delay > 1 );

		payload = ((void*)&msgbuffer) + call RadioPacket.headerLength(&msgbuffer);

		payload[0] = TOS_NODE_ID;
		payload[1] = ++timerCount;

		error = call RadioSend.send(&msgbuffer);
		if( error != SUCCESS )
		{
			if( ++failureCount == 0 )
				call Leds.led0Toggle();
		}
		else
		{
			if( ++successCount == 0 )
				call Leds.led1Toggle();
		}
	}

	tasklet_async event void RadioSend.sendDone(error_t error)
	{
		RADIO_ASSERT( error == SUCCESS );
	}

	tasklet_async event void RadioSend.ready()
	{
	}

	tasklet_async event bool RadioReceive.header(message_t* msg)
	{
		return TRUE;
	}

	tasklet_async event message_t* RadioReceive.receive(message_t* msg)
	{
		if( ++receiveCount == 0 )
			call Leds.led2Toggle();

		return msg;
	}
}
