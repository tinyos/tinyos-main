/*
 * Copyright (c) 2005-2006 Rincon Research Corporation
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
 * - Neither the name of the Rincon Research Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * RINCON RESEARCH OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * Fills in the network ID byte for outgoing packets for compatibility with
 * other 6LowPAN networks.  Filters incoming packets that are not
 * TinyOS network compatible.  Provides the 6LowpanSnoop interface to
 * sniff for packets that were not originated from TinyOS.
 *
 * @author David Moss
 */
 
#include "CC2420.h"

module CC2420TinyosNetworkP @safe() {
  provides {
    interface Send;
    interface Receive;
    
    interface Receive as NonTinyosReceive[uint8_t networkId];
  }
  
  uses {
    interface Send as SubSend;
    interface Receive as SubReceive;
    interface CC2420PacketBody;
  }
}

implementation {

  /***************** Send Commands ****************/
  command error_t Send.send(message_t* msg, uint8_t len) {
    (call CC2420PacketBody.getHeader(msg))->network = TINYOS_6LOWPAN_NETWORK_ID;
    return call SubSend.send(msg, len);
  }

  command error_t Send.cancel(message_t* msg) {
    return call SubSend.cancel(msg);
  }

  command uint8_t Send.maxPayloadLength() {
    return call SubSend.maxPayloadLength();
  }

  command void* Send.getPayload(message_t* msg, uint8_t len) {
    return call SubSend.getPayload(msg, len);
  }
  
  /***************** SubSend Events *****************/
  event void SubSend.sendDone(message_t* msg, error_t error) {
    signal Send.sendDone(msg, error);
  }
  
  /***************** SubReceive Events ***************/
  event message_t *SubReceive.receive(message_t *msg, void *payload, uint8_t len) {
    if((call CC2420PacketBody.getHeader(msg))->network == TINYOS_6LOWPAN_NETWORK_ID) {
      return signal Receive.receive(msg, payload, len);
      
    } else {
      return signal NonTinyosReceive.receive[(call CC2420PacketBody.getHeader(msg))->network](msg, payload, len);
    }
  }
  
  /***************** Defaults ****************/
  default event message_t *NonTinyosReceive.receive[uint8_t networkId](message_t *msg, void *payload, uint8_t len) {
    return msg;
  }
  
}
