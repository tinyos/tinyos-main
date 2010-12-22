// $Id: SerialActiveMessageC.nc,v 1.3 2010-06-22 20:50:43 scipio Exp $
/*
 * Copyright (c) 2007 Toilers Research Group - Colorado School of Mines
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of Toilers Research Group - Colorado School of 
 *   Mines  nor the names of its contributors may be used to endorse 
 *   or promote products derived from this software without specific
 *   prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/**
 * Author: Chad Metcalf
 * Date: July 9, 2007
 *
 * The Serial Active Message implementation for use with the TOSSIM Live
 * extensions.
 *
 */

#include <AM.h>
#include <Serial.h>
#include "sim_serial_forwarder.h"

module SerialActiveMessageC {
    provides {
        interface SplitControl;

        interface AMSend[am_id_t id];
        interface Receive[am_id_t id];
        interface Receive as Snoop[am_id_t id];

        interface Packet;
        interface AMPacket;
        interface PacketAcknowledgements as Acks;
    }
    uses {
        interface TossimPacketModel as Model;
        command am_addr_t amAddress();
    }
}
implementation {

    message_t buffer;
    message_t* bufferPointer = &buffer;
    
    message_t* sendMsgPtr = NULL;

    serial_header_t* getHeader(message_t* amsg) {
        return (serial_header_t*)(amsg->data - sizeof(serial_header_t));
    }

    task void startDone() { signal SplitControl.startDone(SUCCESS); }
    task void stopDone() { signal SplitControl.stopDone(SUCCESS); }

    command error_t SplitControl.start() {
        post startDone();
        return SUCCESS;
    }

    command error_t SplitControl.stop() {
        post stopDone();
        return SUCCESS;
    }

    command error_t AMSend.send[am_id_t id](am_addr_t addr,
                                            message_t* amsg,
                                            uint8_t len) {
        error_t err;
        serial_header_t* header = getHeader(amsg);
        
        header->type = id;
        header->dest = addr;
        // For out going serial messages we'll use the real TOS_NODE_ID
        header->src = TOS_NODE_ID;
        header->length = len;
        err = call Model.send((int)addr, amsg, len + sizeof(serial_header_t));
        return err;
    }

    command error_t AMSend.cancel[am_id_t id](message_t* msg) {
        dbg("Serial", "SerialAM: cancelled a packet\n");
        return call Model.cancel(msg);
    }

    command uint8_t AMSend.maxPayloadLength[am_id_t id]() {
        return call Packet.maxPayloadLength();
    }

    command void* AMSend.getPayload[am_id_t id](message_t* m, uint8_t len) {
        return call Packet.getPayload(m, len);
    }

    event void Model.sendDone(message_t* msg, error_t result) {
        signal AMSend.sendDone[call AMPacket.type(msg)](msg, result);
    }

    task void modelSendDone ()
    {
        signal Model.sendDone(sendMsgPtr, SUCCESS);
    }

    default command error_t Model.send(int node, message_t* msg, uint8_t len) {

        sendMsgPtr = msg;

        dbg("Serial", "Sending serial message (%p) of type %hhu and length %hhu @ %s.\n",
            msg, call AMPacket.type(msg), len, sim_time_string());
        sim_sf_dispatch_packet((void*)msg, len);
        
        post modelSendDone ();

        return SUCCESS;
    }

    /* Receiving a packet */

    event void Model.receive(message_t* msg) {
        uint8_t len;
        void* payload;

        memcpy(bufferPointer, msg, sizeof(message_t));
	
	if (msg != NULL) {
	  free(msg);
	}
	
        payload = call Packet.getPayload(bufferPointer, call Packet.maxPayloadLength());
        len = call Packet.payloadLength(bufferPointer);

        dbg("Serial", "Received serial message (%p) of type %hhu and length %hhu @ %s.\n",
            bufferPointer, call AMPacket.type(bufferPointer), len, sim_time_string());
        bufferPointer = signal Receive.receive[call AMPacket.type(bufferPointer)]
            (bufferPointer, payload, len);
    }

    event bool Model.shouldAck(message_t* msg) {
        serial_header_t* header = getHeader(msg);
        if (header->dest == call amAddress()) {
            dbg("Acks", "Received packet addressed to me so ack it\n");
            return TRUE;
        }
        return FALSE;
    }

    command am_addr_t AMPacket.address() {
        return call amAddress();
    }

    command am_addr_t AMPacket.destination(message_t* amsg) {
        serial_header_t* header = getHeader(amsg);
        return header->dest;
    }

    command void AMPacket.setDestination(message_t* amsg, am_addr_t addr) {
        serial_header_t* header = getHeader(amsg);
        header->dest = addr;
    }

    command am_addr_t AMPacket.source(message_t* amsg) {
        serial_header_t* header = getHeader(amsg);
        return header->src;
    }

    command void AMPacket.setSource(message_t* amsg, am_addr_t addr) {
        serial_header_t* header = getHeader(amsg);
        header->src = addr;
    }

    command bool AMPacket.isForMe(message_t* amsg) {
        return (call AMPacket.destination(amsg) == call AMPacket.address() ||
                call AMPacket.destination(amsg) == AM_BROADCAST_ADDR);
    }

    command am_id_t AMPacket.type(message_t* amsg) {
        serial_header_t* header = getHeader(amsg);
        return header->type;
    }

    command void AMPacket.setType(message_t* amsg, am_id_t t) {
        serial_header_t* header = getHeader(amsg);
        header->type = t;
    }

    command am_group_t AMPacket.group(message_t* amsg) {
        serial_header_t* header = getHeader(amsg);
        return header->group;
    }

    command void AMPacket.setGroup(message_t* msg, am_group_t group) {
        serial_header_t* header = getHeader(msg);
        header->group = group;
    }

    command am_group_t AMPacket.localGroup() {
        return TOS_AM_GROUP;
    }
    command void Packet.clear(message_t* msg) {}

    command void* Packet.getPayload(message_t* msg, uint8_t len) {
        if (len <= TOSH_DATA_LENGTH) {
            return msg->data;
        } else {
            return NULL;
        }
    }

    command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
        getHeader(msg)->length = len;
    }

    command uint8_t Packet.maxPayloadLength() {
        return TOSH_DATA_LENGTH;
    }

    command uint8_t Packet.payloadLength(message_t* msg) {
        return getHeader(msg)->length;
    }

    async command error_t Acks.requestAck(message_t* msg) {
        return FAIL;
    }

    async command error_t Acks.noAck(message_t* msg) {
        return SUCCESS;
    }

    async command bool Acks.wasAcked(message_t* msg) {
        return FALSE;
    }
    default event message_t* Receive.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) {
        return msg;
    }

    default event message_t* Snoop.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) {
        return msg;
    }

    default event void AMSend.sendDone[uint8_t id](message_t* msg, error_t err) {
        return;
    }

    default command error_t Model.cancel(message_t* msg) {
        return FAIL;
    }

    default command am_addr_t amAddress() {
        return 0;
    }

    void serial_active_message_deliver_handle(sim_event_t* evt) {
        message_t* m = (message_t*)evt->data;
        signal Model.receive(m);
    }

    sim_event_t* allocate_serial_deliver_event(int node, message_t* msg, sim_time_t t) {
        sim_event_t* evt = (sim_event_t*)malloc(sizeof(sim_event_t));
	message_t* newMsg = (message_t*)malloc(sizeof(message_t));
        uint8_t payloadLength = ((serial_header_t*)msg->header)->length;
        memcpy(getHeader(newMsg), msg, sizeof(serial_header_t) + payloadLength);
	
        evt->mote = node;
        evt->time = t;
        evt->handle = serial_active_message_deliver_handle;
        evt->cleanup = sim_queue_cleanup_event;
        evt->cancelled = 0;
        evt->force = 0;
        evt->data = newMsg;
        return evt;
    }

    void serial_active_message_deliver(int node, message_t* msg, sim_time_t t) @C() @spontaneous() {
        sim_event_t* evt = allocate_serial_deliver_event(node, msg, t);
        sim_queue_insert(evt);
    }
}
