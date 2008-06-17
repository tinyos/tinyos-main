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

        interface TimeSyncPacket<T32khz, uint32_t> as TimeSyncPacket32khz;
        interface TimeSyncPacket<TMilli, uint32_t> as TimeSyncPacketMilli;
    }

    uses
    {
        interface AMSend as SubSend[uint8_t id];
        interface Packet as SubPacket;

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
    inline void* getFooter(message_t* msg)
    {
        // we use the payload length that we export (the smaller one)
        return msg->data + call Packet.payloadLength(msg);
    }

/*----------------- Packet -----------------*/
    command void Packet.clear(message_t* msg)
    {
        call PacketTimeSyncOffset.cancel(msg);
        call SubPacket.clear(msg);
    }

    command void Packet.setPayloadLength(message_t* msg, uint8_t len)
    {
        call SubPacket.setPayloadLength(msg, len + sizeof(timesync_radio_t));
    }

    command uint8_t Packet.payloadLength(message_t* msg)
    {
        return call SubPacket.payloadLength(msg) - sizeof(timesync_radio_t);
    }

    command uint8_t Packet.maxPayloadLength()
    {
        return call SubPacket.maxPayloadLength() - sizeof(timesync_radio_t);
    }

    command void* Packet.getPayload(message_t* msg, uint8_t len)
    {
        return call SubPacket.getPayload(msg, len + sizeof(timesync_radio_t));
    }

/*----------------- TimeSyncAMSend32khz -----------------*/
    command error_t TimeSyncAMSend32khz.send[am_id_t id](am_addr_t addr, message_t* msg, uint8_t len, uint32_t event_time)
    {
        error_t err;
        void * timesync = msg->data + len;
        *(timesync_radio_t*)timesync = event_time;

        err = call SubSend.send[id](addr, msg, len + sizeof(timesync_radio_t));
        call PacketTimeSyncOffset.set(msg);
        return err;
    }

    command error_t TimeSyncAMSend32khz.cancel[am_id_t id](message_t* msg)
    {
        call PacketTimeSyncOffset.cancel(msg);
        return call SubSend.cancel[id](msg);
    }

    default event void TimeSyncAMSend32khz.sendDone[am_id_t id](message_t* msg, error_t error) {}

    command uint8_t TimeSyncAMSend32khz.maxPayloadLength[am_id_t id]()
    {
        return call SubSend.maxPayloadLength[id]() - sizeof(timesync_radio_t);
    }

    command void* TimeSyncAMSend32khz.getPayload[am_id_t id](message_t* msg, uint8_t len)
    {
        return call SubSend.getPayload[id](msg, len + sizeof(timesync_radio_t));
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

/*----------------- SubSend.sendDone -------------------*/
    event void SubSend.sendDone[am_id_t id](message_t* msg, error_t error)
    {
        signal TimeSyncAMSend32khz.sendDone[id](msg, error);
        signal TimeSyncAMSendMilli.sendDone[id](msg, error);
    }

/*----------------- TimeSyncPacket32khz -----------------*/
    command bool TimeSyncPacket32khz.isValid(message_t* msg)
    {
        timesync_radio_t* timesync = getFooter(msg);
        return call PacketTimeStamp32khz.isValid(msg) && *timesync != CC2420_INVALID_TIMESTAMP;
    }

    command uint32_t TimeSyncPacket32khz.eventTime(message_t* msg)
    {
        timesync_radio_t* timesync = getFooter(msg);

        return (uint32_t)(*timesync) + call PacketTimeStamp32khz.timestamp(msg);
    }

/*----------------- TimeSyncPacketMilli -----------------*/
    command bool TimeSyncPacketMilli.isValid(message_t* msg)
    {
        timesync_radio_t* timesync = getFooter(msg);
        return call PacketTimeStampMilli.isValid(msg) && *timesync != CC2420_INVALID_TIMESTAMP;
    }

    command uint32_t TimeSyncPacketMilli.eventTime(message_t* msg)
    {
        timesync_radio_t* timesync = getFooter(msg);
        return ((int32_t)(*timesync) >> 5) + call PacketTimeStampMilli.timestamp(msg);
    }
}
