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
#include "CC2520.h"
#include "CC2520TimeSyncMessage.h"

module CC2520PacketP @safe() {

  provides {
    interface CC2520Packet;
    interface PacketAcknowledgements as Acks;
    interface CC2520PacketBody;
    interface LinkPacketMetadata;

    interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;
    interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
    interface PacketTimeSyncOffset;
  }

  uses interface LocalTime<T32khz> as LocalTime32khz;
  uses interface LocalTime<TMilli> as LocalTimeMilli;
}

implementation {


  


  /***************** PacketAcknowledgement Commands ****************/
  async command error_t Acks.requestAck( message_t* p_msg ) {
    (call CC2520PacketBody.getHeader( p_msg ))->fcf |= 1 << IEEE154_FCF_ACK_REQ;
    return SUCCESS;
  }

  async command error_t Acks.noAck( message_t* p_msg ) {
    (call CC2520PacketBody.getHeader( p_msg ))->fcf &= ~(1 << IEEE154_FCF_ACK_REQ);
    return SUCCESS;
  }

  async command bool Acks.wasAcked( message_t* p_msg ) {
    return (call CC2520PacketBody.getMetadata( p_msg ))->ack;
  }

  /***************** CC2420Packet Commands ****************/

 int getAddressLength(int type) {
    switch (type) {
    case IEEE154_ADDR_SHORT: return 2;
    case IEEE154_ADDR_EXT: return 8;
    case IEEE154_ADDR_NONE: return 0;
    default: return -100;
    }
  }
  
  uint8_t * ONE getNetwork(message_t * ONE msg) {
    cc2520_header_t *hdr = (call CC2520PacketBody.getHeader( msg ));
    int offset;
    
    offset = getAddressLength((hdr->fcf >> IEEE154_FCF_DEST_ADDR_MODE) & 0x3) +
      getAddressLength((hdr->fcf >> IEEE154_FCF_SRC_ADDR_MODE) & 0x3) + 
      offsetof(cc2520_header_t, dest);

    return ((uint8_t *)hdr) + offset;
  }

  async command void CC2520Packet.setPower( message_t* p_msg, uint8_t power ) {
    if ( power > 31 )
      power = 31;
    (call CC2520PacketBody.getMetadata( p_msg ))->tx_power = power;
  }

  async command uint8_t CC2520Packet.getPower( message_t* p_msg ) {
    return (call CC2520PacketBody.getMetadata( p_msg ))->tx_power;
  }
   
  async command int8_t CC2520Packet.getRssi( message_t* p_msg ) {
    return (call CC2520PacketBody.getMetadata( p_msg ))->rssi;
  }

  async command uint8_t CC2520Packet.getLqi( message_t* p_msg ) {
    return (call CC2520PacketBody.getMetadata( p_msg ))->lqi;
  }

  async command uint8_t CC2520Packet.getNetwork( message_t* ONE p_msg ) {
#if defined(TFRAMES_ENABLED)
    return TINYOS_6LOWPAN_NETWORK_ID;
#else
    atomic 
      return *(getNetwork(p_msg));
#endif
  }

  async command void CC2520Packet.setNetwork( message_t* ONE p_msg , uint8_t networkId ) {
#if ! defined(TFRAMES_ENABLED)
    atomic 
      *(getNetwork(p_msg)) = networkId;
#endif
  }    

  /***************** CC2420PacketBody Commands ****************/
  async command cc2520_header_t * ONE CC2520PacketBody.getHeader( message_t* ONE msg ) {
    return TCAST(cc2520_header_t* ONE, (uint8_t *)msg + offsetof(message_t, data) - sizeof( cc2520_header_t ));
  }

  async command uint8_t * CC2520PacketBody.getPayload( message_t* msg) {
    cc2520_header_t *hdr = (call CC2520PacketBody.getHeader( msg ));
    int offset;
    
    offset = getAddressLength((hdr->fcf >> IEEE154_FCF_DEST_ADDR_MODE) & 0x3) +
      getAddressLength((hdr->fcf >> IEEE154_FCF_SRC_ADDR_MODE) & 0x3) + 
      offsetof(cc2520_header_t, dest);
#ifdef CC2520_HW_SECURITY
	offset += 5;
#endif
#ifdef CC2520_IFRAME_TYPE
  	offset += 1;
#endif
    return ((uint8_t *)hdr) + offset;
  }


  async command cc2520_metadata_t *CC2520PacketBody.getMetadata( message_t* msg ) {
		
    return (cc2520_metadata_t*)msg->metadata;
  }

  async command bool LinkPacketMetadata.highChannelQuality(message_t* msg) {
    return call CC2520Packet.getLqi(msg) > 105;
  }

  /***************** PacketTimeStamp32khz Commands ****************/
  async command bool PacketTimeStamp32khz.isValid(message_t* msg)
  {
	
      //call CC2520PacketBody.getMetadata( msg )->timestamp = 0;
    return ((call CC2520PacketBody.getMetadata( msg ))->timestamp != CC2520_INVALID_TIMESTAMP);
  }

  async command uint32_t PacketTimeStamp32khz.timestamp(message_t* msg)
  {
   	
    return (call CC2520PacketBody.getMetadata( msg ))->timestamp;
  }

  async command void PacketTimeStamp32khz.clear(message_t* msg)
  {
    (call CC2520PacketBody.getMetadata( msg ))->timesync = FALSE;
    (call CC2520PacketBody.getMetadata( msg ))->timestamp = CC2520_INVALID_TIMESTAMP;
   
  }

  async command void PacketTimeStamp32khz.set(message_t* msg, uint32_t value)
  {
    (call CC2520PacketBody.getMetadata( msg ))->timestamp = value;
 	
  }

  /***************** PacketTimeStampMilli Commands ****************/
  // over the air value is always T32khz, which is used to capture SFD interrupt
  // (Timer1 on micaZ, B1 on telos)
  async command bool PacketTimeStampMilli.isValid(message_t* msg)
  {
    return call PacketTimeStamp32khz.isValid(msg);
  }

  async command uint32_t PacketTimeStampMilli.timestamp(message_t* msg)
  {
    int32_t offset = call PacketTimeStamp32khz.timestamp(msg) - call LocalTime32khz.get();

    return (offset >> 5) + call LocalTimeMilli.get();
  }

  async command void PacketTimeStampMilli.clear(message_t* msg)
  {
    call PacketTimeStamp32khz.clear(msg);
  }

  async command void PacketTimeStampMilli.set(message_t* msg, uint32_t value)
  {
    int32_t offset = (value - call LocalTimeMilli.get()) << 5;
	
      	
    call PacketTimeStamp32khz.set(msg, offset + call LocalTime32khz.get());
    
  }
  /*----------------- PacketTimeSyncOffset -----------------*/
  async command bool PacketTimeSyncOffset.isSet(message_t* msg)
  {

    return ((call CC2520PacketBody.getMetadata( msg ))->timesync);
  }

  //returns offset of timestamp from the beginning of cc2420 header which is
  //          sizeof(cc2420_header_t)+datalen-sizeof(timesync_radio_t)
  //uses packet length of the message which is
  //          MAC_HEADER_SIZE+MAC_FOOTER_SIZE+datalen
  async command uint8_t PacketTimeSyncOffset.get(message_t* msg)
  {
	
    return (call CC2520PacketBody.getHeader(msg))->length
            + (sizeof(cc2520_header_t) - MAC_HEADER_SIZE)
            - MAC_FOOTER_SIZE
            - sizeof(timesync_radio_t);
  }
  
  async command void PacketTimeSyncOffset.set(message_t* msg)
  {
    (call CC2520PacketBody.getMetadata( msg ))->timesync = TRUE;
	
  }

  async command void PacketTimeSyncOffset.cancel(message_t* msg)
  {
    (call CC2520PacketBody.getMetadata( msg ))->timesync = FALSE;

  }
}
