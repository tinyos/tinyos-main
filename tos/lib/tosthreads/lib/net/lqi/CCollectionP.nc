/*
 * Copyright (c) 2008 Stanford University.
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
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
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
 * @author Kevin Klues <klueska@cs.stanford.edu>
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

module CCollectionP {
  uses {
    interface BlockingStdControl as RoutingControl;
    interface BlockingReceive[collection_id_t id];
    interface BlockingReceive as BlockingSnoop[collection_id_t id];
    interface BlockingSend[uint8_t id];
    interface Packet;
    interface CollectionPacket;
    interface RootControl;
    interface CCollectionId;
  }
  provides {
    interface CollectionId[uint8_t client];
  }
}
implementation {
  command collection_id_t CollectionId.fetch[uint8_t id]() {
    return call CCollectionId.fetch(id);
  }

  error_t collectionSetCollectionId(uint8_t clientid, collection_id_t collectionid) @C() @spontaneous() {
    return call CCollectionId.set(clientid, collectionid);
  }
  
  error_t collectionRoutingStart() @C() @spontaneous() {
    return call RoutingControl.start();
  }
  error_t collectionRoutingStop() @C() @spontaneous() {
    return call RoutingControl.stop();
  }

  error_t collectionReceive(message_t* m, uint32_t timeout, collection_id_t id) @C() @spontaneous() {
    return call BlockingReceive.receive[id](m, timeout);
  }
  error_t collectionSnoop(message_t* m, uint32_t timeout, collection_id_t id) @C() @spontaneous() {
    return call BlockingSnoop.receive[id](m, timeout);
  }
  error_t collectionSend(message_t* msg, uint8_t len, uint8_t id) @C() @spontaneous() {
    call CollectionPacket.setType(msg, call CCollectionId.fetch(id));
    return call BlockingSend.send[id](msg, len);
  }
 
  void collectionClear(message_t* msg) @C() @spontaneous() {
    call Packet.clear(msg);
  }
  uint8_t collectionGetPayloadLength(message_t* msg) @C() @spontaneous() {
    return call Packet.payloadLength(msg);
  }
  void collectionSetPayloadLength(message_t* msg, uint8_t len) @C() @spontaneous() {
    call Packet.setPayloadLength(msg, len);
  }
  uint8_t collectionMaxPayloadLength() @C() @spontaneous() {
    return call Packet.maxPayloadLength();
  }
  void* collectionGetPayload(message_t* msg, uint8_t len) @C() @spontaneous() {
    return call Packet.getPayload(msg, len);
  }

  am_addr_t collectionGetOrigin(message_t* msg) @C() @spontaneous() {
    return call CollectionPacket.getOrigin(msg);
  }
  void collectionSetOrigin(message_t* msg, am_addr_t addr) @C() @spontaneous() {
    call CollectionPacket.setOrigin(msg, addr);
  }
  collection_id_t collectionGetType(message_t* msg) @C() @spontaneous() {
    return call CollectionPacket.getType(msg);
  }
  void collectionSetType(message_t* msg, collection_id_t id) @C() @spontaneous() {
    call CollectionPacket.setType(msg, id);
  }
  uint8_t collectionGetSequenceNumber(message_t* msg) @C() @spontaneous() {
    return call CollectionPacket.getSequenceNumber(msg);
  }
  void collectionSetSequenceNumber(message_t* msg, uint8_t seqno) @C() @spontaneous() {
    call CollectionPacket.setSequenceNumber(msg, seqno);
  }

  error_t collectionSetRoot() @C() @spontaneous() {
    return call RootControl.setRoot();
  }
  error_t collectionUnsetRoot() @C() @spontaneous() {
    return call RootControl.unsetRoot();
  }
  bool collectionIsRoot() @C() @spontaneous() {
    return call RootControl.isRoot();
  }
}

