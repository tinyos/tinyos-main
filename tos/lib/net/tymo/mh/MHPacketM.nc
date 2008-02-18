/*
 * Copyright (c) 2007 Romain Thouvenin <romain.thouvenin@gmail.com>
 * Published under the terms of the GNU General Public License (GPLv2).
 */

#include "mhpacket.h"

#define HEADER  ((mhpacket_header_t *)(call SubPacket.getPayload(amsg, call SubPacket.maxPayloadLength())))

/**
 * MHPacketM - Implements ActiveMessage on top of ActiveMessage,
 * to transport data in a multihop network.
 *
 * @author Romain Thouvenin
 */

module MHPacketM {
  provides {
    interface Packet;
    interface AMPacket as MHPacket;
  }
  uses {
    interface Packet as SubPacket;
    interface AMPacket;
  }
}

implementation {
  
  /**********
   * Packet *
   **********/

  command void Packet.clear(message_t *msg){
    call SubPacket.clear(msg);
  }

  command void * Packet.getPayload(message_t *msg, uint8_t len){
    nx_uint8_t * p = call SubPacket.getPayload(msg, len);
    return (void *)(p + sizeof(mhpacket_header_t));
  }

  command uint8_t Packet.maxPayloadLength(){
    return call SubPacket.maxPayloadLength() - sizeof(mhpacket_header_t);
  }

  command uint8_t Packet.payloadLength(message_t *amsg){
    return HEADER->len;
  }

  command void Packet.setPayloadLength(message_t *amsg, uint8_t len){
    HEADER->len = len;
    call SubPacket.setPayloadLength(amsg, len + sizeof(mhpacket_header_t));
  }

  
  /**********
   * AMPacket *
   **********/

  command am_addr_t MHPacket.address(){
    return call AMPacket.address();
  }

  command am_addr_t MHPacket.destination(message_t *amsg){
    return HEADER->dest;
  }

  command bool MHPacket.isForMe(message_t *amsg){
    return ((HEADER->dest == call MHPacket.address()) || (HEADER->dest == AM_BROADCAST_ADDR));
  }

  command void MHPacket.setDestination(message_t *amsg, am_addr_t addr){
    HEADER->dest = addr;
  }

  command void MHPacket.setSource(message_t *amsg, am_addr_t addr){
    HEADER->src = addr;
  }

  command void MHPacket.setType(message_t *amsg, am_id_t t){
    HEADER->type = t;
    call AMPacket.setType(amsg, AM_MULTIHOP);
  }

  command am_addr_t MHPacket.source(message_t *amsg){
    return HEADER->src;
  }

  command am_id_t MHPacket.type(message_t *amsg){
    return HEADER->type;
  }

  /* *** UNIMPLEMENTED ! *** */
  //TODO what to do with this?

  command am_group_t MHPacket.group(message_t* amsg) {
    return 0;
  }

  command void MHPacket.setGroup(message_t* amsg, am_group_t grp) { }

  command am_group_t MHPacket.localGroup() {
    return 0;
  }

}
