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

module CsmaLayerP
{
	provides
	{
		interface RadioSend;
	}

	uses
	{
		interface CsmaConfig as Config;

		interface RadioSend as SubSend;
		interface RadioCCA as SubCCA;
	}
}

implementation
{
	tasklet_norace message_t *txMsg;

	tasklet_norace uint8_t state;
	enum
	{
		STATE_READY = 0,
		STATE_CCA_WAIT = 1,
		STATE_SEND = 2,
	};

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
			if( call Config.requiresSoftwareCCA(msg) )
			{
				txMsg = msg;

				if( (error = call SubCCA.request()) == SUCCESS )
					state = STATE_CCA_WAIT;
			}
			else if( (error = call SubSend.send(msg)) == SUCCESS )
				state = STATE_SEND;
		}
		else
			error = EBUSY;

		return error;
	}

	tasklet_async event void SubCCA.done(error_t error)
	{
		ASSERT( state == STATE_CCA_WAIT );

		if( error == SUCCESS && (error = call SubSend.send(txMsg)) == SUCCESS )
			state = STATE_SEND;
		else
		{
			state = STATE_READY;
			signal RadioSend.sendDone(EBUSY);
		}
	}

	tasklet_async event void SubSend.sendDone(error_t error)
	{
		ASSERT( state == STATE_SEND );

		state = STATE_READY;
		signal RadioSend.sendDone(error);
	}
}
