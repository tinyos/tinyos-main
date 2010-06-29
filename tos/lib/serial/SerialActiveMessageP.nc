//$Id: SerialActiveMessageP.nc,v 1.11 2010-06-29 22:07:50 scipio Exp $

/* Copyright (c) 2000-2005 The Regents of the University of California.  
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
 */

/**
 * Sending active messages over the serial port.
 *
 * @author Philip Levis
 * @author Ben Greenstein
 * @date August 7 2005
 *
 */

#include <Serial.h>

generic module SerialActiveMessageP () {
  provides {
    interface AMSend[am_id_t id];
    interface Receive[am_id_t id];
    interface AMPacket;
    interface Packet;
    interface PacketAcknowledgements;
  }
  uses {
    interface Send as SubSend;
    interface Receive as SubReceive;
  }
}
implementation {

  serial_header_t* ONE getHeader(message_t* ONE msg) {
    return TCAST(serial_header_t* ONE, (uint8_t*)msg + offsetof(message_t, data) - sizeof(serial_header_t));
  }

  serial_metadata_t* getMetadata(message_t* msg) {
    return (serial_metadata_t*)(msg->metadata);
  }
  
  command error_t AMSend.send[am_id_t id](am_addr_t dest,
					  message_t* msg,
					  uint8_t len) {
    serial_header_t* header = getHeader(msg);

    if (len > call Packet.maxPayloadLength()) {
      return ESIZE;
    }

    header->dest = dest;
    // Do not set the source address or group, as doing so
    // prevents transparent bridging. Need a better long-term
    // solution for this.
    //header->src = call AMPacket.address();
    //header->group = TOS_AM_GROUP;
    header->type = id;
    header->length = len;

    return call SubSend.send(msg, len);
  }

  command error_t AMSend.cancel[am_id_t id](message_t* msg) {
    return call SubSend.cancel(msg);
  }

  command uint8_t AMSend.maxPayloadLength[am_id_t id]() {
    return call Packet.maxPayloadLength();
  }

  command void* AMSend.getPayload[am_id_t id](message_t* m, uint8_t len) {
    return call Packet.getPayload(m, len);
  }
  
  event void SubSend.sendDone(message_t* msg, error_t result) {
    signal AMSend.sendDone[call AMPacket.type(msg)](msg, result);
  }

 default event void AMSend.sendDone[uint8_t id](message_t* msg, error_t result) {
   return;
 }

 default event message_t* Receive.receive[uint8_t id](message_t* msg, void* payload, uint8_t len) {
   return msg;
 }
 
 event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
    return signal Receive.receive[call AMPacket.type(msg)](msg, msg->data, len);
  }

  command void Packet.clear(message_t* msg) {
    memset(getHeader(msg), 0, sizeof(serial_header_t));
    return;
  }

  command uint8_t Packet.payloadLength(message_t* msg) {
    serial_header_t* header = getHeader(msg);    
    return header->length;
  }

  command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
    getHeader(msg)->length  = len;
  }
  
  command uint8_t Packet.maxPayloadLength() {
    return TOSH_DATA_LENGTH;
  }
  
  command void* Packet.getPayload(message_t* msg, uint8_t len) {
    if (len > call Packet.maxPayloadLength()) {
      return NULL;
    }
    else {
      return (void * COUNT_NOK(len))msg->data;
    }
  }

  command am_addr_t AMPacket.address() {
    return 0;
  }

  command am_addr_t AMPacket.destination(message_t* amsg) {
    serial_header_t* header = getHeader(amsg);
    return header->dest;
  }

  command am_addr_t AMPacket.source(message_t* amsg) {
    serial_header_t* header = getHeader(amsg);
    return header->src;
  }

  command void AMPacket.setDestination(message_t* amsg, am_addr_t addr) {
    serial_header_t* header = getHeader(amsg);
    header->dest = addr;
  }

  command void AMPacket.setSource(message_t* amsg, am_addr_t addr) {
    serial_header_t* header = getHeader(amsg);
    header->src = addr;
  }
  
  command bool AMPacket.isForMe(message_t* amsg) {
    return TRUE;
  }

  command am_id_t AMPacket.type(message_t* amsg) {
    serial_header_t* header = getHeader(amsg);
    return header->type;
  }

  command void AMPacket.setType(message_t* amsg, am_id_t type) {
    serial_header_t* header = getHeader(amsg);
    header->type = type;
  }

  async command error_t PacketAcknowledgements.requestAck( message_t* msg ) {
    return FAIL;
  }
  async command error_t PacketAcknowledgements.noAck( message_t* msg ) {
    return SUCCESS;
  }
  
  command void AMPacket.setGroup(message_t* msg, am_group_t group) {
    serial_header_t* header = getHeader(msg);
    header->group = group;
  }

  command am_group_t AMPacket.group(message_t* msg) {
    serial_header_t* header = getHeader(msg);
    return header->group;
  }

  command am_group_t AMPacket.localGroup() {
    return TOS_AM_GROUP;
  }

 
  async command bool PacketAcknowledgements.wasAcked(message_t* msg) {
    return FALSE;
  }

}
