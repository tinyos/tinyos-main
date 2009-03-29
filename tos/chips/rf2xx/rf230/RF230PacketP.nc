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

#include <RF230Packet.h>
#include <GenericTimeSyncMessage.h>
#include <RadioConfig.h>

module RF230PacketP
{
	provides
	{
		interface PacketAcknowledgements;
		interface Packet;
		interface PacketField<uint8_t> as PacketLinkQuality;
		interface PacketField<uint8_t> as PacketTransmitPower;
		interface PacketField<uint8_t> as PacketRSSI;
		interface PacketField<uint16_t> as PacketSleepInterval;
		interface PacketField<uint8_t> as PacketTimeSyncOffset;

		interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
		interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
	}

	uses
	{
		interface IEEE154Packet2;

		interface LocalTime<TRadio> as LocalTimeRadio;
		interface LocalTime<TMilli> as LocalTimeMilli;
	}
}

implementation
{
	enum
	{
		PACKET_LENGTH_INCREASE = 
			sizeof(rf230packet_header_t) - 1	// the 8-bit length field is not counted
			+ sizeof(ieee154_footer_t),		// the CRC is not stored in memory
	};

	inline rf230packet_metadata_t* getMeta(message_t* msg)
	{
		return (rf230packet_metadata_t*)(msg->metadata);
	}

/*----------------- Packet -----------------*/

	command void Packet.clear(message_t* msg) 
	{
		call IEEE154Packet2.createDataFrame(msg);

		getMeta(msg)->flags = RF230PACKET_CLEAR_METADATA;
	}

	inline command void Packet.setPayloadLength(message_t* msg, uint8_t len) 
	{
		call IEEE154Packet2.setLength(msg, len + PACKET_LENGTH_INCREASE);
	}

	inline command uint8_t Packet.payloadLength(message_t* msg) 
	{
		return call IEEE154Packet2.getLength(msg) - PACKET_LENGTH_INCREASE;
	}

	inline command uint8_t Packet.maxPayloadLength()
	{
		return TOSH_DATA_LENGTH;
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
		call IEEE154Packet2.setAckRequired(msg, TRUE);

		return SUCCESS;
	}

	async command error_t PacketAcknowledgements.noAck(message_t* msg)
	{
		call IEEE154Packet2.setAckRequired(msg, FALSE);

		return SUCCESS;
	}

	async command bool PacketAcknowledgements.wasAcked(message_t* msg)
	{
		return getMeta(msg)->flags & RF230PACKET_WAS_ACKED;
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

/*----------------- PacketTimeStampRadio -----------------*/

	async command bool PacketTimeStampRadio.isValid(message_t* msg)
	{
		return getMeta(msg)->flags & RF230PACKET_TIMESTAMP;
	}

	async command uint32_t PacketTimeStampRadio.timestamp(message_t* msg)
	{
		return getMeta(msg)->timestamp;
	}

	async command void PacketTimeStampRadio.clear(message_t* msg)
	{
		getMeta(msg)->flags &= ~RF230PACKET_TIMESTAMP;
	}

	async command void PacketTimeStampRadio.set(message_t* msg, uint32_t value)
	{
		getMeta(msg)->flags |= RF230PACKET_TIMESTAMP;
		getMeta(msg)->timestamp = value;
	}

/*----------------- PacketTimeStampMilli -----------------*/

	async command bool PacketTimeStampMilli.isValid(message_t* msg)
	{
		return call PacketTimeStampRadio.isValid(msg);
	}

	async command uint32_t PacketTimeStampMilli.timestamp(message_t* msg)
	{
		int32_t offset = call PacketTimeStampRadio.timestamp(msg) - call LocalTimeRadio.get();

		return (offset >> RADIO_ALARM_MILLI_EXP) + call LocalTimeMilli.get();
	}

	async command void PacketTimeStampMilli.clear(message_t* msg)
	{
		call PacketTimeStampRadio.clear(msg);
	}

	async command void PacketTimeStampMilli.set(message_t* msg, uint32_t value)
	{
		int32_t offset = (value - call LocalTimeMilli.get()) << RADIO_ALARM_MILLI_EXP;

		call PacketTimeStampRadio.set(msg, offset + call LocalTimeRadio.get());
	}

/*----------------- PacketTransmitPower -----------------*/

	async command bool PacketTransmitPower.isSet(message_t* msg)
	{
		return getMeta(msg)->flags & RF230PACKET_TXPOWER;
	}

	async command uint8_t PacketTransmitPower.get(message_t* msg)
	{
		return getMeta(msg)->power;
	}

	async command void PacketTransmitPower.clear(message_t* msg)
	{
		getMeta(msg)->flags &= ~RF230PACKET_TXPOWER;
	}

	async command void PacketTransmitPower.set(message_t* msg, uint8_t value)
	{
		getMeta(msg)->flags &= ~RF230PACKET_RSSI;
		getMeta(msg)->flags |= RF230PACKET_TXPOWER;
		getMeta(msg)->power = value;
	}

/*----------------- PacketRSSI -----------------*/

	async command bool PacketRSSI.isSet(message_t* msg)
	{
		return getMeta(msg)->flags & RF230PACKET_RSSI;
	}

	async command uint8_t PacketRSSI.get(message_t* msg)
	{
		return getMeta(msg)->power;
	}

	async command void PacketRSSI.clear(message_t* msg)
	{
		getMeta(msg)->flags &= ~RF230PACKET_RSSI;
	}

	async command void PacketRSSI.set(message_t* msg, uint8_t value)
	{
		getMeta(msg)->flags &= ~RF230PACKET_TXPOWER;
		getMeta(msg)->flags |= RF230PACKET_RSSI;
		getMeta(msg)->power = value;
	}

/*----------------- PacketTimeSyncOffset -----------------*/

	async command bool PacketTimeSyncOffset.isSet(message_t* msg)
	{
		return getMeta(msg)->flags & RF230PACKET_TIMESYNC;
	}

	async command uint8_t PacketTimeSyncOffset.get(message_t* msg)
	{
		return call IEEE154Packet2.getLength(msg) - PACKET_LENGTH_INCREASE - sizeof(timesync_absolute_t);
	}

	async command void PacketTimeSyncOffset.clear(message_t* msg)
	{
		getMeta(msg)->flags &= ~RF230PACKET_TIMESYNC;
	}

	async command void PacketTimeSyncOffset.set(message_t* msg, uint8_t value)
	{
		// the value is ignored, the offset always points to the timesync footer at the end of the payload
		getMeta(msg)->flags |= RF230PACKET_TIMESYNC;
	}

/*----------------- PacketSleepInterval -----------------*/

	async command bool PacketSleepInterval.isSet(message_t* msg)
	{
		return getMeta(msg)->flags & RF230PACKET_LPL_SLEEPINT;
	}

	async command uint16_t PacketSleepInterval.get(message_t* msg)
	{
#ifdef LOW_POWER_LISTENING
		return getMeta(msg)->lpl_sleepint;
#else
		return 0;
#endif
	}

	async command void PacketSleepInterval.clear(message_t* msg)
	{
		getMeta(msg)->flags &= ~RF230PACKET_LPL_SLEEPINT;
	}

	async command void PacketSleepInterval.set(message_t* msg, uint16_t value)
	{
		getMeta(msg)->flags |= RF230PACKET_LPL_SLEEPINT;

#ifdef LOW_POWER_LISTENING
		getMeta(msg)->lpl_sleepint = value;
#endif
	}
}
