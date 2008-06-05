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

#include <TimeSyncMessage.h>
#include <HplRF230.h>

module TimeSyncMessageP
{
	provides
	{
		interface TimeSyncAMSend<TRF230, uint32_t> as TimeSyncAMSendRadio[uint8_t id];
		interface TimeSyncAMSend<TMilli, uint32_t> as TimeSyncAMSendMilli[uint8_t id];
		interface Packet;

		interface TimeSyncPacket<TRF230, uint32_t> as TimeSyncPacketRadio;
		interface TimeSyncPacket<TMilli, uint32_t> as TimeSyncPacketMilli;
	}

	uses
	{
		interface AMSend as SubSend[uint8_t id];
		interface Packet as SubPacket;

		interface PacketTimeStamp<TRF230, uint32_t> as PacketTimeStampRadio;
		interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;

		interface LocalTime<TRF230> as LocalTimeRadio;
		interface LocalTime<TMilli> as LocalTimeMilli;

		interface PacketField<uint8_t> as PacketTimeSyncOffset;
	}
}

implementation
{
	// TODO: change the Packet.payloadLength and Packet.maxPayloadLength commands to async
	inline void* getFooter(message_t* msg)
	{
		// we use the payload length that we export (the smaller one)
		return msg->data + call Packet.payloadLength(msg);
	}

/*----------------- Packet -----------------*/

	command void Packet.clear(message_t* msg) 
	{
		call SubPacket.clear(msg);
	}

	command void Packet.setPayloadLength(message_t* msg, uint8_t len) 
	{
		call SubPacket.setPayloadLength(msg, len + sizeof(timesync_relative_t));
	}

	command uint8_t Packet.payloadLength(message_t* msg) 
	{
		return call SubPacket.payloadLength(msg) - sizeof(timesync_relative_t);
	}

	command uint8_t Packet.maxPayloadLength()
	{
		return call SubPacket.maxPayloadLength() - sizeof(timesync_relative_t);
	}

	command void* Packet.getPayload(message_t* msg, uint8_t len)
	{
		return call SubPacket.getPayload(msg, len + sizeof(timesync_relative_t));
	}

/*----------------- TimeSyncAMSendRadio -----------------*/

	command error_t TimeSyncAMSendRadio.send[am_id_t id](am_addr_t addr, message_t* msg, uint8_t len, uint32_t event_time)
	{
		*(timesync_absolute_t*)(msg->data + len) = event_time;

		call PacketTimeSyncOffset.set(msg, len);

		return call SubSend.send[id](addr, msg, len + sizeof(timesync_relative_t));
	}

	command error_t TimeSyncAMSendRadio.cancel[am_id_t id](message_t* msg)
	{
		return call SubSend.cancel[id](msg);
	}

	default event void TimeSyncAMSendRadio.sendDone[am_id_t id](message_t* msg, error_t error)
	{
	}

	command uint8_t TimeSyncAMSendRadio.maxPayloadLength[am_id_t id]()
	{
		return call SubSend.maxPayloadLength[id]() - sizeof(timesync_relative_t);
	}

	command void* TimeSyncAMSendRadio.getPayload[am_id_t id](message_t* msg, uint8_t len)
	{
		return call SubSend.getPayload[id](msg, len + sizeof(timesync_relative_t));
	}

/*----------------- TimeSyncAMSendMilli -----------------*/

	command error_t TimeSyncAMSendMilli.send[am_id_t id](am_addr_t addr, message_t* msg, uint8_t len, uint32_t event_time)
	{
		// compute elapsed time in millisecond
		event_time = ((event_time - call LocalTimeMilli.get()) << 10) + call LocalTimeRadio.get();

		return call TimeSyncAMSendRadio.send[id](addr, msg, len, event_time);
	}

	command error_t TimeSyncAMSendMilli.cancel[am_id_t id](message_t* msg)
	{
		return call TimeSyncAMSendRadio.cancel[id](msg);
	}

	default event void TimeSyncAMSendMilli.sendDone[am_id_t id](message_t* msg, error_t error)
	{
	}

	command uint8_t TimeSyncAMSendMilli.maxPayloadLength[am_id_t id]()
	{
		return call TimeSyncAMSendRadio.maxPayloadLength[id]();
	}

	command void* TimeSyncAMSendMilli.getPayload[am_id_t id](message_t* msg, uint8_t len)
	{
		return call TimeSyncAMSendRadio.getPayload[id](msg, len);
	}

	/*----------------- SubSend.sendDone -------------------*/

	event void SubSend.sendDone[am_id_t id](message_t* msg, error_t error)
	{
		signal TimeSyncAMSendRadio.sendDone[id](msg, error);
		signal TimeSyncAMSendMilli.sendDone[id](msg, error);
	}

	/*----------------- TimeSyncPacketRadio -----------------*/

	async command bool TimeSyncPacketRadio.isValid(message_t* msg)
	{
		timesync_relative_t* timesync = getFooter(msg);

		return call PacketTimeStampRadio.isValid(msg) && *timesync != 0x80000000L;
	}

	async command uint32_t TimeSyncPacketRadio.eventTime(message_t* msg)
	{
		timesync_relative_t* timesync = getFooter(msg);

		return (*timesync) + call PacketTimeStampRadio.timestamp(msg);
	}

	/*----------------- TimeSyncPacketMilli -----------------*/

	async command bool TimeSyncPacketMilli.isValid(message_t* msg)
	{
		timesync_relative_t* timesync = getFooter(msg);

		return call PacketTimeStampMilli.isValid(msg) && *timesync != 0x80000000L;
	}

	async command uint32_t TimeSyncPacketMilli.eventTime(message_t* msg)
	{
		timesync_relative_t* timesync = getFooter(msg);

		return ((int32_t)(*timesync) << 10) + call PacketTimeStampMilli.timestamp(msg);
	}
}
