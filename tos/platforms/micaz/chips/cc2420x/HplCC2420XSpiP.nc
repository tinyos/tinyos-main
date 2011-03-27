/*
 * Copyright (c) 2010, Vanderbilt University
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
 * Author: Janos Sallai
 */ 

module HplCC2420XSpiP @safe()
{
	provides interface Resource;
  
	uses
	{
		interface Resource as SubResource;
		interface GeneralIO as SS;
	}
}

implementation
{
	async command error_t Resource.request()
	{
		return call SubResource.request();
	}

	async command error_t Resource.immediateRequest()
	{
		error_t error = call SubResource.immediateRequest();
		if( error == SUCCESS )
		{
			call SS.makeOutput();
			call SS.clr();
		}
		return error;
	}

	event void SubResource.granted()
	{
		call SS.makeOutput();
		call SS.clr();

		signal Resource.granted();
	}
	
	async command error_t Resource.release()
	{
		if( call SubResource.isOwner() )
			call SS.set();

		return call SubResource.release();
	}

	async command bool Resource.isOwner()
	{
		return call SubResource.isOwner();
	}
}
