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

#include <Tasklet.h>

generic module UniqueLayerP(uint8_t neigborhoodSize)
{
	provides
	{
		interface BareSend as Send;
		interface RadioReceive;

		interface Init;
	}

	uses
	{
		interface BareSend as SubSend;
		interface RadioReceive as SubReceive;

		interface UniqueConfig;
		interface Neighborhood;
		interface NeighborhoodFlag;
	}
}

implementation
{
	uint8_t sequenceNumber;

	command error_t Init.init()
	{
		sequenceNumber = TOS_NODE_ID << 4;
		return SUCCESS;
	}

	command error_t Send.send(message_t* msg)
	{
		call UniqueConfig.setSequenceNumber(msg, ++sequenceNumber);
		return call SubSend.send(msg);
	}

	command error_t Send.cancel(message_t* msg)
	{
		return call SubSend.cancel(msg);
	}

	event void SubSend.sendDone(message_t* msg, error_t error)
	{
		signal Send.sendDone(msg, error);
	}

	tasklet_async event bool SubReceive.header(message_t* msg)
	{
		// we could scan here, but better be lazy
		return signal RadioReceive.header(msg);
	}

	tasklet_norace uint8_t receivedNumbers[neigborhoodSize];

	tasklet_async event message_t* SubReceive.receive(message_t* msg)
	{
		uint8_t idx = call Neighborhood.insertNode(call UniqueConfig.getSender(msg));
		uint8_t dsn = call UniqueConfig.getSequenceNumber(msg);

		if( call NeighborhoodFlag.get(idx) )
		{
			uint8_t diff = dsn - receivedNumbers[idx];

			if( diff == 0 )
			{
				call UniqueConfig.reportChannelError();
				return msg;
			}
		}
		else
			call NeighborhoodFlag.set(idx);

		receivedNumbers[idx] = dsn;

		return signal RadioReceive.receive(msg);
	}

	tasklet_async event void Neighborhood.evicted(uint8_t idx) { }
}
