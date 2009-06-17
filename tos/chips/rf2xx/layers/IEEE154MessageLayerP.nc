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

#include <IEEE154MessageLayer.h>

module IEEE154MessageLayerP
{
	provides 
	{
		interface IEEE154MessageLayer;
		interface RadioPacket;
		interface Ieee154Packet;
		interface Packet;
		interface Ieee154Send;
		interface BareSend as Send;
		interface Receive as Ieee154Receive;
		interface SendNotifier;
	}

	uses
	{
		interface ActiveMessageAddress;
		interface RadioPacket as SubPacket;
		interface BareSend as SubSend;
		interface BareReceive as SubReceive;
	}
}

implementation
{
/*----------------- IEEE154Message -----------------*/

	enum
	{
		IEEE154_DATA_FRAME_MASK = (IEEE154_TYPE_MASK << IEEE154_FCF_FRAME_TYPE) 
			| (1 << IEEE154_FCF_INTRAPAN) 
			| (IEEE154_ADDR_MASK << IEEE154_FCF_DEST_ADDR_MODE) 
			| (IEEE154_ADDR_MASK << IEEE154_FCF_SRC_ADDR_MODE),

		IEEE154_DATA_FRAME_VALUE = (IEEE154_TYPE_DATA << IEEE154_FCF_FRAME_TYPE) 
			| (1 << IEEE154_FCF_INTRAPAN) 
			| (IEEE154_ADDR_SHORT << IEEE154_FCF_DEST_ADDR_MODE) 
			| (IEEE154_ADDR_SHORT << IEEE154_FCF_SRC_ADDR_MODE),

		IEEE154_ACK_FRAME_LENGTH = 3,	// includes the FCF, DSN
		IEEE154_ACK_FRAME_MASK = (IEEE154_TYPE_MASK << IEEE154_FCF_FRAME_TYPE), 
		IEEE154_ACK_FRAME_VALUE = (IEEE154_TYPE_ACK << IEEE154_FCF_FRAME_TYPE),
	};

	ieee154_header_t* getHeader(message_t* msg)
	{
		return ((void*)msg) + call SubPacket.headerLength(msg);
	}

	void* getPayload(message_t* msg)
	{
		return ((void*)msg) + call RadioPacket.headerLength(msg);
	}

	async command uint16_t IEEE154MessageLayer.getFCF(message_t* msg)
	{
		return getHeader(msg)->fcf;
	}

	async command void IEEE154MessageLayer.setFCF(message_t* msg, uint16_t fcf)
	{
		getHeader(msg)->fcf = fcf;
	}

	async command bool IEEE154MessageLayer.isDataFrame(message_t* msg)
	{
		return (getHeader(msg)->fcf & IEEE154_DATA_FRAME_MASK) == IEEE154_DATA_FRAME_VALUE;
	}

	async command void IEEE154MessageLayer.createDataFrame(message_t* msg)
	{
		getHeader(msg)->fcf = IEEE154_DATA_FRAME_VALUE;
	}

	async command bool IEEE154MessageLayer.isAckFrame(message_t* msg)
	{
		return (getHeader(msg)->fcf & IEEE154_ACK_FRAME_MASK) == IEEE154_ACK_FRAME_VALUE;
	}

	async command void IEEE154MessageLayer.createAckFrame(message_t* msg)
	{
		call SubPacket.setPayloadLength(msg, IEEE154_ACK_FRAME_LENGTH);
		getHeader(msg)->fcf = IEEE154_ACK_FRAME_VALUE;
	}

	async command void IEEE154MessageLayer.createAckReply(message_t* data, message_t* ack)
	{
		ieee154_header_t* header = getHeader(ack);
		call SubPacket.setPayloadLength(ack, IEEE154_ACK_FRAME_LENGTH);

		header->fcf = IEEE154_ACK_FRAME_VALUE;
		header->dsn = getHeader(data)->dsn;
	}

	async command bool IEEE154MessageLayer.verifyAckReply(message_t* data, message_t* ack)
	{
		ieee154_header_t* header = getHeader(ack);

		return header->dsn == getHeader(data)->dsn
			&& (header->fcf & IEEE154_ACK_FRAME_MASK) == IEEE154_ACK_FRAME_VALUE;
	}

	async command bool IEEE154MessageLayer.getAckRequired(message_t* msg)
	{
		return getHeader(msg)->fcf & (1 << IEEE154_FCF_ACK_REQ);
	}

	async command void IEEE154MessageLayer.setAckRequired(message_t* msg, bool ack)
	{
		if( ack )
			getHeader(msg)->fcf |= (1 << IEEE154_FCF_ACK_REQ);
		else
			getHeader(msg)->fcf &= ~(uint16_t)(1 << IEEE154_FCF_ACK_REQ);
	}

	async command bool IEEE154MessageLayer.getFramePending(message_t* msg)
	{
		return getHeader(msg)->fcf & (1 << IEEE154_FCF_FRAME_PENDING);
	}

	async command void IEEE154MessageLayer.setFramePending(message_t* msg, bool pending)
	{
		if( pending )
			getHeader(msg)->fcf |= (1 << IEEE154_FCF_FRAME_PENDING);
		else
			getHeader(msg)->fcf &= ~(uint16_t)(1 << IEEE154_FCF_FRAME_PENDING);
	}

	async command uint8_t IEEE154MessageLayer.getDSN(message_t* msg)
	{
		return getHeader(msg)->dsn;
	}

	async command void IEEE154MessageLayer.setDSN(message_t* msg, uint8_t dsn)
	{
		getHeader(msg)->dsn = dsn;
	}

	async command uint16_t IEEE154MessageLayer.getDestPan(message_t* msg)
	{
		return getHeader(msg)->destpan;
	}

	async command void IEEE154MessageLayer.setDestPan(message_t* msg, uint16_t pan)
	{
		getHeader(msg)->destpan = pan;
	}

	async command uint16_t IEEE154MessageLayer.getDestAddr(message_t* msg)
	{
		return getHeader(msg)->dest;
	}

	async command void IEEE154MessageLayer.setDestAddr(message_t* msg, uint16_t addr)
	{
		getHeader(msg)->dest = addr;
	}

	async command uint16_t IEEE154MessageLayer.getSrcAddr(message_t* msg)
	{
		return getHeader(msg)->src;
	}

	async command void IEEE154MessageLayer.setSrcAddr(message_t* msg, uint16_t addr)
	{	
		getHeader(msg)->src = addr;
	}

	async command bool IEEE154MessageLayer.requiresAckWait(message_t* msg)
	{
		return call IEEE154MessageLayer.getAckRequired(msg)
			&& call IEEE154MessageLayer.isDataFrame(msg)
			&& call IEEE154MessageLayer.getDestAddr(msg) != 0xFFFF;
	}

	async command bool IEEE154MessageLayer.requiresAckReply(message_t* msg)
	{
		return call IEEE154MessageLayer.getAckRequired(msg)
			&& call IEEE154MessageLayer.isDataFrame(msg)
			&& call IEEE154MessageLayer.getDestAddr(msg) == call ActiveMessageAddress.amAddress();
	}

	async event void ActiveMessageAddress.changed()
	{
	}

/*----------------- Ieee154Packet -----------------*/

	command ieee154_saddr_t Ieee154Packet.address()
	{
		return call ActiveMessageAddress.amAddress();
	}

	command ieee154_saddr_t Ieee154Packet.destination(message_t* msg)
	{
		return call IEEE154MessageLayer.getDestAddr(msg);
	}
 
	command ieee154_saddr_t Ieee154Packet.source(message_t* msg)
	{
		return call IEEE154MessageLayer.getSrcAddr(msg);
	}

	command void Ieee154Packet.setDestination(message_t* msg, ieee154_saddr_t addr)
	{
		call IEEE154MessageLayer.setDestAddr(msg, addr);
	}

	command void Ieee154Packet.setSource(message_t* msg, ieee154_saddr_t addr)
	{
		call IEEE154MessageLayer.setSrcAddr(msg, addr);
	}

	command bool Ieee154Packet.isForMe(message_t* msg)
	{
		ieee154_saddr_t addr = call Ieee154Packet.destination(msg);
		return addr == call Ieee154Packet.address() || addr == IEEE154_BROADCAST_ADDR;
	}

	command ieee154_panid_t Ieee154Packet.pan(message_t* msg)
	{
		return call IEEE154MessageLayer.getDestPan(msg);
	}

	command void Ieee154Packet.setPan(message_t* msg, ieee154_panid_t grp)
	{
		call IEEE154MessageLayer.setDestPan(msg, grp);
	}

	command ieee154_panid_t Ieee154Packet.localPan()
	{
		return call ActiveMessageAddress.amGroup();
	}

/*----------------- RadioPacket -----------------*/

	async command uint8_t RadioPacket.headerLength(message_t* msg)
	{
		return call SubPacket.headerLength(msg) + sizeof(ieee154_header_t);
	}

	async command uint8_t RadioPacket.payloadLength(message_t* msg)
	{
		return call SubPacket.payloadLength(msg) - sizeof(ieee154_header_t);
	}

	async command void RadioPacket.setPayloadLength(message_t* msg, uint8_t length)
	{
		call SubPacket.setPayloadLength(msg, length + sizeof(ieee154_header_t));
	}

	async command uint8_t RadioPacket.maxPayloadLength()
	{
		return call SubPacket.maxPayloadLength() - sizeof(ieee154_header_t);
	}

	async command uint8_t RadioPacket.metadataLength(message_t* msg)
	{
		return call SubPacket.metadataLength(msg);
	}

	async command void RadioPacket.clear(message_t* msg)
	{
		call IEEE154MessageLayer.createDataFrame(msg);
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
		if( ! call IEEE154MessageLayer.isDataFrame(msg) )
			call IEEE154MessageLayer.createDataFrame(msg);

		call Packet.setPayloadLength(msg, len);
	    	call Ieee154Packet.setSource(msg, call Ieee154Packet.address());
		call Ieee154Packet.setDestination(msg, addr);
	    	call Ieee154Packet.setPan(msg, call Ieee154Packet.localPan());
		
    		signal SendNotifier.aboutToSend(addr, msg);
    	
    		return call SubSend.send(msg);
	}

	default event void Ieee154Send.sendDone(message_t* msg, error_t error)
	{
	}

	default event void SendNotifier.aboutToSend(am_addr_t addr, message_t* msg)
	{
	}

/*----------------- Send -----------------*/

	command error_t Send.send(message_t* msg)
	{
		// user forgot to call Packet.clear(), lower levels can send other types
		if( ! call IEEE154MessageLayer.isDataFrame(msg) )
			call IEEE154MessageLayer.createDataFrame(msg);

		return call SubSend.send(msg);
	}

	command error_t Send.cancel(message_t* msg)
	{
		return call SubSend.cancel(msg);
	}

	event void SubSend.sendDone(message_t* msg, error_t error)
	{
		// we signal  both, only one of them should be connected
		signal Ieee154Send.sendDone(msg, error);
		signal Send.sendDone(msg, error);
	}

	default event void Send.sendDone(message_t* msg, error_t error)
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
}
