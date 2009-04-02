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

#include <IEEE154PacketLayer.h>

module IEEE154PacketLayerP
{
	provides 
	{
		interface IEEE154PacketLayer;
		interface AMPacket;
	}

	uses interface ActiveMessageAddress;
}

implementation
{
/*----------------- IEEE154Packet -----------------*/

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

		IEEE154_ACK_FRAME_LENGTH = 5,	// includes the FCF, DSN and FCS
		IEEE154_ACK_FRAME_MASK = (IEEE154_TYPE_MASK << IEEE154_FCF_FRAME_TYPE), 
		IEEE154_ACK_FRAME_VALUE = (IEEE154_TYPE_ACK << IEEE154_FCF_FRAME_TYPE),
	};

	inline ieee154_header_t* getHeader(message_t* msg)
	{
		return (ieee154_header_t*)(msg->data - sizeof(ieee154_header_t));
	}

	inline async command ieee154_header_t* IEEE154PacketLayer.getHeader(message_t* msg)
	{
		return getHeader(msg);
	}

	inline async command uint8_t IEEE154PacketLayer.getLength(message_t* msg)
	{
		return getHeader(msg)->length;
	}

	inline async command void IEEE154PacketLayer.setLength(message_t* msg, uint8_t length)
	{
		getHeader(msg)->length = length;
	}

	inline async command uint16_t IEEE154PacketLayer.getFCF(message_t* msg)
	{
		return getHeader(msg)->fcf;
	}

	inline async command void IEEE154PacketLayer.setFCF(message_t* msg, uint16_t fcf)
	{
		getHeader(msg)->fcf = fcf;
	}

	inline async command bool IEEE154PacketLayer.isDataFrame(message_t* msg)
	{
		return (getHeader(msg)->fcf & IEEE154_DATA_FRAME_MASK) == IEEE154_DATA_FRAME_VALUE;
	}

	inline async command void IEEE154PacketLayer.createDataFrame(message_t* msg)
	{
		getHeader(msg)->fcf = IEEE154_DATA_FRAME_VALUE;
	}

	inline async command bool IEEE154PacketLayer.isAckFrame(message_t* msg)
	{
		return (getHeader(msg)->fcf & IEEE154_ACK_FRAME_MASK) == IEEE154_ACK_FRAME_VALUE;
	}

	inline async command void IEEE154PacketLayer.createAckFrame(message_t* msg)
	{
		ieee154_header_t* header = getHeader(msg);

		header->length = IEEE154_ACK_FRAME_LENGTH;
		header->fcf = IEEE154_ACK_FRAME_VALUE;
	}

	inline async command void IEEE154PacketLayer.createAckReply(message_t* data, message_t* ack)
	{
		ieee154_header_t* header = getHeader(ack);

		header->length = IEEE154_ACK_FRAME_LENGTH;
		header->fcf = IEEE154_ACK_FRAME_VALUE;
		header->dsn = getHeader(data)->dsn;
	}

	inline async command bool IEEE154PacketLayer.verifyAckReply(message_t* data, message_t* ack)
	{
		ieee154_header_t* header = getHeader(ack);

		return header->dsn == getHeader(data)->dsn
			&& (header->fcf & IEEE154_ACK_FRAME_MASK) == IEEE154_ACK_FRAME_VALUE;
	}

	inline async command bool IEEE154PacketLayer.getAckRequired(message_t* msg)
	{
		return getHeader(msg)->fcf & (1 << IEEE154_FCF_ACK_REQ);
	}

	inline async command void IEEE154PacketLayer.setAckRequired(message_t* msg, bool ack)
	{
		if( ack )
			getHeader(msg)->fcf |= (1 << IEEE154_FCF_ACK_REQ);
		else
			getHeader(msg)->fcf &= ~(uint16_t)(1 << IEEE154_FCF_ACK_REQ);
	}

	inline async command bool IEEE154PacketLayer.getFramePending(message_t* msg)
	{
		return getHeader(msg)->fcf & (1 << IEEE154_FCF_FRAME_PENDING);
	}

	inline async command void IEEE154PacketLayer.setFramePending(message_t* msg, bool pending)
	{
		if( pending )
			getHeader(msg)->fcf |= (1 << IEEE154_FCF_FRAME_PENDING);
		else
			getHeader(msg)->fcf &= ~(uint16_t)(1 << IEEE154_FCF_FRAME_PENDING);
	}

	inline async command uint8_t IEEE154PacketLayer.getDSN(message_t* msg)
	{
		return getHeader(msg)->dsn;
	}

	inline async command void IEEE154PacketLayer.setDSN(message_t* msg, uint8_t dsn)
	{
		getHeader(msg)->dsn = dsn;
	}

	inline async command uint16_t IEEE154PacketLayer.getDestPan(message_t* msg)
	{
		return getHeader(msg)->destpan;
	}

	inline async command void IEEE154PacketLayer.setDestPan(message_t* msg, uint16_t pan)
	{
		getHeader(msg)->destpan = pan;
	}

	inline async command uint16_t IEEE154PacketLayer.getDestAddr(message_t* msg)
	{
		return getHeader(msg)->dest;
	}

	inline async command void IEEE154PacketLayer.setDestAddr(message_t* msg, uint16_t addr)
	{
		getHeader(msg)->dest = addr;
	}

	inline async command uint16_t IEEE154PacketLayer.getSrcAddr(message_t* msg)
	{
		return getHeader(msg)->src;
	}

	inline async command void IEEE154PacketLayer.setSrcAddr(message_t* msg, uint16_t addr)
	{
		getHeader(msg)->src = addr;
	}

