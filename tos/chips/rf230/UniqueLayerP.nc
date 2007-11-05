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

#include <Tasklet.h>
#include <Neighborhood.h>

module UniqueLayerP
{
	provides
	{
		interface Send;
		interface RadioReceive;

		interface Init;
	}

	uses
	{
		interface Send as SubSend;
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

	command error_t Send.send(message_t* msg, uint8_t len)
	{
		call UniqueConfig.setSequenceNumber(msg, ++sequenceNumber);
		return call SubSend.send(msg, len);
	}

	command error_t Send.cancel(message_t* msg)
	{
		return call SubSend.cancel(msg);
	}

	event void SubSend.sendDone(message_t* msg, error_t error)
	{
		signal Send.sendDone(msg, error);
	}

	command uint8_t Send.maxPayloadLength()
	{
		return call SubSend.maxPayloadLength();
	}

	command void* Send.getPayload(message_t* msg, uint8_t len)
	{
		return call SubSend.getPayload(msg, len);
	}

	tasklet_async event bool SubReceive.header(message_t* msg)
	{
		// we could scan here, but better be lazy
		return signal RadioReceive.header(msg);
	}

	tasklet_norace uint8_t receivedNumbers[NEIGHBORHOOD_SIZE];

	tasklet_async event message_t* SubReceive.receive(message_t* msg)
	{
		uint8_t index = call Neighborhood.insertNode(call UniqueConfig.getSender(msg));
		uint8_t dsn = call UniqueConfig.getSequenceNumber(msg);

		if( call NeighborhoodFlag.get(index) )
		{
			uint8_t diff = dsn - receivedNumbers[index];

			if( diff == 0 )
			{
				call UniqueConfig.reportChannelError();
				return msg;
			}
		}
		else
			call NeighborhoodFlag.set(index);

		receivedNumbers[index] = dsn;

		return signal RadioReceive.receive(msg);
	}

	tasklet_async event void Neighborhood.evicted(uint8_t index) { }
}
