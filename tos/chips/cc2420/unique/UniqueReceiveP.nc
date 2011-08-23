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
 * This layer keeps a history of the past RECEIVE_HISTORY_SIZE received messages
 * If the source address and dsn number of a newly received message matches
 * our recent history, we drop the message because we've already seen it.
 * @author David Moss
 */
 
#include "CC2420.h"

module UniqueReceiveP @safe() {
  provides {
    interface Receive;
    interface Receive as DuplicateReceive;
    interface Init;
  }
  
  uses {
    interface Receive as SubReceive;
    interface CC2420PacketBody;
  }
}

implementation {
  
  struct {
    uint16_t source;
    uint8_t dsn;
  } receivedMessages[RECEIVE_HISTORY_SIZE];
  
  uint8_t writeIndex = 0;
  
  /** History element containing info on a source previously received from */
  uint8_t recycleSourceElement;
  
  enum {
    INVALID_ELEMENT = 0xFF,
  };
  
  /***************** Init Commands *****************/
  command error_t Init.init() {
    int i;
    for(i = 0; i < RECEIVE_HISTORY_SIZE; i++) {
      receivedMessages[i].source = (am_addr_t) 0xFFFF;
      receivedMessages[i].dsn = 0;
    }
    return SUCCESS;
  }
  
  /***************** Prototypes Commands ***************/
  bool hasSeen(uint16_t msgSource, uint8_t msgDsn);
  void insert(uint16_t msgSource, uint8_t msgDsn);
  uint16_t getSourceKey(message_t ONE *msg);
  
  /***************** SubReceive Events *****************/
  event message_t *SubReceive.receive(message_t* msg, void* payload, 
      uint8_t len) {

    uint16_t msgSource = getSourceKey(msg);
    uint8_t msgDsn = (call CC2420PacketBody.getHeader(msg))->dsn;

    if(hasSeen(msgSource, msgDsn)) {
      return signal DuplicateReceive.receive(msg, payload, len);
    } else {
      insert(msgSource, msgDsn);
      return signal Receive.receive(msg, payload, len);
    }
  }
  
  /****************** Functions ****************/  
  /**
   * This function does two things:
   *  1. It loops through our entire receive history and detects if we've 
   *     seen this DSN before from the given source (duplicate packet)
   *  2. It detects if we've seen messages from this source before, so we know
   *     where to update our history if it turns out this is a new message.
   *
   * The global recycleSourceElement variable stores the location of the next insert
   * if we've received a packet from that source before.  Otherwise, it's up 
   * to the insert() function to decide who to kick out of our history.
   */
  bool hasSeen(uint16_t msgSource, uint8_t msgDsn) {
    int i;
    recycleSourceElement = INVALID_ELEMENT;

    atomic {
      for(i = 0; i < RECEIVE_HISTORY_SIZE; i++) {
        if(receivedMessages[i].source == msgSource) {
          if(receivedMessages[i].dsn == msgDsn) {
            // Only exit this loop if we found a duplicate packet
            return TRUE;
          }
          
          recycleSourceElement = i;
        }
      }
    }
      
    return FALSE;
  }
  
  /**
   * Insert the message into the history.  If we received a message from this
   * source before, insert it into the same location as last time and verify
   * that the "writeIndex" is not pointing to that location. Otherwise,
   * insert it into the "writeIndex" location.
   */
  void insert(uint16_t msgSource, uint8_t msgDsn) {
    uint8_t element = recycleSourceElement;
    bool increment = FALSE;
   
    atomic {
      if(element == INVALID_ELEMENT || writeIndex == element) {
        // Use the writeIndex element to insert this new message into
        element = writeIndex;
        increment = TRUE;
      }

      receivedMessages[element].source = msgSource;
      receivedMessages[element].dsn = msgDsn;
      if(increment) {
        writeIndex++;
        writeIndex %= RECEIVE_HISTORY_SIZE;
      }
    }
  }

  /**
   * Derive a key to to store the source address with.
   *
   * For long (EUI64) addresses, use the sum of the word in the
   * address as a key in the table to avoid manipulating the full
   * address.
   */
  uint16_t getSourceKey(message_t * ONE msg) {
    cc2420_header_t *hdr = call CC2420PacketBody.getHeader(msg);
    int s_mode = (hdr->fcf >> IEEE154_FCF_SRC_ADDR_MODE) & 0x3;
    int d_mode = (hdr->fcf >> IEEE154_FCF_DEST_ADDR_MODE) & 0x3;
    int s_offset = 2, s_len = 2;
    uint16_t key = 0;
    uint8_t *current = (uint8_t *)&hdr->dest;
    int i;

    if (s_mode == IEEE154_ADDR_EXT) {
      s_len = 8;
    }
    if (d_mode == IEEE154_ADDR_EXT) {
      s_offset = 8;
    }

    current += s_offset;
    
    for (i = 0; i < s_len; i++) {
        key += current[i];
    }
    return key;
  }


  
  /***************** Defaults ****************/
  default event message_t *DuplicateReceive.receive(message_t *msg, void *payload, uint8_t len) {
    return msg;
  }
}

