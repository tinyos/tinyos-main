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
 */

module CCollectionP {
  uses {
    interface BlockingStdControl;
    interface BlockingReceive[am_id_t amId];
    interface BlockingReceive as BlockingReceiveAny;
    interface BlockingReceive as BlockingSnoop[am_id_t amId];
    interface BlockingReceive as BlockingSnoopAny;
    interface BlockingAMSend as Send[am_id_t id];
    interface Packet;
    interface AMPacket;
    interface PacketAcknowledgements;
  }
}
implementation {
  error_t collectionReceive(message_t* m, uint32_t timeout, collection_id_t id) @C() @spontaneous() {
  }
  error_t collectionSnoop(message_t* m, uint32_t timeout, collection_id_t id) @C() @spontaneous() {
  }
  error_t collectionSend(message_t* msg, uint8_t len, collection_id_t id) @C() @spontaneous() {
  }
 
  void collectionClear(message_t* msg) @C() @spontaneous() {
  }
  uint8_t collectionGetPayloadLength(message_t* msg) @C() @spontaneous() {
  }
  void collectionSetPayloadLength(message_t* msg, uint8_t len) @C() @spontaneous() {
  }
  uint8_t collectionMaxPayloadLength() @C() @spontaneous() {
  }
  void* collectionGetPayload(message_t* msg, uint8_t len) @C() @spontaneous() {
  }

  am_addr_t collectionGetOrigin(message_t* msg) @C() @spontaneous() {
  }
  void collectionSetOrigin(message_t* msg, am_addr_t addr) @C() @spontaneous() {
  }
  collection_id_t collectionGetType(message_t* msg) @C() @spontaneous() {
  }
  void collectionSetType(message_t* msg, collection_id_t id) @C() @spontaneous() {
  }
  uint8_t collectionGetSequenceNumber(message_t* msg) @C() @spontaneous() {
  }
  void collectionSetSequenceNumber(message_t* msg, uint8_t seqno) @C() @spontaneous() {
  }

  error_t collectionSetRoot() @C() @spontaneous() {
  }
  error_t collectionUnsetRoot() @C() @spontaneous() {
  }
  bool collectionIsRoot() @C() @spontaneous() {
  }
}