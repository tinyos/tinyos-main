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

#include <TimeSyncMessageLayer.h>

module TimeSyncMessageLayerP
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
		am_id_t id = call AMPacket.type(msg);

		return signal Receive.receive[id](msg, payload, len - sizeof(timesync_footer_t));
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
