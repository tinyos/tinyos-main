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

#include <DefaultPacket.h>

module DefaultPacketP
{
	provides
	{
		interface PacketAcknowledgements;
		interface Packet;
		interface PacketField<uint8_t> as PacketLinkQuality;
		interface PacketField<uint8_t> as PacketTransmitPower;
		interface PacketField<uint16_t> as PacketTimeStamping;
		interface PacketField<uint16_t> as PacketTimeSynchron;

		interface PacketTimeStamp<TRF230, uint16_t>;
		interface PacketTimeSynch<TRF230, uint16_t>;
	}

	uses
	{
		interface IEEE154Packet;
	}
}

implementation
{
/*----------------- Async Packet -----------------*/

#define PACKET_OVERHEAD ((sizeof(ieee154_header_t) - 1) + sizeof(defpacket_footer_t) + sizeof(ieee154_footer_t))

	// async Packet.payloadLength
	inline uint8_t getPayloadLength(message_t* msg)
	{
		//	sizeof(ieee154_header_t) - 1 : the ieee154 header minus the length field
		//	sizeof(defpacket_footer_t) : footer containing the embedded time offset
		//	sizeof(ieee154_footer_t) : the size of the CRC (not transmitted)

		return call IEEE154Packet.getLength(msg) - PACKET_OVERHEAD;
	}

	// async Pakcet.maxPayloadLength
	inline uint8_t getMaxPayloadLength()
	{
		return TOSH_DATA_LENGTH;
	}

/*----------------- Accessors -----------------*/

	inline defpacket_metadata_t* getMeta(message_t* msg)
	{
		return (defpacket_metadata_t*)(msg->metadata);
	}

	inline defpacket_footer_t* getFooter(message_t* msg)
	{
		return (defpacket_footer_t*)(msg->data + getPayloadLength(msg));
	}

/*----------------- Packet -----------------*/

	command void Packet.clear(message_t* msg) 
	{
		call IEEE154Packet.createDataFrame(msg);

#ifdef IEEE154_6LOWPAN
		call IEEE154Packet.set6LowPan(msg, TINYOS_6LOWPAN_NETWORK_ID);
#endif

		getMeta(msg)->flags = DEFPACKET_CLEAR_METADATA;
	}
  
	inline command void Packet.setPayloadLength(message_t* msg, uint8_t len) 
	{
		call IEEE154Packet.setLength(msg, len + PACKET_OVERHEAD);
	}
  
	inline command uint8_t Packet.payloadLength(message_t* msg) 
	{
		return getPayloadLength(msg);
	}
  
	inline command uint8_t Packet.maxPayloadLength()
	{
		return getMaxPayloadLength();
	}
  
	command void* Packet.getPayload(message_t* msg, uint8_t len)
	{
		if( len > TOSH_DATA_LENGTH )
			return NULL;

		return msg->data;
	}

/*----------------- PacketAcknowledgements -----------------*/

	async command error_t PacketAcknowledgements.requestAck(message_t* msg)
	{
		call IEEE154Packet.setAckRequired(msg, TRUE);

		return SUCCESS;
	}

	async command error_t PacketAcknowledgements.noAck(message_t* msg)
	{
		call IEEE154Packet.setAckRequired(msg, FALSE);

		return SUCCESS;
	}

	async command bool PacketAcknowledgements.wasAcked(message_t* msg)
	{
		return getMeta(msg)->flags & DEFPACKET_WAS_ACKED;
	}

/*----------------- PacketLinkQuality -----------------*/

	async command bool PacketLinkQuality.isSet(message_t* msg)
	{
		return TRUE;
	}

	async command uint8_t PacketLinkQuality.get(message_t* msg)
	{
		return getMeta(msg)->lqi;
	}

	async command void PacketLinkQuality.clear(message_t* msg)
	{
	}

	async command void PacketLinkQuality.set(message_t* msg, uint8_t value)
	{
		getMeta(msg)->lqi = value;
	}

/*----------------- PacketTimeStamp -----------------*/

	async command bool PacketTimeStamping.isSet(message_t* msg)
	{
		return getMeta(msg)->flags & DEFPACKET_TIMESTAMP;
	}

	async command uint16_t PacketTimeStamping.get(message_t* msg)
	{
		return getMeta(msg)->timestamp;
	}

	async command void PacketTimeStamping.clear(message_t* msg)
	{
		getMeta(msg)->flags &= ~DEFPACKET_TIMESTAMP;
	}

	async command void PacketTimeStamping.set(message_t* msg, uint16_t value)
	{
		getMeta(msg)->flags |= DEFPACKET_TIMESTAMP;
		getMeta(msg)->timestamp = value;
	}

	inline async command bool PacketTimeStamp.isSet(message_t* msg)
	{
		return call PacketTimeStamping.isSet(msg);
	}

	inline async command uint16_t PacketTimeStamp.get(message_t* msg)
	{
		return call PacketTimeStamping.get(msg);
	}

	inline async command void PacketTimeStamp.clear(message_t* msg)
	{
		call PacketTimeStamping.clear(msg);
	}

	inline async command void PacketTimeStamp.set(message_t* msg, uint16_t value)
	{
		call PacketTimeStamping.set(msg, value);
	}

/*----------------- PacketTimeSynch -----------------*/

	async command bool PacketTimeSynchron.isSet(message_t* msg)
	{
		// just sanity check if the length is not initialized
		if( getPayloadLength(msg) > getMaxPayloadLength() )
			return FALSE;

		return getFooter(msg)->timeoffset != DEFPACKET_INVALID_TIMEOFFSET;
	}

	async command uint16_t PacketTimeSynchron.get(message_t* msg)
	{
		return getFooter(msg)->timeoffset;
	}

	async command void PacketTimeSynchron.clear(message_t* msg)
	{
		// just sanity check if the length is not initialized
		if( getPayloadLength(msg) <= getMaxPayloadLength() )
			getFooter(msg)->timeoffset = DEFPACKET_INVALID_TIMEOFFSET;
	}

	async command void PacketTimeSynchron.set(message_t* msg, uint16_t value)
	{
		if( getPayloadLength(msg) > getMaxPayloadLength() )
			return;

		if( value == DEFPACKET_INVALID_TIMEOFFSET )
			++value;

		getFooter(msg)->timeoffset = value;
	}

	inline async command bool PacketTimeSynch.isSet(message_t* msg)
	{
		return call PacketTimeSynchron.isSet(msg);
	}

	inline async command uint16_t PacketTimeSynch.get(message_t* msg)
	{
		return call PacketTimeSynchron.get(msg);
	}

	inline async command void PacketTimeSynch.clear(message_t* msg)
	{
		call PacketTimeSynchron.clear(msg);
	}

	inline async command void PacketTimeSynch.set(message_t* msg, uint16_t value)
	{
		call PacketTimeSynchron.set(msg, value);
	}

/*----------------- Global fields -----------------*/

	uint8_t flags;
	enum
	{
		FLAG_TXPOWER = 0x01,
	};

	uint8_t transmitPower;

/*----------------- PacketTransmitPower -----------------*/

	async command bool PacketTransmitPower.isSet(message_t* msg)
	{
		return flags & FLAG_TXPOWER;
	}

	async command uint8_t PacketTransmitPower.get(message_t* msg)
	{
		return transmitPower;
	}

	async command void PacketTransmitPower.clear(message_t* msg)
	{
		flags &= ~FLAG_TXPOWER;
	}

	async command void PacketTransmitPower.set(message_t* msg, uint8_t value)
	{
		flags |= FLAG_TXPOWER;
		transmitPower = value;
	}
}
