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
		interface LowpanNetworkConfig;
		interface IEEE154MessageConfig;
		interface DummyConfig;

		interface Packet;

		interface PacketData<flags_metadata_t> as PacketFlagsMetadata;
		interface PacketData<rf212_metadata_t> as PacketRF212Metadata;
		interface PacketData<timestamp_metadata_t> as PacketTimeStampMetadata;

#ifdef LOW_POWER_LISTENING
		interface LowPowerListeningConfig;
#endif
#ifdef PACKET_LINK
		interface PacketData<link_metadata_t> as PacketLinkMetadata;
#endif
	}

	uses
	{
		interface IEEE154MessageLayer;
		interface RadioAlarm;

		interface PacketTimeStamp<TRadio, uint32_t>;
	}
}

implementation
{
	rf212packet_header_t* getHeader(message_t* msg)
	{
		return (rf212packet_header_t*)(msg->data - sizeof(rf212packet_header_t));
	}

	rf212packet_metadata_t* getMeta(message_t* msg)
	{
		return (rf212packet_metadata_t*)(msg->metadata);
	}

/*----------------- RF212DriverConfig -----------------*/

	async command uint8_t RF212DriverConfig.getLength(message_t* msg)
	{
		return call IEEE154MessageLayer.getLength(msg);
	}

	async command void RF212DriverConfig.setLength(message_t* msg, uint8_t len)
	{
		call IEEE154MessageLayer.setLength(msg, len);
	}

	async command uint8_t* RF212DriverConfig.getPayload(message_t* msg)
	{
		return ((uint8_t*)(call IEEE154MessageConfig.getHeader(msg))) + 1;
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
		return call IEEE154MessageLayer.isDataFrame(msg);
	}

/*----------------- SoftwareAckConfig -----------------*/

	async command bool SoftwareAckConfig.requiresAckWait(message_t* msg)
	{
		return call IEEE154MessageLayer.requiresAckWait(msg);
	}

	async command bool SoftwareAckConfig.isAckPacket(message_t* msg)
	{
		return call IEEE154MessageLayer.isAckFrame(msg);
	}

	async command bool SoftwareAckConfig.verifyAckPacket(message_t* data, message_t* ack)
	{
		return call IEEE154MessageLayer.verifyAckReply(data, ack);
	}

	async command void SoftwareAckConfig.setAckRequired(message_t* msg, bool ack)
	{
		call IEEE154MessageLayer.setAckRequired(msg, ack);
	}

	async command bool SoftwareAckConfig.requiresAckReply(message_t* msg)
	{
		return call IEEE154MessageLayer.requiresAckReply(msg);
	}

	async command void SoftwareAckConfig.createAckPacket(message_t* data, message_t* ack)
	{
		call IEEE154MessageLayer.createAckReply(data, ack);
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
		return call IEEE154MessageLayer.getDSN(msg);
	}

	async command void UniqueConfig.setSequenceNumber(message_t* msg, uint8_t dsn)
	{
		call IEEE154MessageLayer.setDSN(msg, dsn);
	}

	async command am_addr_t UniqueConfig.getSender(message_t* msg)
	{
		return call IEEE154MessageLayer.getSrcAddr(msg);
	}

	tasklet_async command void UniqueConfig.reportChannelError()
	{
		signal TrafficMonitorConfig.channelError();
	}

/*----------------- ActiveMessageConfig -----------------*/

	command error_t ActiveMessageConfig.checkPacket(message_t* msg)
	{
		// the user forgot to call clear, we should return EINVAL
		if( ! call IEEE154MessageLayer.isDataFrame(msg) )
			call Packet.clear(msg);

		return SUCCESS;
	}

	command activemessage_header_t* ActiveMessageConfig.getHeader(message_t* msg)
	{
		return &(getHeader(msg)->am);
	}

	command am_addr_t ActiveMessageConfig.destination(message_t* msg)
	{
		return call IEEE154MessageLayer.getDestAddr(msg);
	}

	command void ActiveMessageConfig.setDestination(message_t* msg, am_addr_t addr)
	{
		call IEEE154MessageLayer.setDestAddr(msg, addr);
	}

	command am_addr_t ActiveMessageConfig.source(message_t* msg)
	{
		return call IEEE154MessageLayer.getSrcAddr(msg);
	}

	command void ActiveMessageConfig.setSource(message_t* msg, am_addr_t addr)
	{
		call IEEE154MessageLayer.setSrcAddr(msg, addr);
	}

	command am_group_t ActiveMessageConfig.group(message_t* msg)
	{
		return call IEEE154MessageLayer.getDestPan(msg);
	}

	command void ActiveMessageConfig.setGroup(message_t* msg, am_group_t grp)
	{
		call IEEE154MessageLayer.setDestPan(msg, grp);
	}

/*----------------- CsmaConfig -----------------*/

	async command bool CsmaConfig.requiresSoftwareCCA(message_t* msg)
	{
		return call IEEE154MessageLayer.isDataFrame(msg);
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

		uint8_t len = call IEEE154MessageLayer.getLength(msg);
		return call IEEE154MessageLayer.getAckRequired(msg) ? len + 6 + 16 + 11 + 10 : len + 6 + 10;
	}

	async command am_addr_t TrafficMonitorConfig.getSender(message_t* msg)
	{
		return call IEEE154MessageLayer.getSrcAddr(msg);
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
		if( call IEEE154MessageLayer.requiresAckReply(msg) )
			time += (uint16_t)(32 * (-5 + 16 + 11 + 5) * RADIO_ALARM_MICROSEC);
		else
			time += (uint16_t)(32 * (-5 + 5) * RADIO_ALARM_MICROSEC);

		return time;
	}

	tasklet_async event void RadioAlarm.fired()
	{
	}

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

/*----------------- LowpanNetwork -----------------*/

	command lowpan_header_t* LowpanNetworkConfig.getHeader(message_t* msg)
	{
		return &(getHeader(msg)->lowpan);
	}

/*----------------- IEEE154Message -----------------*/

	async command ieee154_header_t* IEEE154MessageConfig.getHeader(message_t* msg)
	{
		return &(getHeader(msg)->ieee154);
	}

/*----------------- LowPowerListening -----------------*/

#ifdef LOW_POWER_LISTENING

	async command lpl_metadata_t* LowPowerListeningConfig.metadata(message_t* msg)
	{
		return &(getMeta(msg)->lpl);
	}

	async command bool LowPowerListeningConfig.getAckRequired(message_t* msg)
	{
		return call IEEE154MessageLayer.getAckRequired(msg);
	}

#endif

/*----------------- Headers and Metadata -----------------*/

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
		signal LowPowerListeningConfig.clear(msg);
#endif
#ifdef PACKET_LINK
		signal PacketLinkMetadata.clear(msg);
#endif
		call IEEE154MessageLayer.createDataFrame(msg);
	}

	command void Packet.setPayloadLength(message_t* msg, uint8_t len)
	{
		call IEEE154MessageLayer.setLength(msg, len + PACKET_LENGTH_INCREASE);
	}

	command uint8_t Packet.payloadLength(message_t* msg)
	{
		return call IEEE154MessageLayer.getLength(msg) - PACKET_LENGTH_INCREASE;
	}

	command uint8_t Packet.maxPayloadLength()
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
