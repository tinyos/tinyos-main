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
 
#ifndef TOSTHREAD_COLLECTION_H
#define TOSTHREAD_COLLECTION_H

#include "ccollection.h"

extern error_t collectionRoutingStart();
extern error_t collectionRoutingStop();

extern error_t collectionSetCollectionId(uint8_t clientid, collection_id_t collectionid);

extern error_t collectionReceive(message_t* m, uint32_t timeout, collection_id_t id);
extern error_t collectionSnoop(message_t* m, uint32_t timeout, collection_id_t id);
extern error_t collectionSend(message_t* msg, uint8_t len, collection_id_t id);
 
extern void    collectionClear(message_t* msg);
extern uint8_t collectionGetPayloadLength(message_t* msg);
extern void    collectionSetPayloadLength(message_t* msg, uint8_t len);
extern uint8_t collectionMaxPayloadLength();
extern void*   collectionGetPayload(message_t* msg, uint8_t len);

extern am_addr_t       collectionGetOrigin(message_t* msg);
extern void            collectionSetOrigin(message_t* msg, am_addr_t addr);
extern collection_id_t collectionGetType(message_t* msg);
extern void            collectionSetType(message_t* msg, collection_id_t id);
extern uint8_t         collectionGetSequenceNumber(message_t* msg);
extern void            collectionSetSequenceNumber(message_t* msg, uint8_t seqno);

extern error_t collectionSetRoot();
extern error_t collectionUnsetRoot();
extern bool    collectionIsRoot();

#endif //TOSTHREAD_COLLECTION_H
