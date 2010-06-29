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
 * @author: Miklos Maroti
 * @author: Brano Kusy (CC2420 port)
 */
#include "CC2420TimeSyncMessage.h"

module CC2420TimeSyncMessageP
{
    provides
    {
        interface TimeSyncAMSend<T32khz, uint32_t> as TimeSyncAMSend32khz[uint8_t id];
        interface TimeSyncAMSend<TMilli, uint32_t> as TimeSyncAMSendMilli[uint8_t id];
        interface Packet;
        interface AMPacket;

        interface TimeSyncPacket<T32khz, uint32_t> as TimeSyncPacket32khz;
        interface TimeSyncPacket<TMilli, uint32_t> as TimeSyncPacketMilli;
        
        interface Receive[am_id_t id];
        interface Receive as Snoop[am_id_t id];
    }

    uses
    {
          interface AMSend as SubSend;
        interface Packet as SubPacket;
        interface AMPacket as SubAMPacket;

        interface Receive as SubReceive;
        interface Receive as SubSnoop;

        interface PacketTimeStamp<T32khz,uint32_t> as PacketTimeStamp32khz;
        interface PacketTimeStamp<TMilli,uint32_t> as PacketTimeStampMilli;
        interface PacketTimeSyncOffset;

        interface LocalTime<T32khz> as LocalTime32khz;
        interface LocalTime<TMilli> as LocalTimeMilli;
        interface Leds;
    }
}

implementation
{
    // TODO: change the Packet.payloadLength and Packet.maxPayloadLength commands to async
    inline timesync_footer_t* getFooter(message_t* msg)
    {
        // we use the payload length that we export (the smaller one)
        return (timesync_footer_t*)(msg->data + call Packet.payloadLength(msg));
    }

/*----------------- Packet -----------------*/
    command void Packet.clear(message_t* msg)
    {
        call PacketTimeSyncOffset.cancel(msg);
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

/*----------------- TimeSyncAMSend32khz -----------------*/
    command error_t TimeSyncAMSend32khz.send[am_id_t id](am_addr_t addr, message_t* msg, uint8_t len, uint32_t event_time)
    {
        error_t err;
        timesync_footer_t* footer = (timesync_footer_t*)(msg->data + len);
        footer->type = id;
        footer->timestamp = event_time;

        err = call SubSend.send(addr, msg, len + sizeof(timesync_footer_t));
        call PacketTimeSyncOffset.set(msg);
        return err;
    }

    command error_t TimeSyncAMSend32khz.cancel[am_id_t id](message_t* msg)
    {
        call PacketTimeSyncOffset.cancel(msg);
        return call SubSend.cancel(msg);
    }

    default event void TimeSyncAMSend32khz.sendDone[am_id_t id](message_t* msg, error_t error) {}

    command uint8_t TimeSyncAMSend32khz.maxPayloadLength[am_id_t id]()
    {
        return call SubSend.maxPayloadLength() - sizeof(timesync_footer_t);
    }

    command void* TimeSyncAMSend32khz.getPayload[am_id_t id](message_t* msg, uint8_t len)
    {
        return call SubSend.getPayload(msg, len + sizeof(timesync_footer_t));
    }

/*----------------- TimeSyncAMSendMilli -----------------*/
    command error_t TimeSyncAMSendMilli.send[am_id_t id](am_addr_t addr, message_t* msg, uint8_t len, uint32_t event_time)
    {
        // compute elapsed time in millisecond
        event_time = ((event_time - call LocalTimeMilli.get()) << 5) + call LocalTime32khz.get();
        return call TimeSyncAMSend32khz.send[id](addr, msg, len, event_time);
    }

    command error_t TimeSyncAMSendMilli.cancel[am_id_t id](message_t* msg)
    {
        return call TimeSyncAMSend32khz.cancel[id](msg);
    }

    default event void TimeSyncAMSendMilli.sendDone[am_id_t id](message_t* msg, error_t error){}

    command uint8_t TimeSyncAMSendMilli.maxPayloadLength[am_id_t id]()
    {
        return call TimeSyncAMSend32khz.maxPayloadLength[id]();
    }

    command void* TimeSyncAMSendMilli.getPayload[am_id_t id](message_t* msg, uint8_t len)
    {
        return call TimeSyncAMSend32khz.getPayload[id](msg, len);
    }

/*----------------- SubReceive -------------------*/

    event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len)
    {
        am_id_t id = call AMPacket.type(msg);
        return signal Receive.receive[id](msg, payload, len - sizeof(timesync_footer_t));
    }

    default event message_t* Receive.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) { return msg; }

/*----------------- SubSnoop -------------------*/

    event message_t* SubSnoop.receive(message_t* msg, void* payload, uint8_t len)
    {
        am_id_t id = call AMPacket.type(msg);
        return signal Snoop.receive[id](msg, payload, len - sizeof(timesync_footer_t));
    }

    default event message_t* Snoop.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) { return msg; }

/*----------------- SubSend.sendDone -------------------*/
    event void SubSend.sendDone(message_t* msg, error_t error)
    {
        am_id_t id = call AMPacket.type(msg);
        signal TimeSyncAMSend32khz.sendDone[id](msg, error);
        signal TimeSyncAMSendMilli.sendDone[id](msg, error);
    }

/*----------------- TimeSyncPacket32khz -----------------*/
    command bool TimeSyncPacket32khz.isValid(message_t* msg)
    {
        return call PacketTimeStamp32khz.isValid(msg) && getFooter(msg)->timestamp != CC2420_INVALID_TIMESTAMP;
    }

    command uint32_t TimeSyncPacket32khz.eventTime(message_t* msg)
    {
        return (uint32_t)(getFooter(msg)->timestamp) + call PacketTimeStamp32khz.timestamp(msg);
    }

/*----------------- TimeSyncPacketMilli -----------------*/
    command bool TimeSyncPacketMilli.isValid(message_t* msg)
    {
        return call PacketTimeStampMilli.isValid(msg) && getFooter(msg)->timestamp != CC2420_INVALID_TIMESTAMP;
    }

    command uint32_t TimeSyncPacketMilli.eventTime(message_t* msg)
    {
        return ((int32_t)(getFooter(msg)->timestamp) >> 5) + call PacketTimeStampMilli.timestamp(msg);
    }
}
