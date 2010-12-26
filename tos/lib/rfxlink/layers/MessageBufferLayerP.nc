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
 *         Andreas Huber <huberan@ee.ethz.ch>
 */

#include <Tasklet.h>
#include <RadioAssert.h>

generic module MessageBufferLayerP()
{
	provides
	{
		interface SplitControl;
		interface Init as SoftwareInit;

		interface BareSend as Send;
		interface BareReceive as Receive;
		interface RadioChannel;
	}
	uses
	{
		interface RadioState;
		interface Tasklet;
		interface RadioSend;
		interface RadioReceive;
	}
}

implementation
{
/*----------------- State -----------------*/

	tasklet_norace uint8_t state;
	enum
	{
		STATE_READY = 0,
		STATE_TX_PENDING = 1,
		STATE_TX_RETRY = 2,
		STATE_TX_SEND = 3,
		STATE_TX_DONE = 4,
		STATE_TURN_ON = 5,
		STATE_TURN_OFF = 6,
		STATE_CHANNEL = 7,
	};

	command error_t SplitControl.start()
	{
		error_t error;

		call Tasklet.suspend();

		if( state != STATE_READY )
			error = EBUSY;
		else
		{
			error = call RadioState.turnOn();

			if( error == SUCCESS )
				state = STATE_TURN_ON;
		}

		call Tasklet.resume();

		return error;
	}

	command error_t SplitControl.stop()
	{
		error_t error;

		call Tasklet.suspend();

		if( state != STATE_READY )
			error = EBUSY;
		else
		{
			error = call RadioState.turnOff();

			if( error == SUCCESS )
				state = STATE_TURN_OFF;
		}

		call Tasklet.resume();

		return error;
	}

	command error_t RadioChannel.setChannel(uint8_t channel)
	{
		error_t error;

		call Tasklet.suspend();

		if( state != STATE_READY )
			error = EBUSY;
		else
		{
			error = call RadioState.setChannel(channel);

			if( error == SUCCESS )
				state = STATE_CHANNEL;
		}

		call Tasklet.resume();

		return error;
	}

	command uint8_t RadioChannel.getChannel()
	{
		return call RadioState.getChannel();
	}

	task void stateDoneTask()
	{
		uint8_t s;
		
		s = state;

		// change the state before so we can be reentered from the event
		state = STATE_READY;

		if( s == STATE_TURN_ON )
			signal SplitControl.startDone(SUCCESS);
		else if( s == STATE_TURN_OFF )
			signal SplitControl.stopDone(SUCCESS);
		else if( s == STATE_CHANNEL )
			signal RadioChannel.setChannelDone();
		else	// not our event, ignore it
			state = s;
	}

	tasklet_async event void RadioState.done()
	{
		post stateDoneTask();
	}

	default event void SplitControl.startDone(error_t error)
	{
	}

	default event void SplitControl.stopDone(error_t error)
	{
	}

	default event void RadioChannel.setChannelDone()
	{
	}

/*----------------- Send -----------------*/

	message_t* txMsg;
	tasklet_norace error_t txError;
	uint8_t retries;

	// Many EBUSY replies from RadioSend are normal if the channel is cognested
	enum { MAX_RETRIES = 5 };

	task void sendTask()
	{
		bool done = FALSE;

		call Tasklet.suspend();

		RADIO_ASSERT( state == STATE_TX_PENDING || state == STATE_TX_DONE );

		if( state == STATE_TX_PENDING && ++retries <= MAX_RETRIES )
		{
			txError = call RadioSend.send(txMsg);
			if( txError == SUCCESS )
				state = STATE_TX_SEND;
			else
				state = STATE_TX_RETRY;
		}
		else
		{
			state = STATE_READY;
			done = TRUE;
		}

		call Tasklet.resume();

		if( done )
			signal Send.sendDone(txMsg, txError);
	}

	tasklet_async event void RadioSend.sendDone(error_t error)
	{
		RADIO_ASSERT( state == STATE_TX_SEND );

		txError = error;
		if( error == SUCCESS )
			state = STATE_TX_DONE;
		else
			state = STATE_TX_PENDING;

		post sendTask();
	}

	command error_t Send.send(message_t* msg)
	{
		error_t result;

		call Tasklet.suspend();

		if( state != STATE_READY )
			result = EBUSY;
		else
		{
			txMsg = msg;
			state = STATE_TX_PENDING;
			retries = 0;
			post sendTask();
			result = SUCCESS;
		}

		call Tasklet.resume();

		return result;
	}

	tasklet_async event void RadioSend.ready()
	{
		if( state == STATE_TX_RETRY )
		{
			state = STATE_TX_PENDING;
			post sendTask();
		}
	}

	tasklet_async event void Tasklet.run()
	{
	}

	command error_t Send.cancel(message_t* msg)
	{
		error_t result;

		call Tasklet.suspend();

		RADIO_ASSERT( msg == txMsg );

		if( state == STATE_TX_PENDING || state == STATE_TX_RETRY )
		{
			state = STATE_TX_DONE;
			txError = ECANCEL;
			result = SUCCESS;

			post sendTask();
		}
		else
			result = EBUSY;

		call Tasklet.resume();

		return result;
	}

/*----------------- Receive -----------------*/

	enum
	{
		RECEIVE_QUEUE_SIZE = 3,
	};

	message_t receiveQueueData[RECEIVE_QUEUE_SIZE];
	message_t* receiveQueue[RECEIVE_QUEUE_SIZE];

	uint8_t receiveQueueHead;
	uint8_t receiveQueueSize;

	command error_t SoftwareInit.init()
	{
		uint8_t i;

		for(i = 0; i < RECEIVE_QUEUE_SIZE; ++i)
			receiveQueue[i] = receiveQueueData + i;

		return SUCCESS;
	}

	tasklet_async event bool RadioReceive.header(message_t* msg)
	{
		bool notFull;

		// this prevents undeliverable messages to be acknowledged
		atomic notFull = receiveQueueSize < RECEIVE_QUEUE_SIZE;

		return notFull;
	}

	task void deliverTask()
	{
		// get rid of as many messages as possible without interveining tasks
		for(;;)
		{
			message_t* msg;

			atomic
			{
				if( receiveQueueSize == 0 )
					return;

				msg = receiveQueue[receiveQueueHead];
			}

			msg = signal Receive.receive(msg);

			atomic
			{
				receiveQueue[receiveQueueHead] = msg;

				if( ++receiveQueueHead >= RECEIVE_QUEUE_SIZE )
					receiveQueueHead = 0;

				--receiveQueueSize;
			}
		}
	}

	tasklet_async event message_t* RadioReceive.receive(message_t* msg)
	{
		message_t *m;

		atomic
		{
			if( receiveQueueSize >= RECEIVE_QUEUE_SIZE )
				m = msg;
			else
			{
				uint8_t idx = receiveQueueHead + receiveQueueSize;
				if( idx >= RECEIVE_QUEUE_SIZE )
					idx -= RECEIVE_QUEUE_SIZE;

				m = receiveQueue[idx];
				receiveQueue[idx] = msg;

				++receiveQueueSize;
				post deliverTask();
			}
		}

		return m;
	}

}
