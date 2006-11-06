/*
 * Copyright (c) 2006 Stanford University.
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
 * An LRU cache that stores the signature of a CTP packet instance.
 * An insert operation indicates "use".  Inserting an element not in
 * the cache will replace the oldest, and inserting an element already
 * in the cache will refresh its age.
 *
 * @author Philip Levis 
 */

#include <message.h>

generic module LruCtpMsgCacheP(uint8_t size) {
    provides {
      interface Init;
      interface Cache<message_t*>;
    }
    uses {
      interface CtpPacket;
    }
}
implementation {
  typedef struct {
    am_addr_t origin;
    uint8_t seqno;
    collection_id_t type;
    uint8_t thl;
  } ctp_packet_sig_t;
  
  ctp_packet_sig_t cache[size];
  uint8_t first;
  uint8_t count;

  command error_t Init.init() {
    first = 0;
    count = 0;
    return SUCCESS;
  } 

  void printCache() {
#ifdef TOSSIM
    int i;
    dbg("Cache","Cache:");
    for (i = 0; i < count; i++) {
      dbg_clear("Cache", " %04x %02x %02x %02x", cache[i].origin, cache[i].seqno, cache[i].type, cache[i].thl);
      if (i == first)
	dbg_clear("Cache","*");
    } 
    dbg_clear("Cache","\n");
#endif
    }

    /* if key is in cache returns the index (offset by first), otherwise returns count */
  uint8_t lookup(message_t* m) {
    uint8_t i;
    uint8_t idx;
    for (i = 0; i < count; i++) {
      idx = (i + first) % size;
      if (call CtpPacket.getOrigin(m)         == cache[idx].origin &&
	  call CtpPacket.getSequenceNumber(m) == cache[idx].seqno &&
	  call CtpPacket.getThl(m)            == cache[idx].thl &&
	  call CtpPacket.getType(m)           == cache[idx].type) {
	break;
      }
    }
    return i;
  }
  
  /* remove the entry with index i (relative to first) */
    void remove(uint8_t i) {
        uint8_t j;
        if (i >= count) 
            return;
        if (i == 0) {
            //shift all by moving first
            first = (first + 1) % size;
        } else {
            //shift everyone down
            for (j = i; j < count; j++) {
	      memcpy(&cache[(j + first) % size], &cache[(j + first + 1) % size], sizeof(ctp_packet_sig_t));
	    }
        }
        count--;
    }

    command void Cache.insert(message_t* m) {
        uint8_t i;
        if (count == size ) {
            //remove someone. If item not in 
            //cache, remove the first item.
            //otherwise remove the item temporarily for
            //reinsertion. This moves the item up in the
            //LRU stack.
	  i = lookup(m);
	  remove(i % count);
        }
        //now count < size
        cache[(first + count) % size].origin = call CtpPacket.getOrigin(m);
	cache[(first + count) % size].seqno  = call CtpPacket.getSequenceNumber(m);
	cache[(first + count) % size].thl    = call CtpPacket.getThl(m);
	cache[(first + count) % size].type   = call CtpPacket.getType(m);
        count++;
    }

    command bool Cache.lookup(message_t* m) {
        return (lookup(m) < count);
    }

    command void Cache.flush() {
      call Init.init(); 
    }

}
