/*
 * Copyright (c) 2007, Vanderbilt University
 * Copyright (c) 2011, University of Szeged
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
 * Author: Andras Biro
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
	inline uint8_t getSymbolTime()
	{
		switch( RF212_TRX_CTRL_2_VALUE )
		{
		case RF212_DATA_MODE_BPSK_20:
			return 50;

		case RF212_DATA_MODE_BPSK_40:
			return 25;

		case RF212_DATA_MODE_OQPSK_SIN_RC_100:
		case RF212_DATA_MODE_OQPSK_SIN_RC_200:
		case RF212_DATA_MODE_OQPSK_SIN_RC_400_SCR:
		case RF212_DATA_MODE_OQPSK_SIN_RC_400:
			return 40;

		case RF212_DATA_MODE_OQPSK_SIN_250:
		case RF212_DATA_MODE_OQPSK_RC_250:
		case RF212_DATA_MODE_OQPSK_SIN_500:
		case RF212_DATA_MODE_OQPSK_RC_500:
		case RF212_DATA_MODE_OQPSK_SIN_1000_SCR:
		case RF212_DATA_MODE_OQPSK_SIN_1000:
		case RF212_DATA_MODE_OQPSK_RC_1000_SCR:
		case RF212_DATA_MODE_OQPSK_RC_1000:
			return 16;
		}
	}
	
	inline bool isBpsk()
	{
		switch( RF212_TRX_CTRL_2_VALUE )
		{
		case RF212_DATA_MODE_BPSK_20:
		case RF212_DATA_MODE_BPSK_40:
			return TRUE;

		default:
			return FALSE;
		}
	}

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

// 802.15.4 standard:
// =aTurnaroundTime+phySHRDuration+6*phySymbolsPerOctet
// =12s + phySymbolsPerOctet + 6o * phySymbolsPerOctet
// SHR:  BPSK: 40; OQPSK: 10
// phySymbolsPerOctet: BPSK: 8; OQPSK: 2
// plus we add a constant for safety
//TODO: this const seems way too high. I think we can even go with 0...
#ifndef SOFTWAREACK_TIMEOUT_PLUS
#define SOFTWAREACK_TIMEOUT_PLUS	1000
#endif

	async command uint16_t SoftwareAckConfig.getAckTimeout()
	{
#ifndef SOFTWAREACK_TIMEOUT
		if(isBpsk())
			return ((12+40+6*8) * getSymbolTime() + SOFTWAREACK_TIMEOUT_PLUS) * RADIO_ALARM_MICROSEC;
		else
			return ((12+10+6*2) * getSymbolTime() + SOFTWAREACK_TIMEOUT_PLUS) * RADIO_ALARM_MICROSEC;
#else
			return (uint16_t)(SOFTWAREACK_TIMEOUT * RADIO_ALARM_MICROSEC);
#endif
	}

	tasklet_async command void SoftwareAckConfig.reportChannelError()
	{
#ifdef TRAFFIC_MONITOR
//		signal TrafficMonitorConfig.channelError();
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
//		signal TrafficMonitorConfig.channelError();
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

	async command uint16_t TrafficMonitorConfig.getBytes(message_t* msg)
	{
		// pure airtime: preable (4 bytes), SFD (1 byte), length (1 byte), payload + CRC (len bytes)

		return call RF212Packet.payloadLength(msg) + 6;
	}

/*----------------- RandomCollisionConfig -----------------*/


#ifndef RF212_BACKOFF_MIN
#define RF212_BACKOFF_MIN 20
#endif

	async command uint16_t RandomCollisionConfig.getMinimumBackoff()
	{
		return (uint16_t)(RF212_BACKOFF_MIN * getSymbolTime() * RADIO_ALARM_MICROSEC);
	}

#ifndef RF212_BACKOFF_INIT
#define RF212_BACKOFF_INIT 310
#endif

	async command uint16_t RandomCollisionConfig.getInitialBackoff(message_t* msg)
	{
		return (uint16_t)(RF212_BACKOFF_INIT * getSymbolTime() * RADIO_ALARM_MICROSEC);
	}
	
#ifndef RF212_BACKOFF_CONG
#define RF212_BACKOFF_CONG 140
#endif

	async command uint16_t RandomCollisionConfig.getCongestionBackoff(message_t* msg)
	{
		return (uint16_t)(RF212_BACKOFF_CONG * getSymbolTime() * RADIO_ALARM_MICROSEC);
	}

// 802.15.4 standard: SIFS (no ack requested): 12 symbol; LIFS (ack requested): 40 symbol
	async command uint16_t RandomCollisionConfig.getTransmitBarrier(message_t* msg)
	{
		uint16_t time;

		// TODO: maybe we should use the embedded timestamp of the message
		time = call RadioAlarm.getNow();

		// estimated response time (download the message, etc) is 5-8 bytes
		if( call Ieee154PacketLayer.requiresAckReply(msg) )
			time += (uint16_t)(40 * getSymbolTime() * RADIO_ALARM_MICROSEC);
		else
			time += (uint16_t)(12 * getSymbolTime() * RADIO_ALARM_MICROSEC);

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
		switch(getSymbolTime()){
			case 50: {
				return 38;
			};
			case 40: {
				return 24;
			};
			case 25:{
				return 20;
			};
			case 16:{
				return 12;
			}
			default:{
				return getSymbolTime();
			}
		}
	}
#endif

}
