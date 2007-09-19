/* $Id: BigQueueC.nc,v 1.1 2007-09-19 17:20:47 klueska Exp $ */
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
 *  A general FIFO queue component, whose queue has a bounded size.
 *
 *  @author Philip Levis
 *  @author Geoffrey Mainland
 *  @date   $Date: 2007-09-19 17:20:47 $
 */

   
generic module BigQueueC(typedef queue_t, uint16_t QUEUE_SIZE) {
  provides interface BigQueue<queue_t> as Queue;
}

implementation {

  queue_t queue[QUEUE_SIZE];
  uint16_t head = 0;
  uint16_t tail = 0;
  uint16_t size = 0;
  
  command bool Queue.empty() {
    return size == 0;
  }

  command uint16_t Queue.size() {
    return size;
  }

  command uint16_t Queue.maxSize() {
    return QUEUE_SIZE;
  }

  command queue_t Queue.head() {
    return queue[head];
  }

  void printQueue() {
#ifdef TOSSIM
    int i, j;
    dbg("QueueC", "head <-");
    for (i = head; i < head + size; i++) {
      dbg_clear("QueueC", "[");
      for (j = 0; j < sizeof(queue_t); j++) {
	uint8_t v = ((uint8_t*)&queue[i % QUEUE_SIZE])[j];
	dbg_clear("QueueC", "%0.2hhx", v);
      }
      dbg_clear("QueueC", "] ");
    }
    dbg_clear("QueueC", "<- tail\n");
#endif
  }
  
  command queue_t Queue.dequeue() {
    queue_t t = call Queue.head();
    dbg("QueueC", "%s: size is %hhu\n", __FUNCTION__, size);
    if (!call Queue.empty()) {
      head++;
      head %= QUEUE_SIZE;
      size--;
      printQueue();
    }
    return t;
  }

  command error_t Queue.enqueue(queue_t newVal) {
    if (call Queue.size() < call Queue.maxSize()) {
      dbg("QueueC", "%s: size is %hhu\n", __FUNCTION__, size);
      queue[tail] = newVal;
      tail++;
      tail %= QUEUE_SIZE;
      size++;
      printQueue();
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }
  
  command queue_t Queue.element(uint16_t idx) {
    idx += head;
    idx %= QUEUE_SIZE;
    return queue[idx];
  }  

}