#ifndef TFRAMES_ENABLED

	inline async command uint8_t IEEE154PacketLayer.get6LowPan(message_t* msg)
	{
		return getHeader(msg)->network;
	}

	inline async command void IEEE154PacketLayer.set6LowPan(message_t* msg, uint8_t network)
	{
		getHeader(msg)->network = network;
	}

#endif

	inline async command am_id_t IEEE154PacketLayer.getType(message_t* msg)
	{
		return getHeader(msg)->type;
	}

	inline async command void IEEE154PacketLayer.setType(message_t* msg, am_id_t type)
	{
		getHeader(msg)->type = type;
	}

	async command bool IEEE154PacketLayer.requiresAckWait(message_t* msg)
	{
		return call IEEE154PacketLayer.getAckRequired(msg)
			&& call IEEE154PacketLayer.isDataFrame(msg)
			&& call IEEE154PacketLayer.getDestAddr(msg) != 0xFFFF;
	}

	async command bool IEEE154PacketLayer.requiresAckReply(message_t* msg)
	{
		return call IEEE154PacketLayer.getAckRequired(msg)
			&& call IEEE154PacketLayer.isDataFrame(msg)
			&& call IEEE154PacketLayer.getDestAddr(msg) == call ActiveMessageAddress.amAddress();
	}

	inline async event void ActiveMessageAddress.changed()
	{
	}

/*----------------- AMPacket -----------------*/

	inline command am_addr_t AMPacket.address()
	{
		return call ActiveMessageAddress.amAddress();
	}
 
	inline command am_group_t AMPacket.localGroup()
	{
		// TODO: check if this is correct
		return call ActiveMessageAddress.amGroup();
	}

	inline command am_addr_t AMPacket.destination(message_t* msg)
	{
		return call IEEE154PacketLayer.getDestAddr(msg);
	}
 
	inline command am_addr_t AMPacket.source(message_t* msg)
	{
		return call IEEE154PacketLayer.getSrcAddr(msg);
	}

	inline command void AMPacket.setDestination(message_t* msg, am_addr_t addr)
	{
		call IEEE154PacketLayer.setDestAddr(msg, addr);
	}

	inline command void AMPacket.setSource(message_t* msg, am_addr_t addr)
	{
		call IEEE154PacketLayer.setSrcAddr(msg, addr);
	}

	inline command bool AMPacket.isForMe(message_t* msg)
	{
		am_addr_t addr = call AMPacket.destination(msg);
		return addr == call AMPacket.address() || addr == AM_BROADCAST_ADDR;
	}

	inline command am_id_t AMPacket.type(message_t* msg)
	{
		return call IEEE154PacketLayer.getType(msg);
	}

	inline command void AMPacket.setType(message_t* msg, am_id_t type)
	{
		call IEEE154PacketLayer.setType(msg, type);
	}
  
	inline command am_group_t AMPacket.group(message_t* msg) 
	{
		return call IEEE154PacketLayer.getDestPan(msg);
	}

	inline command void AMPacket.setGroup(message_t* msg, am_group_t grp)
	{
		call IEEE154PacketLayer.setDestPan(msg, grp);
	}
}
