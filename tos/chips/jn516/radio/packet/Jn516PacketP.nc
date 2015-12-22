/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
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
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * @author Jonathan Hui <jhui@archrock.com>
 * @author David Moss
 * @author Chad Metcalf
 */

#include "IEEE802154.h"
#include "message.h"
#include "Jn516.h"

module Jn516PacketP {
	provides {
		interface Packet as BarePacket;
		interface Jn516Packet;
		interface Jn516PacketBody;
		interface LinkPacketMetadata;
	}
}

implementation {

  /***************** BarePacket Commands ****************/
  command void BarePacket.clear(message_t *msg) {
    memset(msg, 0, sizeof(message_t));
  }

  command uint8_t BarePacket.payloadLength(message_t *msg) {
    jn516_header_t *hdr = call Jn516PacketBody.getHeader(msg);
    return hdr->length + 1 - MAC_FOOTER_SIZE;
  }

  command void BarePacket.setPayloadLength(message_t* msg, uint8_t len) {
    jn516_header_t *hdr = call Jn516PacketBody.getHeader(msg);
    hdr->length = len - 1 + MAC_FOOTER_SIZE;
  }

  command uint8_t BarePacket.maxPayloadLength() {
    return TOSH_DATA_LENGTH + sizeof(jn516_header_t);
  }

  command void* BarePacket.getPayload(message_t* msg, uint8_t len) {

  }

  /***************** Jn516Packet Commands ****************/
  
  int getAddressLength(int type) {
    switch (type) {
    case IEEE154_ADDR_SHORT: return 2;
    case IEEE154_ADDR_EXT: return 8;
    case IEEE154_ADDR_NONE: return 0;
    default: return -100;
    }
  }
  
  uint8_t * ONE getNetwork(message_t * ONE msg) {
    jn516_header_t *hdr = (call Jn516PacketBody.getHeader( msg ));
    int offset;
    
    offset = getAddressLength((hdr->fcf >> IEEE154_FCF_DEST_ADDR_MODE) & 0x3) +
      getAddressLength((hdr->fcf >> IEEE154_FCF_SRC_ADDR_MODE) & 0x3) + 
      offsetof(jn516_header_t, dest);

    return ((uint8_t *)hdr) + offset;
  }

  async command void Jn516Packet.setPower( message_t* p_msg, uint8_t power ) {
    if ( power > 31 )
      power = 31;
    (call Jn516PacketBody.getMetadata( p_msg ))->tx_power = power;
  }

  async command uint8_t Jn516Packet.getPower( message_t* p_msg ) {
    return (call Jn516PacketBody.getMetadata( p_msg ))->tx_power;
  }
   
  async command int8_t Jn516Packet.getRssi( message_t* p_msg ) {
    return (call Jn516PacketBody.getMetadata( p_msg ))->rssi;
  }

  async command uint8_t Jn516Packet.getLqi( message_t* p_msg ) {
    return (call Jn516PacketBody.getMetadata( p_msg ))->lqi;
  }

  async command uint8_t Jn516Packet.getNetwork( message_t* ONE p_msg ) {
#if defined(TFRAMES_ENABLED)
    return TINYOS_6LOWPAN_NETWORK_ID;
#else
    atomic 
      return *(getNetwork(p_msg));
#endif
  }

  async command void Jn516Packet.setNetwork( message_t* ONE p_msg , uint8_t networkId ) {
#if ! defined(TFRAMES_ENABLED)
    atomic 
      *(getNetwork(p_msg)) = networkId;
#endif
  }    



  /***************** Jn516PacketBody Commands ****************/
  async command jn516_header_t * ONE Jn516PacketBody.getHeader( message_t* ONE msg ) {
    return TCAST(jn516_header_t* ONE, (uint8_t *)msg + offsetof(message_t, data) - sizeof( jn516_header_t ));
  }

  async command uint8_t * Jn516PacketBody.getPayload( message_t* msg) {
    jn516_header_t *hdr = (call Jn516PacketBody.getHeader( msg ));
    int offset;
    
    offset = getAddressLength((hdr->fcf >> IEEE154_FCF_DEST_ADDR_MODE) & 0x3) +
      getAddressLength((hdr->fcf >> IEEE154_FCF_SRC_ADDR_MODE) & 0x3) + 
      offsetof(jn516_header_t, dest);

    return ((uint8_t *)hdr) + offset;
  }

  async command jn516_metadata_t *Jn516PacketBody.getMetadata( message_t* msg ) {
    return (jn516_metadata_t*)msg->metadata;
  }

  async command bool LinkPacketMetadata.highChannelQuality(message_t* msg) {
    return call Jn516Packet.getLqi(msg) > 105;
  }

}
