// $Id: TossimActiveMessageC.nc,v 1.4 2007-09-25 00:07:59 scipio Exp $
/*
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 *
 * The basic chip-independent TOSSIM Active Message layer for radio chips
 * that do not have simulation support.
 *
 * @author Philip Levis
 * @date December 2 2005
 */

#include <AM.h>

module TossimActiveMessageC {
  provides {
    
    interface AMSend[am_id_t id];
    interface Receive[am_id_t id];
    interface Receive as Snoop[am_id_t id];

    interface Packet;
    interface AMPacket;
    interface TossimPacket;
  }
  uses {
    interface TossimPacketModel as Model;
    command am_addr_t amAddress();
  }
}
implementation {

  message_t buffer;
  message_t* bufferPointer = &buffer;
  
  tossim_header_t* getHeader(message_t* amsg) {
    return (tossim_header_t*)(amsg->data - sizeof(tossim_header_t));
  }

  tossim_metadata_t* getMetadata(message_t* amsg) {
    return (tossim_metadata_t*)(&amsg->metadata);
  }
  
  command error_t AMSend.send[am_id_t id](am_addr_t addr,
					  message_t* amsg,
					  uint8_t len) {
    error_t err;
    tossim_header_t* header = getHeader(amsg);
    dbg("AM", "AM: Sending packet (id=%hhu, len=%hhu) to %hu\n", id, len, addr);
    header->type = id;
    header->dest = addr;
    header->src = call AMPacket.address();
    header->length = len;
    err = call Model.send((int)addr, amsg, len + sizeof(tossim_header_t));
    return err;
  }

  command error_t AMSend.cancel[am_id_t id](message_t* msg) {
    return call Model.cancel(msg);
  }
  
  command uint8_t AMSend.maxPayloadLength[am_id_t id]() {
    return call Packet.maxPayloadLength();
  }

  command void* AMSend.getPayload[am_id_t id](message_t* m, uint8_t len) {
    return call Packet.getPayload(m, len);
  }

  command int8_t TossimPacket.strength(message_t* msg) {
    return getMetadata(msg)->strength;
  }
  
  event void Model.sendDone(message_t* msg, error_t result) {
    signal AMSend.sendDone[call AMPacket.type(msg)](msg, result);
  }

  /* Receiving a packet */

  event void Model.receive(message_t* msg) {
    uint8_t len;
    void* payload;

    memcpy(bufferPointer, msg, sizeof(message_t));
    len = call Packet.payloadLength(bufferPointer);
    payload = call Packet.getPayload(bufferPointer, call Packet.maxPayloadLength());

    if (call AMPacket.isForMe(msg)) {
      dbg("AM", "Received active message (%p) of type %hhu and length %hhu for me @ %s.\n", bufferPointer, call AMPacket.type(bufferPointer), len, sim_time_string());
      bufferPointer = signal Receive.receive[call AMPacket.type(bufferPointer)](bufferPointer, payload, len);
    }
    else {
      dbg("AM", "Snooped on active message of type %hhu and length %hhu for %hu @ %s.\n", call AMPacket.type(bufferPointer), len, call AMPacket.destination(bufferPointer), sim_time_string());
      bufferPointer = signal Snoop.receive[call AMPacket.type(bufferPointer)](bufferPointer, payload, len);
    }
  }

  event bool Model.shouldAck(message_t* msg) {
    tossim_header_t* header = getHeader(msg);
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
    tossim_header_t* header = getHeader(amsg);
    return header->dest;
  }

  command void AMPacket.setDestination(message_t* amsg, am_addr_t addr) {
    tossim_header_t* header = getHeader(amsg);
    header->dest = addr;
  }

  command am_addr_t AMPacket.source(message_t* amsg) {
    tossim_header_t* header = getHeader(amsg);
    return header->src;
  }

  command void AMPacket.setSource(message_t* amsg, am_addr_t addr) {
    tossim_header_t* header = getHeader(amsg);
    header->src = addr;
  }
  
  command bool AMPacket.isForMe(message_t* amsg) {
    return (call AMPacket.destination(amsg) == call AMPacket.address() ||
	    call AMPacket.destination(amsg) == AM_BROADCAST_ADDR);
  }

  command am_id_t AMPacket.type(message_t* amsg) {
    tossim_header_t* header = getHeader(amsg);
    return header->type;
  }

  command void AMPacket.setType(message_t* amsg, am_id_t t) {
    tossim_header_t* header = getHeader(amsg);
    header->type = t;
  }
 
  command void Packet.clear(message_t* msg) {}
  
  command uint8_t Packet.payloadLength(message_t* msg) {
    return getHeader(msg)->length;
  }
  
  command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
    getHeader(msg)->length = len;
  }
  
  command uint8_t Packet.maxPayloadLength() {
    return TOSH_DATA_LENGTH;
  }
  
  command void* Packet.getPayload(message_t* msg, uint8_t len) {
    if (len <= TOSH_DATA_LENGTH) {
      return msg->data;
    }
    else {
      return NULL;
    }
  }

  command am_group_t AMPacket.group(message_t* amsg) {
    tossim_header_t* header = getHeader(amsg);
    return header->group;
  }
  
  command void AMPacket.setGroup(message_t* msg, am_group_t group) {
    tossim_header_t* header = getHeader(msg);
    header->group = group;
  }

  command am_group_t AMPacket.localGroup() {
    return TOS_AM_GROUP;
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

 default command error_t Model.send(int node, message_t* msg, uint8_t len) {
   return FAIL;
 }

 default command error_t Model.cancel(message_t* msg) {
   return FAIL;
 }

 default command am_addr_t amAddress() {
   return 0;
 }
  
 void active_message_deliver_handle(sim_event_t* evt) {
   message_t* m = (message_t*)evt->data;
   dbg("Packet", "Delivering packet to %i at %s\n", (int)sim_node(), sim_time_string());
   signal Model.receive(m);
 }
 
 sim_event_t* allocate_deliver_event(int node, message_t* msg, sim_time_t t) {
   sim_event_t* evt = (sim_event_t*)malloc(sizeof(sim_event_t));
   evt->mote = node;
   evt->time = t;
   evt->handle = active_message_deliver_handle;
   evt->cleanup = sim_queue_cleanup_event;
   evt->cancelled = 0;
   evt->force = 0;
   evt->data = msg;
   return evt;
 }
 
 void active_message_deliver(int node, message_t* msg, sim_time_t t) __attribute__ ((C, spontaneous)) {
   sim_event_t* evt = allocate_deliver_event(node, msg, t);
   sim_queue_insert(evt);
 }
 
}
