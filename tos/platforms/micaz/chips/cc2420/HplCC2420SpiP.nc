/*
 * Copyright (c) 2005 Arch Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * Automatic slave select update for the SpiResource
 *
 * @author Miklos Maroti
 */

module HplCC2420SpiP
{
	provides interface Resource;
  
	uses
	{
		interface Resource as SubResource;	// raw SPI resource
		interface GeneralIO as SS;			// Slave set line
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
