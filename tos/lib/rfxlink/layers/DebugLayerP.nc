/*
 * Copyright (c) 2011, University of Szeged
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

generic module DebugLayerP(char prefix[])
{
	provides
	{
		interface RadioState;
		interface RadioSend;
		interface RadioReceive;
	}

	uses 
	{
		interface RadioState as SubState;
		interface RadioSend as SubSend;
		interface RadioReceive as SubReceive;

		interface DiagMsg;
	}
}

implementation
{
// ------- RadioState

	tasklet_async command error_t RadioState.turnOff()
	{
		error_t error = call SubState.turnOff();

		if( call DiagMsg.record() )
		{
			call DiagMsg.str(prefix);
			call DiagMsg.str("turnOff");
			call DiagMsg.uint8(error);
			call DiagMsg.send();
		}

		return error;
	}

	tasklet_async command error_t RadioState.standby()
	{
		error_t error = call SubState.standby();

		if( call DiagMsg.record() )
		{
			call DiagMsg.str(prefix);
			call DiagMsg.str("standby");
			call DiagMsg.uint8(error);
			call DiagMsg.send();
		}

		return error;
	}

	tasklet_async command error_t RadioState.turnOn()
	{
		error_t error = call SubState.turnOn();

		if( call DiagMsg.record() )
		{
			call DiagMsg.str(prefix);
			call DiagMsg.str("turnOn");
			call DiagMsg.uint8(error);
			call DiagMsg.send();
		}

		return error;
	}

	tasklet_async command error_t RadioState.setChannel(uint8_t channel)
	{
		error_t error = call SubState.setChannel(channel);

		if( call DiagMsg.record() )
		{
			call DiagMsg.str(prefix);
			call DiagMsg.str("setChannel");
			call DiagMsg.uint8(channel);
			call DiagMsg.uint8(error);
			call DiagMsg.send();
		}

		return error;
	}

	tasklet_async event void SubState.done()
	{
		if( call DiagMsg.record() )
		{
			call DiagMsg.str(prefix);
			call DiagMsg.str("done");
			call DiagMsg.send();
		}

		signal RadioState.done();
	}

	tasklet_async command uint8_t RadioState.getChannel()
	{
		return call SubState.getChannel();
	}

// ------- RadioSend

	tasklet_async command error_t RadioSend.send(message_t* msg)
	{
		error_t error = call SubSend.send(msg);

		if( call DiagMsg.record() )
		{
			call DiagMsg.str(prefix);
			call DiagMsg.str("send");
			call DiagMsg.hex16((uint16_t)msg);
			call DiagMsg.uint8(error);
			call DiagMsg.send();
		}

		return error;
	}
	
	tasklet_async event void SubSend.sendDone(error_t error)
	{
		if( call DiagMsg.record() )
		{
			call DiagMsg.str(prefix);
			call DiagMsg.str("sendDone");
			call DiagMsg.uint8(error);
			call DiagMsg.send();
		}

		signal RadioSend.sendDone(error);
	}

	tasklet_async event void SubSend.ready()
	{
		if( call DiagMsg.record() )
		{
			call DiagMsg.str(prefix);
			call DiagMsg.str("ready");
			call DiagMsg.send();
		}

		signal RadioSend.ready();
	}

// ------- RadioReceive

	tasklet_async event bool SubReceive.header(message_t* msg)
	{
		signal RadioReceive.header(msg);
	}

	tasklet_async event message_t* SubReceive.receive(message_t* msg)
	{
		message_t* msg2 = signal RadioReceive.receive(msg);

		if( call DiagMsg.record() )
		{
			call DiagMsg.str(prefix);
			call DiagMsg.str("receive");
			call DiagMsg.hex16((uint16_t)msg);
			call DiagMsg.hex16((uint16_t)msg2);
			call DiagMsg.send();
		}
	}

}
