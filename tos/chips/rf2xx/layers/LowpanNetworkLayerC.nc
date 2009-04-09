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

#include <LowpanNetworkLayer.h>

module LowpanNetworkLayerC
{
	provides
	{
		interface BareSend as Send;
		interface BareReceive as Receive;
		interface RadioPacket;

		interface Receive as NonTinyosReceive[uint8_t network];
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
	lowpan_header_t* getHeader(message_t* msg)
	{
		return ((void*)msg) + call SubPacket.headerLength(msg);
	}

	void* getPayload(message_t* msg)
	{
		return ((void*)msg) + call RadioPacket.headerLength(msg);
	}

#ifndef TINYOS_6LOWPAN_NETWORK_ID
#define TINYOS_6LOWPAN_NETWORK_ID 0x3f
#endif

	command error_t Send.send(message_t* msg)
	{
		getHeader(msg)->network = TINYOS_6LOWPAN_NETWORK_ID;
		return call SubSend.send(msg);
	}

	command error_t Send.cancel(message_t* msg)
	{
		return call SubSend.cancel(msg);
	}

	event void SubSend.sendDone(message_t* msg, error_t error)
	{
		signal Send.sendDone(msg, error);
	}
  
	event message_t *SubReceive.receive(message_t *msg)
	{
		uint8_t network = getHeader(msg)->network;
		if( network == TINYOS_6LOWPAN_NETWORK_ID )
			return signal Receive.receive(msg);
		else
			return signal NonTinyosReceive.receive[network](msg, 
				getPayload(msg), call RadioPacket.payloadLength(msg));
	}

	default event message_t *NonTinyosReceive.receive[uint8_t network](message_t *msg, void *payload, uint8_t len)
	{
		return msg;
	}

/*----------------- RadioPacket -----------------*/

	async command uint8_t RadioPacket.headerLength(message_t* msg)
	{
		return call SubPacket.headerLength(msg) + sizeof(lowpan_header_t);
	}

	async command uint8_t RadioPacket.payloadLength(message_t* msg)
	{
		return call SubPacket.payloadLength(msg) - sizeof(lowpan_header_t);
	}

	async command void RadioPacket.setPayloadLength(message_t* msg, uint8_t length)
	{
		call SubPacket.setPayloadLength(msg, length + sizeof(lowpan_header_t));
	}

	async command uint8_t RadioPacket.maxPayloadLength()
	{
		return call SubPacket.maxPayloadLength() - sizeof(lowpan_header_t);
	}

	async command uint8_t RadioPacket.metadataLength(message_t* msg)
	{
		return call SubPacket.metadataLength(msg);
	}

	async command void RadioPacket.clear(message_t* msg)
	{
		call SubPacket.clear(msg);
	}
}
