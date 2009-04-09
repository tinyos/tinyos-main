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

module MessageBufferLayerP
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

	norace uint8_t state;	// written only from tasks
	enum
	{
		STATE_READY = 0,
		STATE_TX_PENDING = 1,
		STATE_TX_SEND = 2,
		STATE_TX_DONE = 3,
		STATE_TURN_ON = 4,
		STATE_TURN_OFF = 5,
		STATE_CHANNEL = 6,
	};

	command error_t SplitControl.start()
	{
		error_t error;

		call Tasklet.suspend();

		if( state != STATE_READY )
			error = EBUSY;
		else
			error = call RadioState.turnOn();

		if( error == SUCCESS )
			state = STATE_TURN_ON;

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
			error = call RadioState.turnOff();

		if( error == SUCCESS )
			state = STATE_TURN_OFF;

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
			error = call RadioState.setChannel(channel);

		if( error == SUCCESS )
			state = STATE_CHANNEL;

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
	error_t txError;
	uint8_t retries;

	// Many EBUSY replies from RadioSend are normal if the channel is cognested
	enum { MAX_RETRIES = 5 };

	task void sendTask()
	{
		error_t error;

		ASSERT( state == STATE_TX_PENDING || state == STATE_TX_SEND );

		atomic error = txError;
		if( (state == STATE_TX_SEND && error == SUCCESS) || ++retries > MAX_RETRIES )
			state = STATE_TX_DONE;
		else
		{
			call Tasklet.suspend();

			error = call RadioSend.send(txMsg);
			if( error == SUCCESS )
				state = STATE_TX_SEND;
			else if( retries == MAX_RETRIES )
				state = STATE_TX_DONE;
			else
				state = STATE_TX_PENDING;

			call Tasklet.resume();
		}

		if( state == STATE_TX_DONE )
		{
			state = STATE_READY;
			signal Send.sendDone(txMsg, error);
		}
	}

	tasklet_async event void RadioSend.sendDone(error_t error)
	{
		ASSERT( state == STATE_TX_SEND );

		atomic txError = error;
		post sendTask();
	}

	command error_t Send.send(message_t* msg)
	{
		if( state != STATE_READY )
			return EBUSY;

		txMsg = msg;
		state = STATE_TX_PENDING;
		retries = 0;
		post sendTask();

		return SUCCESS;
	}

	tasklet_async event void RadioSend.ready()
	{
		if( state == STATE_TX_PENDING )
			post sendTask();
	}

	tasklet_async event void Tasklet.run()
	{
	}

	command error_t Send.cancel(message_t* msg)
	{
		if( state == STATE_TX_PENDING )
		{
			state = STATE_READY;

			// TODO: check if sendDone can be called before cancel returns
			signal Send.sendDone(msg, ECANCEL);

			return SUCCESS;
		}
		else
			return FAIL;
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
				uint8_t index = receiveQueueHead + receiveQueueSize;
				if( index >= RECEIVE_QUEUE_SIZE )
					index -= RECEIVE_QUEUE_SIZE;

				m = receiveQueue[index];
				receiveQueue[index] = msg;

				++receiveQueueSize;
				post deliverTask();
			}
		}

		return m;
	}

}
