/*
 * Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
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
 */
/*									tab:4
 * Copyright (c) 2005 Stanford University. All rights reserved.
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
 *
 * @author Stephen Dawson-Haggerty
 * @version $Revision: 1.3 $ $Date: 2010-06-29 22:07:44 $
 */
 
#include "CC2420.h"
#include "IEEE802154.h"

module CC2420Ieee154MessageP {

  provides {
    interface Ieee154Send;
    interface Receive as Ieee154Receive;
    interface Ieee154Packet;
    interface Packet;
  }
  
  uses {
    interface Send as SubSend;
    interface Receive as SubReceive;
    interface CC2420Packet;
    interface CC2420PacketBody;
    interface CC2420Config;
#ifdef CC2420_IEEE154_RESOURCE_SEND
    interface Resource;
#endif
  }
}
implementation {
  message_t *m_pending_msg;
  enum {
    EXTRA_OVERHEAD = sizeof(cc2420_header_t) - offsetof(cc2420_header_t, network),
  };

  /***************** Ieee154Send Commands ****************/
  command error_t Ieee154Send.send(ieee154_saddr_t addr,
                                   message_t* msg,
                                   uint8_t len) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader( msg );

    header->length = len + CC2420_SIZE - EXTRA_OVERHEAD;
    header->dest = addr;
    header->destpan = call CC2420Config.getPanAddr();
    header->src = call CC2420Config.getShortAddr();
    header->fcf = ( 1 << IEEE154_FCF_INTRAPAN ) |
      ( IEEE154_ADDR_SHORT << IEEE154_FCF_DEST_ADDR_MODE ) |
      ( IEEE154_ADDR_SHORT << IEEE154_FCF_SRC_ADDR_MODE ) ;

#ifdef CC2420_IEEE154_RESOURCE_SEND
    if (call Resource.isOwner())
      return EBUSY;

    if (call Resource.immediateRequest() == SUCCESS) {
      error_t rc;
      rc = call SubSend.send( msg, header->length - 1 );
      if (rc != SUCCESS) {
        call Resource.release();
      }
      return rc;
    } else {
      m_pending_msg = msg;
      return call Resource.request();
    }
#else
    return call SubSend.send( msg, header->length - 1 );
#endif
  }

#ifdef CC2420_IEEE154_RESOURCE_SEND
  event void Resource.granted() {
    error_t rc;
    cc2420_header_t* header = call CC2420PacketBody.getHeader( m_pending_msg );
    rc = call SubSend.send(m_pending_msg, header->length - 1);
    if (rc != SUCCESS) {
      call Resource.release();
      signal Ieee154Send.sendDone(m_pending_msg, rc);
    }
  }
#endif

  command error_t Ieee154Send.cancel(message_t* msg) {
    return call SubSend.cancel(msg);
  }

  command uint8_t Ieee154Send.maxPayloadLength() {
    return call Packet.maxPayloadLength();
  }

  command void* Ieee154Send.getPayload(message_t* m, uint8_t len) {
    return call Packet.getPayload(m, len);
  }

  event message_t *SubReceive.receive(message_t *msg, void *payload, uint8_t len) {
    return signal Ieee154Receive.receive(msg,
                                         call Packet.getPayload(msg, 0),
                                         call Packet.payloadLength(msg));
  }

  /***************** Ieee154Packet Commands ****************/
  command ieee154_saddr_t Ieee154Packet.address() {
    return call CC2420Config.getShortAddr();
  }
 
  command ieee154_saddr_t Ieee154Packet.destination(message_t* msg) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(msg);
    return header->dest;
  }
 
  command ieee154_saddr_t Ieee154Packet.source(message_t* msg) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(msg);
    return header->src;
  }

  command void Ieee154Packet.setDestination(message_t* msg, ieee154_saddr_t addr) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(msg);
    header->dest = addr;
  }

  command void Ieee154Packet.setSource(message_t* msg, ieee154_saddr_t addr) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(msg);
    header->src = addr;
  }

  command bool Ieee154Packet.isForMe(message_t* msg) {
    return (call Ieee154Packet.destination(msg) == call Ieee154Packet.address() ||
	    call Ieee154Packet.destination(msg) == IEEE154_BROADCAST_ADDR);
  }

  command ieee154_panid_t Ieee154Packet.pan(message_t* msg) {
    return (call CC2420PacketBody.getHeader(msg))->destpan;
  }

  command void Ieee154Packet.setPan(message_t* msg, ieee154_panid_t grp) {
    // Overridden intentionally when we send()
    (call CC2420PacketBody.getHeader(msg))->destpan = grp;
  }

  command ieee154_panid_t Ieee154Packet.localPan() {
    return call CC2420Config.getPanAddr();
  }


  /***************** Packet Commands ****************/
  command void Packet.clear(message_t* msg) {
    memset(call CC2420PacketBody.getHeader(msg), 0, sizeof(cc2420_header_t) - EXTRA_OVERHEAD);
    memset(call CC2420PacketBody.getMetadata(msg), 0, sizeof(cc2420_metadata_t));
  }
  
  command uint8_t Packet.payloadLength(message_t* msg) {
    return (call CC2420PacketBody.getHeader(msg))->length - CC2420_SIZE + EXTRA_OVERHEAD;
  }
  
  command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
    (call CC2420PacketBody.getHeader(msg))->length  = len + CC2420_SIZE - EXTRA_OVERHEAD;
  }
  
  command uint8_t Packet.maxPayloadLength() {
    return TOSH_DATA_LENGTH + EXTRA_OVERHEAD;
  }
  
  command void* Packet.getPayload(message_t* msg, uint8_t len) {
    return msg->data - EXTRA_OVERHEAD;
  }

  
  /***************** SubSend Events ****************/
  event void SubSend.sendDone(message_t* msg, error_t result) {
#ifdef CC2420_IEEE154_RESOURCE_SEND
    call Resource.release();
#endif
    signal Ieee154Send.sendDone(msg, result);
  }

  /***************** CC2420Config Events ****************/
  event void CC2420Config.syncDone( error_t error ) {
  }

  default event void Ieee154Send.sendDone(message_t *msg, error_t e) {

  }
}
