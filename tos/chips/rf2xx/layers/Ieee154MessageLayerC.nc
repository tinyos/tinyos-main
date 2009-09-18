/*
 * Copyright (c) 2007-2009, Vanderbilt University
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
