/* 
 * Copyright (c) 2006, Ecole Polytechnique Federale de Lausanne (EPFL),
 * Switzerland.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Ecole Polytechnique Federale de Lausanne (EPFL) 
 *   nor the names of its contributors may be used to 
 *   endorse or promote products derived from this software without 
 *   specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ========================================================================
 */

/*
 * @author Henri Dubois-Ferriere
 *
 */
module XE1205ActiveMessageP {
    uses interface Packet;
    uses interface Send as SubSend;
    uses interface Receive as SubReceive;
    uses command am_addr_t amAddress();

    provides interface AMSend[am_id_t id];
    provides interface AMPacket;
    provides interface Receive[am_id_t id];
    provides interface Receive as Snoop[am_id_t id];
}
implementation {
  // xxx - this is replicated in ActiveMessageP.
  // put in XE1205.h?
  xe1205_header_t* getHeader( message_t* msg ) {
    return (xe1205_header_t*)( msg->data - sizeof(xe1205_header_t) );
  }

  command am_addr_t AMPacket.address() {
    return call amAddress();
  }
 
  command am_addr_t AMPacket.destination(message_t* msg) {
    xe1205_header_t* header = getHeader(msg);
    return header->dest;
  }

  command void AMPacket.setDestination(message_t* msg, am_addr_t addr) {
    xe1205_header_t* header = getHeader(msg);
    header->dest = addr;
  }
  
  command am_addr_t AMPacket.source(message_t* msg) {
    xe1205_header_t* header = getHeader(msg);
    return header->source;
  }

  command void AMPacket.setSource(message_t* msg, am_addr_t addr) {
    xe1205_header_t* header = getHeader(msg);
    header->source = addr;
  }
  
  command bool AMPacket.isForMe(message_t* msg) {
    return (call AMPacket.destination(msg) == call AMPacket.address() ||
	    call AMPacket.destination(msg) == AM_BROADCAST_ADDR);
  }

  command am_id_t AMPacket.type(message_t* msg) {
    xe1205_header_t* header = getHeader(msg);
    return header->type;
  }

  command void AMPacket.setType(message_t* msg, am_id_t type) {
    xe1205_header_t* header = getHeader(msg);
    header->type = type;
  }

  command uint8_t AMSend.maxPayloadLength[am_id_t id]() {
    return call Packet.maxPayloadLength();
  }

  command void* AMSend.getPayload[am_id_t id](message_t* m) {
    return call Packet.getPayload(m, NULL);
  }

  command error_t AMSend.send[am_id_t id](am_addr_t addr, 
					  message_t* msg, 
					  uint8_t len) {
    xe1205_header_t* header = getHeader(msg);
    header->type = id;
    header->dest = addr;
    header->source = call AMPacket.address();
    header->group = TOS_AM_GROUP;
    return call SubSend.send(msg, len);
  }

  command error_t AMSend.cancel[am_id_t id](message_t* msg) {
    return call SubSend.cancel(msg);
  }

  event void SubSend.sendDone(message_t* msg, error_t result) {
    signal AMSend.sendDone[call AMPacket.type(msg)](msg, result);
  }

 default event void AMSend.sendDone[uint8_t id](message_t* msg, error_t err) {
   return;
 }

  event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) __attribute__ ((noinline)) {
    if (call AMPacket.isForMe(msg)) {
      return signal Receive.receive[call AMPacket.type(msg)](msg, payload, len);
    }
    else {
      return signal Snoop.receive[call AMPacket.type(msg)](msg, payload, len);
    }
  }
  
  default event message_t* Receive.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) {
    return msg;
  }
  default event message_t* Snoop.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) {
    return msg;
  }

  command void* Receive.getPayload[am_id_t id](message_t* m, uint8_t* len) {
    return call Packet.getPayload(m, len);
  }

  command uint8_t Receive.payloadLength[am_id_t id](message_t* m) {
    return call Packet.payloadLength(m);
  }
  
  command void* Snoop.getPayload[am_id_t id](message_t* m, uint8_t* len) {
    return call Packet.getPayload(m, len);
  }

  command uint8_t Snoop.payloadLength[am_id_t id](message_t* m) {
    return call Packet.payloadLength(m);
  }
  
}

