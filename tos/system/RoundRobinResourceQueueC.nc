/*
 * Copyright (c) 2005 Washington University in St. Louis.
 * All rights reserved.
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
 */

/**
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 * @version $Revision: 1.7 $
 * @date $Date: 2010-06-29 22:07:56 $
 */
 
#include "Resource.h"
 
generic module RoundRobinResourceQueueC(uint8_t size) @safe() {
  provides {
    interface Init;
    interface ResourceQueue as RoundRobinQueue;
  }
}
implementation {
  enum {
    NO_ENTRY = 0xFF,
    SIZE = size ? (size - 1) / 8 + 1 : 0
  };

  uint8_t resQ[SIZE];
  uint8_t last = 0;

  void clearEntry(uint8_t id) {
    resQ[id / 8] &= ~(1 << (id % 8));
  }

  command error_t Init.init() {
    memset(resQ, 0, sizeof(resQ));
    return SUCCESS;
  }  
  
  async command bool RoundRobinQueue.isEmpty() {
    unsigned int i;
    atomic {
      for (i = 0; i<sizeof(resQ); i++)
        if(resQ[i] > 0) return FALSE;
      return TRUE;
    }
  }
  	
  async command bool RoundRobinQueue.isEnqueued(resource_client_id_t id) {
  	return resQ[id / 8] & (1 << (id % 8));
  }

  async command resource_client_id_t RoundRobinQueue.dequeue() {
    int i;
    atomic {
      for (i = last+1; ; i++) {
        if(i == size)
          i = 0;
        if (call RoundRobinQueue.isEnqueued(i)) {
          clearEntry(i);
          last = i;
          return i;
        }
        if (i == last)
          break;
      }
      return NO_ENTRY;
    }
  }
  
  async command error_t RoundRobinQueue.enqueue(resource_client_id_t id) {
    atomic {
      if (!(call RoundRobinQueue.isEnqueued(id))) {
        resQ[id / 8] |=  1 << (id % 8);
        return SUCCESS;
      }
      return EBUSY;
    }
  }
}
