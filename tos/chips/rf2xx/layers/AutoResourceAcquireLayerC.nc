/*
 * Copyright (c) 2009, Vanderbilt University
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

generic module AutoResourceAcquireLayerC()
{
	provides
	{
		interface BareSend;
	}

	uses
	{
		interface BareSend as SubSend;
		interface Resource;
	}
}

implementation
{
	message_t *pending;

	command error_t BareSend.send(message_t* msg)
	{
		if( call Resource.immediateRequest() == SUCCESS )
		{
			error_t result = call SubSend.send(msg);
			if( result != SUCCESS )
				call Resource.release();

			return result;
		}

		pending = msg;
		return call Resource.request();
	}

	event void Resource.granted()
	{
		error_t result = call SubSend.send(pending);
		if( result != SUCCESS )
		{
			call Resource.release();
			signal BareSend.sendDone(pending, result);
		}
	}

	event void SubSend.sendDone(message_t* msg, error_t result)
	{
		call Resource.release();
		signal BareSend.sendDone(msg, result);
	}

	command error_t BareSend.cancel(message_t* msg)
	{
		return call SubSend.cancel(msg);
	}
}
