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

#include <TinyosNetworkLayer.h>

/*
   If TFRAMES_ENABLED is defined, then only TinyOS frames will be supported
   (with no network byte). If IEEE154FRAMES_ENABLED, then only IEEE 802.15.4 
   frames will be supported (the network byte is part of the payload). If 
   neither is defined, then both TinyOS frames and IEEE 802.15.4 frames will
   be supported where TinyOS frames are the ones whose network byte is
   TINYOS_6LOWPAN_NETWORK_ID.
*/

#if defined(TFRAMES_ENABLED) && defined(IEEE154FRAMES_ENABLED)
#error You cannot specify both TFRAMES_ENABLED and IEEE154FRAMES_ENABLED at the same time
#endif

module TinyosNetworkLayerC
{
	provides
	{
#ifndef TFRAMES_ENABLED
		interface BareSend as Ieee154Send;
		interface BareReceive as Ieee154Receive;
		interface RadioPacket as Ieee154Packet;
#endif

#ifndef IEEE154FRAMES_ENABLED
		interface BareSend as TinyosSend;
		interface BareReceive as TinyosReceive;
		interface RadioPacket as TinyosPacket;
#endif
	}

	uses
	{
		interface BareSend as SubSend;
		interface BareReceive as SubReceive;
		interface RadioPacket as SubPacket;
	}
}

implementation
{
/*----------------- Ieee154MessageC -----------------*/

#ifndef TFRAMES_ENABLED

	command error_t Ieee154Send.send(message_t* msg)
	{
		return call SubSend.send(msg);
	}

	command error_t Ieee154Send.cancel(message_t* msg)
	{
		return call SubSend.cancel(msg);
	}
	
	async command uint8_t Ieee154Packet.headerLength(message_t* msg)
	{
		return call SubPacket.headerLength(msg);
	}

	async command uint8_t Ieee154Packet.payloadLength(message_t* msg)
	{
		return call SubPacket.payloadLength(msg);
	}

	async command void Ieee154Packet.setPayloadLength(message_t* msg, uint8_t length)
	{
		call SubPacket.setPayloadLength(msg, length);
	}

	async command uint8_t Ieee154Packet.maxPayloadLength()
	{
		return call SubPacket.maxPayloadLength();
	}

	async command uint8_t Ieee154Packet.metadataLength(message_t* msg)
	{
		return call SubPacket.metadataLength(msg);
	}

	async command void Ieee154Packet.clear(message_t* msg)
	{
		call SubPacket.clear(msg);
	}

#endif

/*----------------- ActiveMessageC -----------------*/

#ifndef IEEE154FRAMES_ENABLED

	network_header_t* getHeader(message_t* msg)
	{
		return ((void*)msg) + call SubPacket.headerLength(msg);
	}

	command error_t TinyosSend.send(message_t* msg)
	{
#ifndef TFRAMES_ENABLED
		getHeader(msg)->network = TINYOS_6LOWPAN_NETWORK_ID;
#endif
		return call SubSend.send(msg);
	}

	command error_t TinyosSend.cancel(message_t* msg)
	{
		return call SubSend.cancel(msg);
	}

	enum
	{
#ifndef TFRAMES_ENABLED
		PAYLOAD_OFFSET = sizeof(network_header_t),
#else
		PAYLOAD_OFFSET = 0,
#endif
	};

	async command uint8_t TinyosPacket.headerLength(message_t* msg)
	{
		return call SubPacket.headerLength(msg) + PAYLOAD_OFFSET;
	}

	async command uint8_t TinyosPacket.payloadLength(message_t* msg)
	{
		return call SubPacket.payloadLength(msg) - PAYLOAD_OFFSET;
	}

	async command void TinyosPacket.setPayloadLength(message_t* msg, uint8_t length)
	{
		call SubPacket.setPayloadLength(msg, length + PAYLOAD_OFFSET);
	}

	async command uint8_t TinyosPacket.maxPayloadLength()
	{
		return call SubPacket.maxPayloadLength() - PAYLOAD_OFFSET;
	}

	async command uint8_t TinyosPacket.metadataLength(message_t* msg)
	{
		return call SubPacket.metadataLength(msg);
	}

	async command void TinyosPacket.clear(message_t* msg)
	{
		call SubPacket.clear(msg);
	}

#endif

/*----------------- Events -----------------*/

#if defined(TFRAMES_ENABLED)

	event void SubSend.sendDone(message_t* msg, error_t result)
	{
		signal TinyosSend.sendDone(msg, result);
	}

	event message_t* SubReceive.receive(message_t* msg)
	{
		return signal TinyosReceive.receive(msg);
	}

#elif defined(IEEE154FRAMES_ENABLED)

	event void SubSend.sendDone(message_t* msg, error_t result)
	{
		signal Ieee154Send.sendDone(msg, result);
	}

	event message_t* SubReceive.receive(message_t* msg)
	{
		return signal Ieee154Receive.receive(msg);
	}

#else

	event void SubSend.sendDone(message_t* msg, error_t result)
	{
		if( getHeader(msg)->network == TINYOS_6LOWPAN_NETWORK_ID )
			signal TinyosSend.sendDone(msg, result);
		else
			signal Ieee154Send.sendDone(msg, result);
	}

	event message_t* SubReceive.receive(message_t* msg)
	{
		if( getHeader(msg)->network == TINYOS_6LOWPAN_NETWORK_ID )
			return signal TinyosReceive.receive(msg);
		else
			return signal Ieee154Receive.receive(msg);
	}

#endif
}
