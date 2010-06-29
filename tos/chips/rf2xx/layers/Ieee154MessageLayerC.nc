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

module Ieee154MessageLayerC
{
	provides 
	{
		interface Packet;
		interface Ieee154Send;
		interface Receive as Ieee154Receive;
		interface SendNotifier;
	}

	uses
	{
		interface Ieee154PacketLayer;
		interface Ieee154Packet;
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

		// user forgot to call Packet.clear(), maybe we should return EFAIL
		if( ! call Ieee154PacketLayer.isDataFrame(msg) )
			call Ieee154PacketLayer.createDataFrame(msg);

		call Packet.setPayloadLength(msg, len);
	    	call Ieee154Packet.setSource(msg, call Ieee154Packet.address());
		call Ieee154Packet.setDestination(msg, addr);
	    	call Ieee154Packet.setPan(msg, call Ieee154Packet.localPan());
		
    		signal SendNotifier.aboutToSend(addr, msg);
    	
    		return call SubSend.send(msg);
	}

	event void SubSend.sendDone(message_t* msg, error_t error)
	{
		signal Ieee154Send.sendDone(msg, error);
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
		if( call Ieee154Packet.isForMe(msg) )
			return signal Ieee154Receive.receive(msg,
				getPayload(msg), call Packet.payloadLength(msg));
		else
			return msg;
	}

	default event message_t* Ieee154Receive.receive(message_t* msg, void* payload, uint8_t len)
	{
		return msg;
	}
}
