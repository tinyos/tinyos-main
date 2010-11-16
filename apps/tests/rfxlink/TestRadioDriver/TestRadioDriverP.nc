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

module TestRadioDriverP
{
	uses
	{
		interface Boot;
		interface SplitControl;
		interface Leds;

		interface RadioState;
		interface RadioSend;
		interface RadioPacket;
	}
}

implementation
{
	uint8_t counter;
	message_t msg;

	// we transmit 10 messages as fast as we can and turn off/on the radio
	task void next()
	{
		error_t error;

		if( counter == 0 )
		{
			error = call RadioState.turnOn();
			RADIO_ASSERT( error == SUCCESS );
		}
		else if( counter > 10 )
		{
			error = call RadioState.turnOff();
			RADIO_ASSERT( error == SUCCESS );
		}
		else
		{
			uint8_t *payload;

			call RadioPacket.clear(&msg);
			call RadioPacket.setPayloadLength(&msg, 2);
			payload = ((void*)&msg) + call RadioPacket.headerLength(&msg);

			payload[0] = TOS_NODE_ID;
			payload[1] = counter;

			error = call RadioSend.send(&msg);
			if( error != SUCCESS )
				call Leds.led0Toggle();
			else
				call Leds.led1Toggle();
		}

		// retry last operation
		if( error != SUCCESS )
			post next();
	}

	tasklet_async event void RadioState.done()
	{
		if( counter == 0 )
			counter = 1;
		else
			counter = 0;

		post next();
	}

	tasklet_async event void RadioSend.sendDone(error_t error)
	{
		RADIO_ASSERT( error == SUCCESS );

		counter += 1;
		post next();
	}

	tasklet_async event void RadioSend.ready()
	{
	}

	event void Boot.booted()
	{
		error_t error;
		
		error = call SplitControl.start();
		RADIO_ASSERT( error == SUCCESS );
	}

	event void SplitControl.startDone(error_t error)
	{
		RADIO_ASSERT( error == SUCCESS );
		
		counter = 0;
		post next();
	}

	event void SplitControl.stopDone(error_t error)
	{
	}
}
