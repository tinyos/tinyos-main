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
#include <RadioAssert.h>

module SoftwareAckLayerP
{
	provides
	{
		interface RadioSend;
		interface RadioReceive;
	}
	uses
	{
		interface RadioSend as SubSend;
		interface RadioReceive as SubReceive;
		interface RadioAlarm;

		interface SoftwareAckConfig;
	}
}

implementation
{
	tasklet_norace uint8_t state;
	enum
	{
		STATE_READY = 0,
		STATE_DATA_SEND = 1,
		STATE_ACK_WAIT = 2,
		STATE_ACK_SEND = 3,
	};

	tasklet_norace message_t *txMsg;
	tasklet_norace message_t ackMsg;

	tasklet_async event void SubSend.ready()
	{
		if( state == STATE_READY )
			signal RadioSend.ready();
	}

	tasklet_async command error_t RadioSend.send(message_t* msg)
	{
		error_t error;

		if( state == STATE_READY )
		{
			if( (error = call SubSend.send(msg)) == SUCCESS )
			{
				call SoftwareAckConfig.setAckReceived(msg, FALSE);
				state = STATE_DATA_SEND;
				txMsg = msg;
			}
		}
		else
			error = EBUSY;

		return error;
	}

	tasklet_async event void SubSend.sendDone(error_t error)
	{
		if( state == STATE_ACK_SEND )
		{
			// TODO: what if error != SUCCESS
			ASSERT( error == SUCCESS );

			state = STATE_READY;
		}
		else
		{
			ASSERT( state == STATE_DATA_SEND );
			ASSERT( call RadioAlarm.isFree() );

			if( error == SUCCESS && call SoftwareAckConfig.requiresAckWait(txMsg) && call RadioAlarm.isFree() )
			{
				call RadioAlarm.wait(call SoftwareAckConfig.getAckTimeout());
				state = STATE_ACK_WAIT;
			}
			else
			{
				state = STATE_READY;
				signal RadioSend.sendDone(error);
			}
		}
	}

	tasklet_async event void RadioAlarm.fired()
	{
		ASSERT( state == STATE_ACK_WAIT );

		call SoftwareAckConfig.reportChannelError();

		state = STATE_READY;
		signal RadioSend.sendDone(SUCCESS);	// we have sent it, but not acked
	}

	tasklet_async event bool SubReceive.header(message_t* msg)
	{
		if( call SoftwareAckConfig.isAckPacket(msg) )
			return state == STATE_ACK_WAIT && call SoftwareAckConfig.verifyAckPacket(txMsg, msg);
		else
			return signal RadioReceive.header(msg);
	}

	tasklet_async event message_t* SubReceive.receive(message_t* msg)
	{
		bool ack = call SoftwareAckConfig.isAckPacket(msg);

		ASSERT( state == STATE_ACK_WAIT || state == STATE_READY );

		if( state == STATE_ACK_WAIT )
		{
			ASSERT( !ack || call SoftwareAckConfig.verifyAckPacket(txMsg, msg) );

			call RadioAlarm.cancel();
			call SoftwareAckConfig.setAckReceived(txMsg, ack);

			state = STATE_READY;
			signal RadioSend.sendDone(SUCCESS);
		}

		if( ack )
			return msg;

		if( call SoftwareAckConfig.requiresAckReply(msg) )
		{
			call SoftwareAckConfig.createAckPacket(msg, &ackMsg);

			// TODO: what to do if we are busy and cannot send an ack
			if( call SubSend.send(&ackMsg) == SUCCESS )
				state = STATE_ACK_SEND;
			else
				ASSERT(FALSE);
		}

		return signal RadioReceive.receive(msg);
	}
}
