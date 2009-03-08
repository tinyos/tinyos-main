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

#include <RF2xxPacket.h>
#include <RadioAlarm.h>
#include <Tasklet.h>
#include <HplRF2xx.h>

module RF2xxActiveMessageP
{
	provides
	{
		interface RF2xxDriverConfig;
		interface SoftwareAckConfig;
		interface UniqueConfig;
		interface CsmaConfig;
		interface TrafficMonitorConfig;
		interface RandomCollisionConfig;
		interface SlottedCollisionConfig;
		interface ActiveMessageConfig;
		interface DummyConfig;
	}

	uses
	{
		interface IEEE154Packet;
		interface Packet;
		interface RadioAlarm;
	}
}

implementation
{
/*----------------- RF2xxDriverConfig -----------------*/

	async command uint8_t RF2xxDriverConfig.getLength(message_t* msg)
	{
		return call IEEE154Packet.getLength(msg);
	}

	async command void RF2xxDriverConfig.setLength(message_t* msg, uint8_t len)
	{
		call IEEE154Packet.setLength(msg, len);
	}

	async command uint8_t* RF2xxDriverConfig.getPayload(message_t* msg)
	{
		return ((uint8_t*)(call IEEE154Packet.getHeader(msg))) + 1;
	}

	inline rf2xxpacket_metadata_t* getMeta(message_t* msg)
	{
		return (rf2xxpacket_metadata_t*)(msg->metadata);
	}

	async command uint8_t RF2xxDriverConfig.getHeaderLength()
	{
		// we need the fcf, dsn, destpan and dest
		return 7;
	}

	async command uint8_t RF2xxDriverConfig.getMaxLength()
	{
		// note, that the ieee154_footer_t is not stored, but we should include it here
		return sizeof(rf2xxpacket_header_t) - 1 + TOSH_DATA_LENGTH + sizeof(ieee154_footer_t);
	}

	async command uint8_t RF2xxDriverConfig.getDefaultChannel()
	{
		return RF2XX_DEF_CHANNEL;
	}

	async command bool RF2xxDriverConfig.requiresRssiCca(message_t* msg)
	{
		return call IEEE154Packet.isDataFrame(msg);
	}

/*----------------- SoftwareAckConfig -----------------*/

	async command bool SoftwareAckConfig.requiresAckWait(message_t* msg)
	{
		return call IEEE154Packet.requiresAckWait(msg);
	}

	async command bool SoftwareAckConfig.isAckPacket(message_t* msg)
	{
		return call IEEE154Packet.isAckFrame(msg);
	}

	async command bool SoftwareAckConfig.verifyAckPacket(message_t* data, message_t* ack)
	{
		return call IEEE154Packet.verifyAckReply(data, ack);
	}

	async command bool SoftwareAckConfig.requiresAckReply(message_t* msg)
	{
		return call IEEE154Packet.requiresAckReply(msg);
	}

	async command void SoftwareAckConfig.createAckPacket(message_t* data, message_t* ack)
	{
		call IEEE154Packet.createAckReply(data, ack);
	}

	async command void SoftwareAckConfig.setAckReceived(message_t* msg, bool acked)
	{
		if( acked )
			getMeta(msg)->flags |= RF2XXPACKET_WAS_ACKED;
		else
			getMeta(msg)->flags &= ~RF2XXPACKET_WAS_ACKED;
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
		return call IEEE154Packet.getDSN(msg);
	}

	async command void UniqueConfig.setSequenceNumber(message_t* msg, uint8_t dsn)
	{
		call IEEE154Packet.setDSN(msg, dsn);
	}

	async command am_addr_t UniqueConfig.getSender(message_t* msg)
	{
		return call IEEE154Packet.getSrcAddr(msg);
	}

	tasklet_async command void UniqueConfig.reportChannelError()
	{
		signal TrafficMonitorConfig.channelError();
	}

/*----------------- ActiveMessageConfig -----------------*/

	command error_t ActiveMessageConfig.checkPacket(message_t* msg)
	{
		// the user forgot to call clear, we should return EINVAL
		if( ! call IEEE154Packet.isDataFrame(msg) )
			call Packet.clear(msg);

		return SUCCESS;
	}

/*----------------- CsmaConfig -----------------*/

	async command bool CsmaConfig.requiresSoftwareCCA(message_t* msg)
	{
		return call IEEE154Packet.isDataFrame(msg);
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

		uint8_t len = call IEEE154Packet.getLength(msg);
		return call IEEE154Packet.getAckRequired(msg) ? len + 6 + 16 + 11 + 10 : len + 6 + 10;
	}

	async command am_addr_t TrafficMonitorConfig.getSender(message_t* msg)
	{
		return call IEEE154Packet.getSrcAddr(msg);
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
		if( call IEEE154Packet.requiresAckReply(msg) )
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
		return 11;
	}

	async command uint16_t SlottedCollisionConfig.getTransmitTime(message_t* msg)
	{
		// TODO: check if the timestamp is correct
		return getMeta(msg)->timestamp;
	}

	async command uint16_t SlottedCollisionConfig.getCollisionWindowStart(message_t* msg)
	{
		// the preamble (4 bytes), SFD (1 byte), plus two extra for safety
		return getMeta(msg)->timestamp - (uint16_t)(7 * 32 * RADIO_ALARM_MICROSEC);
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
}
