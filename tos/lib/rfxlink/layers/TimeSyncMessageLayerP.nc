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
 * - Neither the name of the copyright holders nor the names of
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

#include <TimeSyncMessageLayer.h>

generic module TimeSyncMessageLayerP()
{
	provides
	{
		interface Receive[am_id_t id];
		interface Receive as Snoop[am_id_t id];
		interface AMPacket;
		interface Packet;

		interface TimeSyncAMSend<TRadio, uint32_t> as TimeSyncAMSendRadio[am_id_t id];
		interface TimeSyncAMSend<TMilli, uint32_t> as TimeSyncAMSendMilli[am_id_t id];

		interface TimeSyncPacket<TRadio, uint32_t> as TimeSyncPacketRadio;
		interface TimeSyncPacket<TMilli, uint32_t> as TimeSyncPacketMilli;
	}

	uses
	{
		interface AMSend as SubAMSend;
		interface Receive as SubReceive;
		interface Receive as SubSnoop;
		interface AMPacket as SubAMPacket;
		interface Packet as SubPacket;

		interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
		interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;

		interface LocalTime<TRadio> as LocalTimeRadio;
		interface LocalTime<TMilli> as LocalTimeMilli;

		interface PacketField<uint8_t> as PacketTimeSyncOffset;
	}
}

implementation
{
	inline timesync_footer_t* getFooter(message_t* msg)
	{
		// we use the payload length that we export (the smaller one)
		return (timesync_footer_t*)(msg->data + call Packet.payloadLength(msg));
	}

/*----------------- Packet -----------------*/

	command void Packet.clear(message_t* msg)
	{
		call SubPacket.clear(msg);
	}

	command void Packet.setPayloadLength(message_t* msg, uint8_t len)
	{
		call SubPacket.setPayloadLength(msg, len + sizeof(timesync_footer_t));
	}

	command uint8_t Packet.payloadLength(message_t* msg)
	{
		return call SubPacket.payloadLength(msg) - sizeof(timesync_footer_t);
	}

	command uint8_t Packet.maxPayloadLength()
	{
		return call SubPacket.maxPayloadLength() - sizeof(timesync_footer_t);
	}

	command void* Packet.getPayload(message_t* msg, uint8_t len)
	{
		return call SubPacket.getPayload(msg, len + sizeof(timesync_footer_t));
	}

/*----------------- AMPacket -----------------*/

	inline command am_addr_t AMPacket.address()
	{
		return call SubAMPacket.address();
	}
 
	inline command am_group_t AMPacket.localGroup()
	{
		return call SubAMPacket.localGroup();
	}

	inline command bool AMPacket.isForMe(message_t* msg)
	{
		return call SubAMPacket.isForMe(msg) && call SubAMPacket.type(msg) == AM_TIMESYNCMSG;
	}

	inline command am_addr_t AMPacket.destination(message_t* msg)
	{
		return call SubAMPacket.destination(msg);
	}
 
	inline command void AMPacket.setDestination(message_t* msg, am_addr_t addr)
	{
		call SubAMPacket.setDestination(msg, addr);
	}

	inline command am_addr_t AMPacket.source(message_t* msg)
	{
		return call SubAMPacket.source(msg);
	}

	inline command void AMPacket.setSource(message_t* msg, am_addr_t addr)
	{
		call SubAMPacket.setSource(msg, addr);
	}

	inline command am_id_t AMPacket.type(message_t* msg)
	{
		return getFooter(msg)->type;
	}

	inline command void AMPacket.setType(message_t* msg, am_id_t type)
	{
		getFooter(msg)->type = type;
	}
  
	inline command am_group_t AMPacket.group(message_t* msg) 
	{
		return call SubAMPacket.group(msg);
	}

	inline command void AMPacket.setGroup(message_t* msg, am_group_t grp)
	{
		call SubAMPacket.setGroup(msg, grp);
	}

/*----------------- TimeSyncAMSendRadio -----------------*/

	command error_t TimeSyncAMSendRadio.send[am_id_t id](am_addr_t addr, message_t* msg, uint8_t len, uint32_t event_time)
	{
		timesync_footer_t* footer = (timesync_footer_t*)(msg->data + len);

		footer->type = id;
		footer->timestamp.absolute = event_time;
		call PacketTimeSyncOffset.set(msg, offsetof(message_t, data) + len + offsetof(timesync_footer_t, timestamp.absolute));

		return call SubAMSend.send(addr, msg, len + sizeof(timesync_footer_t));
	}

	command error_t TimeSyncAMSendRadio.cancel[am_id_t id](message_t* msg)
	{
		return call SubAMSend.cancel(msg);
	}

	default event void TimeSyncAMSendRadio.sendDone[am_id_t id](message_t* msg, error_t error)
	{
	}

	command uint8_t TimeSyncAMSendRadio.maxPayloadLength[am_id_t id]()
	{
		return call SubAMSend.maxPayloadLength() - sizeof(timesync_footer_t);
	}

	command void* TimeSyncAMSendRadio.getPayload[am_id_t id](message_t* msg, uint8_t len)
	{
		return call SubAMSend.getPayload(msg, len + sizeof(timesync_footer_t));
	}

/*----------------- TimeSyncAMSendMilli -----------------*/

	command error_t TimeSyncAMSendMilli.send[am_id_t id](am_addr_t addr, message_t* msg, uint8_t len, uint32_t event_time)
	{
		// compute elapsed time in millisecond
		event_time = ((int32_t)(event_time - call LocalTimeMilli.get()) << RADIO_ALARM_MILLI_EXP) + call LocalTimeRadio.get();

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

	event void SubAMSend.sendDone(message_t* msg, error_t error)
	{
		am_id_t id = call AMPacket.type(msg);

		signal TimeSyncAMSendRadio.sendDone[id](msg, error);
		signal TimeSyncAMSendMilli.sendDone[id](msg, error);
	}

/*----------------- SubReceive and SubSnoop -------------------*/

	event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len)
	{
		if( len >= sizeof(timesync_footer_t) ){
			am_id_t id = call AMPacket.type(msg);

			return signal Receive.receive[id](msg, payload, len - sizeof(timesync_footer_t));
		} else
			return msg;
	}

	default event message_t* Receive.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) { return msg; }

	event message_t* SubSnoop.receive(message_t* msg, void* payload, uint8_t len)
	{
		am_id_t id = call AMPacket.type(msg);

		return signal Snoop.receive[id](msg, payload, len - sizeof(timesync_footer_t));
	}

	default event message_t* Snoop.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) { return msg; }

/*----------------- TimeSyncPacketRadio -----------------*/

	command bool TimeSyncPacketRadio.isValid(message_t* msg)
	{
		return call PacketTimeStampRadio.isValid(msg) && getFooter(msg)->timestamp.relative != 0x80000000L;
	}

	command uint32_t TimeSyncPacketRadio.eventTime(message_t* msg)
	{
		return getFooter(msg)->timestamp.relative + call PacketTimeStampRadio.timestamp(msg);
	}

/*----------------- TimeSyncPacketMilli -----------------*/

	command bool TimeSyncPacketMilli.isValid(message_t* msg)
	{
		return call PacketTimeStampMilli.isValid(msg) && getFooter(msg)->timestamp.relative != 0x80000000L;
	}

	command uint32_t TimeSyncPacketMilli.eventTime(message_t* msg)
	{
		return ((int32_t)(getFooter(msg)->timestamp.relative) >> RADIO_ALARM_MILLI_EXP) + call PacketTimeStampMilli.timestamp(msg);
	}
}
