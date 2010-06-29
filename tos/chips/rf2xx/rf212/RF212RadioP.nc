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
 */

#include <RF212Radio.h>
#include <RadioConfig.h>
#include <Tasklet.h>

module RF212RadioP
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

#ifdef LOW_POWER_LISTENING
		interface LowPowerListeningConfig;
#endif
	}

	uses
	{
		interface Ieee154PacketLayer;
		interface RadioAlarm;
		interface RadioPacket as RF212Packet;

		interface PacketTimeStamp<TRadio, uint32_t>;
	}
}

implementation
{

/*----------------- RF212DriverConfig -----------------*/

	async command uint8_t RF212DriverConfig.headerLength(message_t* msg)
	{
		return offsetof(message_t, data) - sizeof(rf212packet_header_t);
	}

	async command uint8_t RF212DriverConfig.maxPayloadLength()
	{
		return sizeof(rf212packet_header_t) + TOSH_DATA_LENGTH;
	}

	async command uint8_t RF212DriverConfig.metadataLength(message_t* msg)
	{
		return 0;
	}

	async command uint8_t RF212DriverConfig.headerPreloadLength()
	{
		// we need the fcf, dsn, destpan and dest
		return 7;
	}

	async command bool RF212DriverConfig.requiresRssiCca(message_t* msg)
	{
		return call Ieee154PacketLayer.isDataFrame(msg);
	}

/*----------------- SoftwareAckConfig -----------------*/

	async command bool SoftwareAckConfig.requiresAckWait(message_t* msg)
	{
		return call Ieee154PacketLayer.requiresAckWait(msg);
	}

	async command bool SoftwareAckConfig.isAckPacket(message_t* msg)
	{
		return call Ieee154PacketLayer.isAckFrame(msg);
	}

	async command bool SoftwareAckConfig.verifyAckPacket(message_t* data, message_t* ack)
	{
		return call Ieee154PacketLayer.verifyAckReply(data, ack);
	}

	async command void SoftwareAckConfig.setAckRequired(message_t* msg, bool ack)
	{
		call Ieee154PacketLayer.setAckRequired(msg, ack);
	}

	async command bool SoftwareAckConfig.requiresAckReply(message_t* msg)
	{
		return call Ieee154PacketLayer.requiresAckReply(msg);
	}

	async command void SoftwareAckConfig.createAckPacket(message_t* data, message_t* ack)
	{
		call Ieee154PacketLayer.createAckReply(data, ack);
	}

#ifndef SOFTWAREACK_TIMEOUT
#define SOFTWAREACK_TIMEOUT	20000
#endif

	async command uint16_t SoftwareAckConfig.getAckTimeout()
	{
		return (uint16_t)(SOFTWAREACK_TIMEOUT * RADIO_ALARM_MICROSEC);
	}

	tasklet_async command void SoftwareAckConfig.reportChannelError()
	{
#ifdef TRAFFIC_MONITOR
		signal TrafficMonitorConfig.channelError();
#endif
	}

/*----------------- UniqueConfig -----------------*/

	async command uint8_t UniqueConfig.getSequenceNumber(message_t* msg)
	{
		return call Ieee154PacketLayer.getDSN(msg);
	}

	async command void UniqueConfig.setSequenceNumber(message_t* msg, uint8_t dsn)
	{
		call Ieee154PacketLayer.setDSN(msg, dsn);
	}

	async command am_addr_t UniqueConfig.getSender(message_t* msg)
	{
		return call Ieee154PacketLayer.getSrcAddr(msg);
	}

	tasklet_async command void UniqueConfig.reportChannelError()
	{
#ifdef TRAFFIC_MONITOR
		signal TrafficMonitorConfig.channelError();
#endif
	}

/*----------------- ActiveMessageConfig -----------------*/

	command am_addr_t ActiveMessageConfig.destination(message_t* msg)
	{
		return call Ieee154PacketLayer.getDestAddr(msg);
	}

	command void ActiveMessageConfig.setDestination(message_t* msg, am_addr_t addr)
	{
		call Ieee154PacketLayer.setDestAddr(msg, addr);
	}

	command am_addr_t ActiveMessageConfig.source(message_t* msg)
	{
		return call Ieee154PacketLayer.getSrcAddr(msg);
	}

	command void ActiveMessageConfig.setSource(message_t* msg, am_addr_t addr)
	{
		call Ieee154PacketLayer.setSrcAddr(msg, addr);
	}

	command am_group_t ActiveMessageConfig.group(message_t* msg)
	{
		return call Ieee154PacketLayer.getDestPan(msg);
	}

	command void ActiveMessageConfig.setGroup(message_t* msg, am_group_t grp)
	{
		call Ieee154PacketLayer.setDestPan(msg, grp);
	}

	command error_t ActiveMessageConfig.checkFrame(message_t* msg)
	{
		if( ! call Ieee154PacketLayer.isDataFrame(msg) )
			call Ieee154PacketLayer.createDataFrame(msg);

		return SUCCESS;
	}

/*----------------- CsmaConfig -----------------*/

	async command bool CsmaConfig.requiresSoftwareCCA(message_t* msg)
	{
		return call Ieee154PacketLayer.isDataFrame(msg);
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

		uint8_t len = call RF212Packet.payloadLength(msg);
		return call Ieee154PacketLayer.getAckRequired(msg) ? len + 6 + 16 + 11 + 10 : len + 6 + 10;
	}

	async command am_addr_t TrafficMonitorConfig.getSender(message_t* msg)
	{
		return call Ieee154PacketLayer.getSrcAddr(msg);
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

#ifndef LOW_POWER_LISTENING

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

#endif

	async command uint16_t RandomCollisionConfig.getTransmitBarrier(message_t* msg)
	{
		uint16_t time;

		// TODO: maybe we should use the embedded timestamp of the message
		time = call RadioAlarm.getNow();

		// estimated response time (download the message, etc) is 5-8 bytes
		if( call Ieee154PacketLayer.requiresAckReply(msg) )
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

/*----------------- Dummy -----------------*/

	async command void DummyConfig.nothing()
	{
	}

/*----------------- LowPowerListening -----------------*/

#ifdef LOW_POWER_LISTENING

	command bool LowPowerListeningConfig.needsAutoAckRequest(message_t* msg)
	{
		return call Ieee154PacketLayer.getDestAddr(msg) != TOS_BCAST_ADDR;
	}

	command bool LowPowerListeningConfig.ackRequested(message_t* msg)
	{
		return call Ieee154PacketLayer.getAckRequired(msg);
	}

	command uint16_t LowPowerListeningConfig.getListenLength()
	{
		return 5;
	}

	async command uint16_t RandomCollisionConfig.getMinimumBackoff()
	{
		return (uint16_t)(320 * RADIO_ALARM_MICROSEC);
	}

	async command uint16_t RandomCollisionConfig.getInitialBackoff(message_t* msg)
	{
		return (uint16_t)(1600 * RADIO_ALARM_MICROSEC);
	}

	async command uint16_t RandomCollisionConfig.getCongestionBackoff(message_t* msg)
	{
		return (uint16_t)(3200 * RADIO_ALARM_MICROSEC);
	}

#endif

}
