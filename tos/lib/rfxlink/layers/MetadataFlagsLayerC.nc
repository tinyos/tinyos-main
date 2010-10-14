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

#include <MetadataFlagsLayer.h>
#include <RadioAssert.h>

module MetadataFlagsLayerC
{
	provides 
	{
		interface PacketFlag[uint8_t bit];
		interface RadioPacket;
	}

	uses
	{
		interface RadioPacket as SubPacket;
	}
}

implementation
{
	flags_metadata_t* getMeta(message_t* msg)
	{
		return ((void*)msg) + sizeof(message_t) - call RadioPacket.metadataLength(msg);
	}

/*----------------- RadioPacket -----------------*/

	async command bool PacketFlag.get[uint8_t bit](message_t* msg)
	{
		return getMeta(msg)->flags & (1<<bit);
	}

	async command void PacketFlag.set[uint8_t bit](message_t* msg)
	{
		ASSERT( bit  < 8 );

		getMeta(msg)->flags |= (1<<bit);
	}

	async command void PacketFlag.clear[uint8_t bit](message_t* msg)
	{
		ASSERT( bit  < 8 );

		getMeta(msg)->flags &= ~(1<<bit);
	}

	async command void PacketFlag.setValue[uint8_t bit](message_t* msg, bool value)
	{
		if( value )
			call PacketFlag.set[bit](msg);
		else
			call PacketFlag.clear[bit](msg);
	}

/*----------------- RadioPacket -----------------*/
	
	async command uint8_t RadioPacket.headerLength(message_t* msg)
	{
		return call SubPacket.headerLength(msg);
	}

	async command uint8_t RadioPacket.payloadLength(message_t* msg)
	{
		return call SubPacket.payloadLength(msg);
	}

	async command void RadioPacket.setPayloadLength(message_t* msg, uint8_t length)
	{
		call SubPacket.setPayloadLength(msg, length);
	}

	async command uint8_t RadioPacket.maxPayloadLength()
	{
		return call SubPacket.maxPayloadLength();
	}

	async command uint8_t RadioPacket.metadataLength(message_t* msg)
	{
		return call SubPacket.metadataLength(msg) + sizeof(flags_metadata_t);
	}

	async command void RadioPacket.clear(message_t* msg)
	{
		getMeta(msg)->flags = 0;
		call SubPacket.clear(msg);
	}
}
