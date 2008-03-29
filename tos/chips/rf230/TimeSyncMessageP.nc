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

module TimeSyncMessageP
{
	provides
	{
		interface TimeSyncSend<TMicro> as TimeSyncSendMicro[uint8_t id];
		interface TimeSyncSend<TMilli> as TimeSyncSendMilli[uint8_t id];
		interface Packet;
		interface TimeSyncPacket<TMicro> as TimeSyncPacketMicro;
		interface TimeSyncPacket<TMilli> as TimeSyncPacketMilli;
	}

	uses
	{
		interface AMSend as SubSend[uint8_t id];
		interface Packet as SubPacket;
		interface PacketTimeStamp<TMicro,uint16_t>;		// TODO: change this to 32-bit
		interface PacketLastTouch;

		interface LocalTime<TMicro> as LocalTimeMicro;
		interface LocalTime<TMilli> as LocalTimeMilli;
	}
}

implementation
{
/*----------------- Packet -----------------*/

	typedef struct timesync_local_t
	{
		uint32_t event_time;		// in microsec
	} timesync_local_t;

	// TODO: change the Packet.payloadLength and Packet.maxPayloadLength commands to async
	inline timesync_footer_t* getFooter(message_t* msg)
	{
		return (timesync_footer_t*)(msg->data + call SubPacket.payloadLength(msg) - sizeof(timesync_footer_t));
	}

	inline timesync_local_t* getLocal(message_t* msg)
	{
		return (timesync_local_t*)(msg->data + call SubPacket.maxPayloadLength() - sizeof(timesync_local_t));
	}

	command void Packet.clear(message_t* msg) 
	{
		call SubPacket.clear(msg);
		call PacketLastTouch.cancel(msg);	// TODO: check if we need to do this
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
		return call SubPacket.maxPayloadLength() - sizeof(timesync_footer_t) - sizeof(timesync_local_t);
	}

	command void* Packet.getPayload(message_t* msg, uint8_t len)
	{
		return call SubPacket.getPayload(msg, len + sizeof(timesync_footer_t) + sizeof(timesync_local_t));
	}

/*----------------- TimeSyncSendMicro -----------------*/

	command error_t TimeSyncSendMicro.send[am_id_t id](uint32_t event_time, am_addr_t addr, message_t* msg, uint8_t len)
	{
		timesync_local_t* local = getLocal(msg);

		local->event_time = event_time;

		call PacketLastTouch.request(msg);

		return call SubSend.send[id](addr, msg, len + sizeof(timesync_footer_t));
	}

	command error_t TimeSyncSendMicro.cancel[am_id_t id](message_t* msg)
	{
		call PacketLastTouch.cancel(msg);
		return call SubSend.cancel[id](msg);
	}

	default event void TimeSyncSendMicro.sendDone[am_id_t id](message_t* msg, error_t error)
	{
	}

	command uint8_t TimeSyncSendMicro.maxPayloadLength[am_id_t id]()
	{
		return call SubSend.maxPayloadLength[id]() - sizeof(timesync_footer_t);
	}

	command void* TimeSyncSendMicro.getPayload[am_id_t id](message_t* msg, uint8_t len)
	{
		return call SubSend.getPayload[id](msg, len + sizeof(timesync_footer_t));
	}

/*----------------- TimeSyncSendMilli -----------------*/

	command error_t TimeSyncSendMilli.send[am_id_t id](uint32_t event_time, am_addr_t addr, message_t* msg, uint8_t len)
	{
		timesync_local_t* local = getLocal(msg);

		// compute elapsed time in millisecond
		event_time = ((event_time - call LocalTimeMilli.get()) << 10) + call LocalTimeMicro.get();

		local->event_time = event_time;

		call PacketLastTouch.request(msg);

		return call SubSend.send[id](addr, msg, len + sizeof(timesync_footer_t));
	}

	command error_t TimeSyncSendMilli.cancel[am_id_t id](message_t* msg)
	{
		return call SubSend.cancel[id](msg);
	}

	default event void TimeSyncSendMilli.sendDone[am_id_t id](message_t* msg, error_t error)
	{
	}

	command uint8_t TimeSyncSendMilli.maxPayloadLength[am_id_t id]()
	{
		return call SubSend.maxPayloadLength[id]() - sizeof(timesync_footer_t);
	}

	command void* TimeSyncSendMilli.getPayload[am_id_t id](message_t* msg, uint8_t len)
	{
		return call SubSend.getPayload[id](msg, len + sizeof(timesync_footer_t));
	}

	/*----------------- SubSend.sendDone -------------------*/

	event void SubSend.sendDone[am_id_t id](message_t* msg, error_t error)
	{
		signal TimeSyncSendMicro.sendDone[id](msg, error);
		signal TimeSyncSendMilli.sendDone[id](msg, error);
	}

	/*----------------- PacketLastTouch.touch -------------------*/

	enum
	{
		TIMESYNC_INVALID_STAMP = 0x80000000L,
	};

	async event void PacketLastTouch.touch(message_t* msg)
	{
		timesync_footer_t* footer = footer = getFooter(msg);
		timesync_local_t* local;

		if( call PacketTimeStamp.isSet(msg) )
		{
			local = getLocal(msg);

			footer->time_offset = local->event_time - call PacketTimeStamp.get(msg);
		}
		else
			footer->time_offset = TIMESYNC_INVALID_STAMP;
	}

	/*----------------- TimeSyncPacketMicro -----------------*/

	async command bool TimeSyncPacketMicro.hasValidTime(message_t* msg)
	{
		timesync_footer_t* footer = getFooter(msg);

		return call PacketTimeStamp.isSet(msg) && footer->time_offset != TIMESYNC_INVALID_STAMP;
	}

	async command uint32_t TimeSyncPacketMicro.getEventTime(message_t* msg)
	{
		timesync_footer_t* footer = getFooter(msg);

		return (uint32_t)(footer->time_offset) + call PacketTimeStamp.get(msg);
	}

	/*----------------- TimeSyncPacketMilli -----------------*/

	async command bool TimeSyncPacketMilli.hasValidTime(message_t* msg)
	{
		timesync_footer_t* footer = getFooter(msg);

		return call PacketTimeStamp.isSet(msg) && footer->time_offset != TIMESYNC_INVALID_STAMP;
	}

	async command uint32_t TimeSyncPacketMilli.getEventTime(message_t* msg)
	{
		timesync_footer_t* footer = getFooter(msg);

		// time offset compared to now in microsec, important that this is signed
		int32_t elapsed = (uint32_t)(footer->time_offset) + call PacketTimeStamp.get(msg) - call LocalTimeMicro.get();

		return (elapsed >> 10) + call LocalTimeMilli.get();
	}
}
