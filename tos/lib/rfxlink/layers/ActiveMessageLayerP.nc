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
 * Author: Chieh-Jan Mike Liang (default interfaces for TOSThreads)
 */

#include <ActiveMessageLayer.h>

generic module ActiveMessageLayerP()
{
	provides
	{
		interface RadioPacket;
		interface AMPacket;
		interface Packet;
		interface AMSend[am_id_t id];
		interface Receive[am_id_t id];
		interface Receive as Snoop[am_id_t id];	
		interface SendNotifier[am_id_t id];

		// for TOSThreads
		interface Receive as ReceiveDefault[am_id_t id];
		interface Receive as SnoopDefault[am_id_t id];
	}

	uses
	{
		interface RadioPacket as SubPacket;
		interface BareSend as SubSend;
		interface BareReceive as SubReceive;
		interface ActiveMessageConfig as Config;
		interface ActiveMessageAddress;
	}
}

implementation
{
	activemessage_header_t* getHeader(message_t* msg)
	{
		return ((void*)msg) + call SubPacket.headerLength(msg);
	}

	void* getPayload(message_t* msg)
	{
		return ((void*)msg) + call RadioPacket.headerLength(msg);
	}

/*----------------- Send -----------------*/

	command error_t AMSend.send[am_id_t id](am_addr_t addr, message_t* msg, uint8_t len)
	{
		if( len > call Packet.maxPayloadLength() )
			return EINVAL;

		if( call Config.checkFrame(msg) != SUCCESS )
			return FAIL;

		call Packet.setPayloadLength(msg, len);
		call AMPacket.setSource(msg, call AMPacket.address());
		call AMPacket.setGroup(msg, call AMPacket.localGroup());
		call AMPacket.setType(msg, id);
		call AMPacket.setDestination(msg, addr);

		signal SendNotifier.aboutToSend[id](addr, msg);

		return call SubSend.send(msg);
	}

	inline event void SubSend.sendDone(message_t* msg, error_t error)
	{
		signal AMSend.sendDone[call AMPacket.type(msg)](msg, error);
	}

	inline command error_t AMSend.cancel[am_id_t id](message_t* msg)
	{
		return call SubSend.cancel(msg);
	}

	default event void AMSend.sendDone[am_id_t id](message_t* msg, error_t error)
	{
	}

	inline command uint8_t AMSend.maxPayloadLength[am_id_t id]()
	{
		return call Packet.maxPayloadLength();
	}

	inline command void* AMSend.getPayload[am_id_t id](message_t* msg, uint8_t len)
	{
		return call Packet.getPayload(msg, len);
	}

	default event void SendNotifier.aboutToSend[am_id_t id](am_addr_t addr, message_t* msg)
	{
	}

/*----------------- Receive -----------------*/

	event message_t* SubReceive.receive(message_t* msg)
	{
		am_id_t id = call AMPacket.type(msg);
		void* payload = getPayload(msg);
		uint8_t len = call Packet.payloadLength(msg);

		msg = call AMPacket.isForMe(msg) 
			? signal Receive.receive[id](msg, payload, len)
			: signal Snoop.receive[id](msg, payload, len);

		return msg;
	}

	default event message_t* Receive.receive[am_id_t id](message_t* msg, void* payload, uint8_t len)
	{
		return signal ReceiveDefault.receive[id](msg, payload, len);;
	}

	default event message_t* ReceiveDefault.receive[am_id_t id](message_t* msg, void* payload, uint8_t len)
	{
		return msg;
	}

	default event message_t* Snoop.receive[am_id_t id](message_t* msg, void* payload, uint8_t len)
	{
		return signal SnoopDefault.receive[id](msg, payload, len);;
	}

	default event message_t* SnoopDefault.receive[am_id_t id](message_t* msg, void* payload, uint8_t len)
	{
		return msg;
	}

/*----------------- AMPacket -----------------*/

	inline command am_addr_t AMPacket.address()
	{
		return call ActiveMessageAddress.amAddress();
	}
 
	inline command am_group_t AMPacket.localGroup()
	{
		return call ActiveMessageAddress.amGroup();
	}

	inline command bool AMPacket.isForMe(message_t* msg)
	{
		am_addr_t addr = call AMPacket.destination(msg);
		return addr == call AMPacket.address() || addr == AM_BROADCAST_ADDR;
	}

	inline command am_addr_t AMPacket.destination(message_t* msg)
	{
		return call Config.destination(msg);
	}
 
	inline command void AMPacket.setDestination(message_t* msg, am_addr_t addr)
	{
		call Config.setDestination(msg, addr);
	}

	inline command am_addr_t AMPacket.source(message_t* msg)
	{
		return call Config.source(msg);
	}

	inline command void AMPacket.setSource(message_t* msg, am_addr_t addr)
	{
		call Config.setSource(msg, addr);
	}

	inline command am_id_t AMPacket.type(message_t* msg)
	{
		return getHeader(msg)->type;
	}

	inline command void AMPacket.setType(message_t* msg, am_id_t type)
	{
		getHeader(msg)->type = type;
	}
  
	inline command am_group_t AMPacket.group(message_t* msg) 
	{
		return call Config.group(msg);
	}

	inline command void AMPacket.setGroup(message_t* msg, am_group_t grp)
	{
		call Config.setGroup(msg, grp);
	}

	inline async event void ActiveMessageAddress.changed()
	{
	}

/*----------------- RadioPacket -----------------*/

	async command uint8_t RadioPacket.headerLength(message_t* msg)
	{
		return call SubPacket.headerLength(msg) + sizeof(activemessage_header_t);
	}

	async command uint8_t RadioPacket.payloadLength(message_t* msg)
	{
		return call SubPacket.payloadLength(msg) - sizeof(activemessage_header_t);
	}

	async command void RadioPacket.setPayloadLength(message_t* msg, uint8_t length)
	{
		call SubPacket.setPayloadLength(msg, length + sizeof(activemessage_header_t));
	}

	async command uint8_t RadioPacket.maxPayloadLength()
	{
		return call SubPacket.maxPayloadLength() - sizeof(activemessage_header_t);
	}

	async command uint8_t RadioPacket.metadataLength(message_t* msg)
	{
		return call SubPacket.metadataLength(msg);
	}

	async command void RadioPacket.clear(message_t* msg)
	{
		call SubPacket.clear(msg);
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

		return ((void*)msg) + call RadioPacket.headerLength(msg);
	}
}
