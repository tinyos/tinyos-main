// $Id: ActiveMessageC.nc,v 1.6 2008-04-24 06:52:12 klueska Exp $
/*
 * Copyright (c) 2005-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Dummy implementation to support the null platform.
 */

module ActiveMessageC {
  provides {
    interface SplitControl;

    interface AMSend[uint8_t id];
    interface Receive[uint8_t id];
    interface Receive as Snoop[uint8_t id];

    interface Packet;
    interface AMPacket;
    interface PacketAcknowledgements as Acks;
  }
}
implementation {


  command error_t SplitControl.start() {
    return SUCCESS;
  }

  command error_t SplitControl.stop() {
    return SUCCESS;
  }

  command error_t AMSend.send[uint8_t id](am_addr_t addr, message_t* msg, uint8_t len) {
    return SUCCESS;
  }

  command error_t AMSend.cancel[uint8_t id](message_t* msg) {
    return SUCCESS;
  }

  command uint8_t AMSend.maxPayloadLength[uint8_t id]() {
    return 0;
  }

  command void* AMSend.getPayload[uint8_t id](message_t* msg, uint8_t len) {
    return NULL;
  }

  command void Packet.clear(message_t* msg) {
  }

  command uint8_t Packet.payloadLength(message_t* msg) {
    return 0;
  }

  command uint8_t Packet.maxPayloadLength() {
    return 0;
  }

  command void* Packet.getPayload(message_t* msg, uint8_t len) {
    return msg;
  }

  command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
  }

  command am_addr_t AMPacket.address() {
    return 0;
  }

  command am_addr_t AMPacket.destination(message_t* amsg) {
    return 0;
  }

  command bool AMPacket.isForMe(message_t* amsg) {
    return FALSE;
  }

  command am_id_t AMPacket.type(message_t* amsg) {
    return 0;
  }

  command void AMPacket.setDestination(message_t* amsg, am_addr_t addr) {
  }

  command void AMPacket.setType(message_t* amsg, am_id_t t) {
  }

  command am_addr_t AMPacket.source(message_t* amsg) {
    return 0;
  }

  command void AMPacket.setSource(message_t* amsg, am_addr_t addr) { }
  
  command am_group_t AMPacket.group(message_t* amsg) {
    return 0;
  }

  command void AMPacket.setGroup(message_t* amsg, am_group_t grp) { }

  command am_group_t AMPacket.localGroup() {
    return 0;
  }

  async command error_t Acks.requestAck( message_t* msg ) {
    return SUCCESS;
  }

  async command error_t Acks.noAck( message_t* msg ) {
    return SUCCESS;
  }

  async command bool Acks.wasAcked(message_t* msg) {
    return FALSE;
  }
}
