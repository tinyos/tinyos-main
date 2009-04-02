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

#include <RF212ActiveMessage.h>
#include <RadioConfig.h>
#include <Tasklet.h>

module RF212ActiveMessageP
{
	provides
	{
		interface RF212DriverConfig;
		interface SoftwareAckConfig;
		interface UniqueConfig;
		interface CsmaConfig;
		interface TrafficMonitorConfig;
		interface RandomCollisionConfig;
		interface SlottedCollisionConfig;
		interface ActiveMessageConfig;
		interface DummyConfig;

		interface Packet;

		interface PacketData<flags_metadata_t> as PacketFlagsMetadata;
		interface PacketData<rf212_metadata_t> as PacketRF212Metadata;
		interface PacketData<timestamp_metadata_t> as PacketTimeStampMetadata;

#ifdef LOW_POWER_LISTENING
		interface PacketData<lpl_metadata_t> as PacketLplMetadata;
#endif
#ifdef PACKET_LINK
		interface PacketData<link_metadata_t> as PacketLinkMetadata;
#endif
	}

	uses
	{
		interface IEEE154PacketLayer;
		interface RadioAlarm;

		interface PacketTimeStamp<TRadio, uint32_t>;
	}
}

implementation
{
/*----------------- RF212DriverConfig -----------------*/

	async command uint8_t RF212DriverConfig.getLength(message_t* msg)
	{
		return call IEEE154PacketLayer.getLength(msg);
	}

	async command void RF212DriverConfig.setLength(message_t* msg, uint8_t len)
	{
		call IEEE154PacketLayer.setLength(msg, len);
	}

	async command uint8_t* RF212DriverConfig.getPayload(message_t* msg)
	{
		return ((uint8_t*)(call IEEE154PacketLayer.getHeader(msg))) + 1;
	}

	async command uint8_t RF212DriverConfig.getHeaderLength()
	{
		// we need the fcf, dsn, destpan and dest
		return 7;
	}

	async command uint8_t RF212DriverConfig.getMaxLength()
	{
		// note, that the ieee154_footer_t is not stored, but we should include it here
		return sizeof(rf212packet_header_t) - 1 + TOSH_DATA_LENGTH + sizeof(ieee154_footer_t);
	}

	async command bool RF212DriverConfig.requiresRssiCca(message_t* msg)
	{
		return call IEEE154PacketLayer.isDataFrame(msg);
	}

/*----------------- SoftwareAckConfig -----------------*/

	async command bool SoftwareAckConfig.requiresAckWait(message_t* msg)
	{
		return call IEEE154PacketLayer.requiresAckWait(msg);
	}

	async command bool SoftwareAckConfig.isAckPacket(message_t* msg)
	{
		return call IEEE154PacketLayer.isAckFrame(msg);
	}

	async command bool SoftwareAckConfig.verifyAckPacket(message_t* data, message_t* ack)
	{
		return call IEEE154PacketLayer.verifyAckReply(data, ack);
	}

	async command void SoftwareAckConfig.setAckRequired(message_t* msg, bool ack)
	{
		call IEEE154PacketLayer.setAckRequired(msg, ack);
	}

	async command bool SoftwareAckConfig.requiresAckReply(message_t* msg)
	{
		return call IEEE154PacketLayer.requiresAckReply(msg);
	}

	async command void SoftwareAckConfig.createAckPacket(message_t* data, message_t* ack)
	{
		call IEEE154PacketLayer.createAckReply(data, ack);
	}

	async command uint16_t SoftwareAckConfig.getAckTimeout()
	{
		return (uint16_t)(800 * RADIO_ALARM_MICROSEC);
	}

	tasklet_async command void SoftwareAckConfig.reportChannelError()
	{
		signal TrafficMonitorConfig.channelError();
	}

/*----------------- UniqueConfig -----------------*/

	async command uint8_t UniqueConfig.getSequenceNumber(message_t* msg)
	{
		return call IEEE154PacketLayer.getDSN(msg);
	}

	async command void UniqueConfig.setSequenceNumber(message_t* msg, uint8_t dsn)
	{
		call IEEE154PacketLayer.setDSN(msg, dsn);
	}

	async command am_addr_t UniqueConfig.getSender(message_t* msg)
	{
		return call IEEE154PacketLayer.getSrcAddr(msg);
	}

	tasklet_async command void UniqueConfig.reportChannelError()
	{
		signal TrafficMonitorConfig.channelError();
	}

/*----------------- ActiveMessageConfig -----------------*/

	command error_t ActiveMessageConfig.checkPacket(message_t* msg)
	{
		// the user forgot to call clear, we should return EINVAL
		if( ! call IEEE154PacketLayer.isDataFrame(msg) )
			call Packet.clear(msg);

		return SUCCESS;
	}

/*----------------- CsmaConfig -----------------*/

	async command bool CsmaConfig.requiresSoftwareCCA(message_t* msg)
	{
		return call IEEE154PacketLayer.isDataFrame(msg);
	}

/*----------------- TrafficMonitorConfig -----------------*/

	enum
	{
		TRAFFIC_UPDATE_PERIOD = 100,	// in milliseconds
		TRAFFIC_MAX_BYTES = (uint16_t)(TRAFFIC_UPDATE_PERIOD * 1000UL / 32),	// 3125
	};

	async command uint16_t TrafficMonitorConfig.getUpdatePeriod()
	{
		return TRAFFIC_UPDATE_PERIOD;
	}

	async command uint16_t TrafficMonitorConfig.getChannelTime(message_t* msg)
	{
		/* We count in bytes, one byte is 32 microsecond. We are conservative here.
		 *
		 * pure airtime: preable (4 bytes), SFD (1 byte), length (1 byte), payload + CRC (len bytes)
		 * frame separation: 5-10 bytes
		 * ack required: 8-16 byte separation, 11 bytes airtime, 5-10 bytes separation
		 */

		uint8_t len = call IEEE154PacketLayer.getLength(msg);
		return call IEEE154PacketLayer.getAckRequired(msg) ? len + 6 + 16 + 11 + 10 : len + 6 + 10;
	}

	async command am_addr_t TrafficMonitorConfig.getSender(message_t* msg)
	{
		return call IEEE154PacketLayer.getSrcAddr(msg);
	}

	tasklet_async command void TrafficMonitorConfig.timerTick()
	{
		signal SlottedCollisionConfig.timerTick();
	}

/*----------------- RandomCollisionConfig -----------------*/

	/*
	 * We try to use the same values as in CC2420
	 *
	 * CC2420_MIN_BACKOFF = 10 jiffies = 320 microsec
	 * CC2420_BACKOFF_PERIOD = 10 jiffies
	 * initial backoff = 0x1F * CC2420_BACKOFF_PERIOD = 310 jiffies = 9920 microsec
	 * congestion backoff = 0x7 * CC2420_BACKOFF_PERIOD = 70 jiffies = 2240 microsec
	 */

	async command uint16_t RandomCollisionConfig.getMinimumBackoff()
	{
		return (uint16_t)(320 * RADIO_ALARM_MICROSEC);
	}

	async command uint16_t RandomCollisionConfig.getInitialBackoff(message_t* msg)
	{
		return (uint16_t)(9920 * RADIO_ALARM_MICROSEC);
	}

	async command uint16_t RandomCollisionConfig.getCongestionBackoff(message_t* msg)
	{
		return (uint16_t)(2240 * RADIO_ALARM_MICROSEC);
	}

	async command uint16_t RandomCollisionConfig.getTransmitBarrier(message_t* msg)
	{
		uint16_t time;

		// TODO: maybe we should use the embedded timestamp of the message
		time = call RadioAlarm.getNow();

		// estimated response time (download the message, etc) is 5-8 bytes
		if( call IEEE154PacketLayer.requiresAckReply(msg) )
			time += (uint16_t)(32 * (-5 + 16 + 11 + 5) * RADIO_ALARM_MICROSEC);
		else
			time += (uint16_t)(32 * (-5 + 5) * RADIO_ALARM_MICROSEC);

		return time;
	}

	tasklet_async event void RadioAlarm.fired()	{ }

/*----------------- SlottedCollisionConfig -----------------*/

	async command uint16_t SlottedCollisionConfig.getInitialDelay()
	{
		return 300;
	}

	async command uint8_t SlottedCollisionConfig.getScheduleExponent()
	{
		return 1 + RADIO_ALARM_MILLI_EXP;
	}

	async command uint16_t SlottedCollisionConfig.getTransmitTime(message_t* msg)
	{
		// TODO: check if the timestamp is correct
		return call PacketTimeStamp.timestamp(msg);
	}

	async command uint16_t SlottedCollisionConfig.getCollisionWindowStart(message_t* msg)
	{
		// the preamble (4 bytes), SFD (1 byte), plus two extra for safety
		return (call PacketTimeStamp.timestamp(msg)) - (uint16_t)(7 * 32 * RADIO_ALARM_MICROSEC);
	}

	async command uint16_t SlottedCollisionConfig.getCollisionWindowLength(message_t* msg)
	{
		return (uint16_t)(2 * 7 * 32 * RADIO_ALARM_MICROSEC);
	}

	default tasklet_async event void SlottedCollisionConfig.timerTick() { }

/*----------------- Dummy -----------------*/

	async command void DummyConfig.nothing()
	{
	}

/*----------------- Metadata -----------------*/

	inline rf212packet_metadata_t* getMeta(message_t* msg)
	{
		return (rf212packet_metadata_t*)(msg->metadata);
	}

	async command flags_metadata_t* PacketFlagsMetadata.get(message_t* msg)
	{
		return &(getMeta(msg)->flags);
	}

	async command rf212_metadata_t* PacketRF212Metadata.get(message_t* msg)
	{
		return &(getMeta(msg)->rf212);
	}

	async command timestamp_metadata_t* PacketTimeStampMetadata.get(message_t* msg)
	{
		return &(getMeta(msg)->timestamp);
	}

#ifdef LOW_POWER_LISTENING
	async command lpl_metadata_t* PacketLplMetadata.get(message_t* msg)
	{
		return &(getMeta(msg)->lpl);
	}
#endif

#ifdef PACKET_LINK
	async command link_metadata_t* PacketLinkMetadata.get(message_t* msg)
	{
		return &(getMeta(msg)->link);
	}
#endif

/*----------------- Packet -----------------*/

	enum
	{
		PACKET_LENGTH_INCREASE =
			sizeof(rf212packet_header_t) - 1	// the 8-bit length field is not counted
			+ sizeof(ieee154_footer_t),		// the CRC is not stored in memory
	};

	command void Packet.clear(message_t* msg)
	{
		signal PacketFlagsMetadata.clear(msg);
		signal PacketRF212Metadata.clear(msg);
		signal PacketTimeStampMetadata.clear(msg);
#ifdef LOW_POWER_LISTENING
		signal PacketLplMetadata.clear(msg);
#endif
#ifdef PACKET_LINK
		signal PacketLinkMetadata.clear(msg);
#endif
		call IEEE154PacketLayer.createDataFrame(msg);
	}

	inline command void Packet.setPayloadLength(message_t* msg, uint8_t len)
	{
		call IEEE154PacketLayer.setLength(msg, len + PACKET_LENGTH_INCREASE);
	}

	inline command uint8_t Packet.payloadLength(message_t* msg)
	{
		return call IEEE154PacketLayer.getLength(msg) - PACKET_LENGTH_INCREASE;
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
}
