/*
 * Copyright (c) 2007-2009, Vanderbilt University
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
#include <Ieee154PacketLayer.h>

generic module Ieee154MessageLayerC()
{
	provides 
	{
		interface Packet;
		interface Ieee154Packet;
		interface Ieee154Send;
		interface Receive as Ieee154Receive;

		interface SendNotifier;

		interface Send as BareSend;
		interface Receive as BareReceive;
		interface Packet as BarePacket;
	}

	uses
	{
		interface Ieee154PacketLayer;
		interface RadioPacket;
		interface BareSend as SubSend;
		interface BareReceive as SubReceive;
	}
}

implementation
{
	void* getPayload(message_t* msg)
	{
		return ((void*)msg) + call RadioPacket.headerLength(msg);
	}

/*----------------- Packet -----------------*/

	command void Packet.clear(message_t* msg)
	{
		call RadioPacket.clear(msg);
	}

	command uint8_t Packet.payloadLength(message_t* msg)
	{
		return call RadioPacket.payloadLength(msg);
	}

	command void Packet.setPayloadLength(message_t* msg, uint8_t len)
	{
		call RadioPacket.setPayloadLength(msg, len);
	}

	command uint8_t Packet.maxPayloadLength()
	{
		return call RadioPacket.maxPayloadLength();
	}

	command void* Packet.getPayload(message_t* msg, uint8_t len)
	{
		if( len > call RadioPacket.maxPayloadLength() )
			return NULL;

		return getPayload(msg);
	}

/*----------------- Ieee154Packet -----------------*/

	command ieee154_saddr_t Ieee154Packet.address()
	{
		return call Ieee154PacketLayer.localAddr();
	}
 
	command ieee154_saddr_t Ieee154Packet.destination(message_t* msg)
	{
		return call Ieee154PacketLayer.getDestAddr(msg);
	}
 
	command ieee154_saddr_t Ieee154Packet.source(message_t* msg)
	{
		return call Ieee154PacketLayer.getSrcAddr(msg);
	}

	command void Ieee154Packet.setDestination(message_t* msg, ieee154_saddr_t addr)
	{
		call Ieee154PacketLayer.setDestAddr(msg, addr);
	}

	command void Ieee154Packet.setSource(message_t* msg, ieee154_saddr_t addr)
	{
		call Ieee154PacketLayer.setSrcAddr(msg, addr);
	}

	command bool Ieee154Packet.isForMe(message_t* msg)
	{
		return call Ieee154PacketLayer.isForMe(msg);
	}

	command ieee154_panid_t Ieee154Packet.pan(message_t* msg)
	{
		return call Ieee154PacketLayer.getDestPan(msg);
	}

	command void Ieee154Packet.setPan(message_t* msg, ieee154_panid_t grp)
	{
		call Ieee154PacketLayer.setDestPan(msg, grp);
	}

	command ieee154_panid_t Ieee154Packet.localPan()
	{
		return call Ieee154PacketLayer.localPan();
	}

/*----------------- Ieee154Send -----------------*/

	command void * Ieee154Send.getPayload(message_t* msg, uint8_t len)
	{
		return call Packet.getPayload(msg, len);
	}

	command uint8_t Ieee154Send.maxPayloadLength()
	{
		return call Packet.maxPayloadLength();
	}

	command error_t Ieee154Send.cancel(message_t* msg)
	{
		return call SubSend.cancel(msg);
	}

	command error_t Ieee154Send.send(ieee154_saddr_t addr, message_t* msg, uint8_t len)
	{
		if( len > call Packet.maxPayloadLength() )
			return EINVAL;

		// user forgot to call Packet.clear(), maybe we should return FAIL
		if( ! call Ieee154PacketLayer.isDataFrame(msg) )
			call Ieee154PacketLayer.createDataFrame(msg);

		call Packet.setPayloadLength(msg, len);
	    	call Ieee154PacketLayer.setSrcAddr(msg, call Ieee154PacketLayer.localAddr());
		call Ieee154PacketLayer.setDestAddr(msg, addr);
	    	call Ieee154PacketLayer.setDestPan(msg, call Ieee154PacketLayer.localPan());
		
    		signal SendNotifier.aboutToSend(addr, msg);
    	
    		return call SubSend.send(msg);
	}

	event void SubSend.sendDone(message_t* msg, error_t error)
	{
		// This is a hack to call both, but both should not be used simultaneously
		signal Ieee154Send.sendDone(msg, error);
		signal BareSend.sendDone(msg, error);
	}

	default event void Ieee154Send.sendDone(message_t* msg, error_t error)
	{
	}

	default event void SendNotifier.aboutToSend(am_addr_t addr, message_t* msg)
	{
	}

/*----------------- Receive -----------------*/

	event message_t* SubReceive.receive(message_t* msg)
	{
		if( call Ieee154PacketLayer.isForMe(msg) )
			return signal Ieee154Receive.receive(msg,
				getPayload(msg), call Packet.payloadLength(msg));
		else
			return msg;
	}

/*----------------- BarePacket -----------------*/

	typedef nx_struct ieee154_header_t
	{
		nx_uint8_t length;
		ieee154_simple_header_t ieee154;
#ifndef TFRAMES_ENABLED
		network_header_t network;
#endif
	} ieee154_header_t;

	command void BarePacket.clear(message_t* msg)
	{
		// to clear flags
		call RadioPacket.clear(msg);
	}

	command uint8_t BarePacket.payloadLength(message_t* msg)
	{
		return call RadioPacket.payloadLength(msg)
			+ sizeof(ieee154_header_t);
	}

	command void BarePacket.setPayloadLength(message_t* msg, uint8_t len)
	{
		call RadioPacket.setPayloadLength(msg, 
			len - sizeof(ieee154_header_t));
	}

	command uint8_t BarePacket.maxPayloadLength()
	{
		return call RadioPacket.maxPayloadLength()
			+ sizeof(ieee154_header_t);
	}

	command void* BarePacket.getPayload(message_t* msg, uint8_t len)
	{
		if( len > call RadioPacket.maxPayloadLength() )
			return NULL;

		return getPayload(msg) - sizeof(ieee154_header_t);
	}

/*----------------- BareSend -----------------*/

	command error_t BareSend.send(message_t* msg, uint8_t len)
	{
		call BarePacket.setPayloadLength(msg, len);
		return call SubSend.send(msg);
	}

	command error_t BareSend.cancel(message_t* msg)
	{
		return call SubSend.cancel(msg);
	}

	command uint8_t BareSend.maxPayloadLength()
	{
		return call BarePacket.maxPayloadLength();
	}

	command void* BareSend.getPayload(message_t* msg, uint8_t len)
	{
		return call BarePacket.getPayload(msg, len);
	}

	default event void BareSend.sendDone(message_t* msg, error_t error)
	{
	}

/*----------------- BareReceive -----------------*/

	default event message_t* Ieee154Receive.receive(message_t* msg, void* payload, uint8_t len)
	{
		return signal BareReceive.receive(msg, payload - sizeof(ieee154_header_t),
			len + sizeof(ieee154_header_t));
	}

	default event message_t* BareReceive.receive(message_t *msg, void *payload, uint8_t len)
	{
		return msg;
	}
}
