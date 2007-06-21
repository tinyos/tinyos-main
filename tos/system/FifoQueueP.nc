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
 * A generic FIFO queue
 * @author David Moss
 */
 
generic module FifoQueueP(typedef q_element_t, uint8_t FIFO_QUEUE_SIZE) {
  provides {
    interface Init;
    interface FifoQueue<q_element_t>;
  }
}

implementation {

  /** The elements we have enqueued */
  q_element_t myQueue[FIFO_QUEUE_SIZE];
  
  /** The next index we will store another element */
  uint8_t nextEnqueueLocation;
  
  /** The next index we will dequeue. */
  uint8_t currentDequeueLocation;
  
  /** The current size of our queue so we don't have to calculate it */
  uint8_t currentSize;
  
  /***************** Init Commands *****************/
  command error_t Init.init() {
    call FifoQueue.reset();
    return SUCCESS;
  }
  
  /***************** FifoQueue Commands ****************/
  /**
   * Enqueue a single element into our queue.  The available(...) event will
   * signaled every time.
   */
  command error_t FifoQueue.enqueue(q_element_t element) {
    if(call FifoQueue.isFull()) {
      // No more places to enqueue, our queue is full
      return FAIL;
    }
    
    memcpy(&myQueue[nextEnqueueLocation], &element, sizeof(q_element_t));
    currentSize++;
    nextEnqueueLocation++;
    nextEnqueueLocation %= FIFO_QUEUE_SIZE;
    
    signal FifoQueue.available();
    return SUCCESS;
  }
  
  /**
   * Dequeue the next element if it exists
   * @param *location the location to put this element
   * @param maxSize the maximum size of our location so we don't overflow
   * @return SUCCESS if we dequeued something to the given location.
   *     FAIL if there was nothing to dequeue.
   *     ESIZE if the dequeue destination buffer is too small
   */
  command error_t FifoQueue.dequeue(void *location, uint8_t maxSize) {
    uint8_t nextDequeue = (currentDequeueLocation + 1) % FIFO_QUEUE_SIZE;
    
    if(maxSize < sizeof(q_element_t)) {
      // Too small of a destination buffer
      return ESIZE;
    }
    
    if(call FifoQueue.isEmpty()) {
      // No more to dequeue
      return FAIL;
    }
    
    currentDequeueLocation = nextDequeue;
    memcpy(location, &myQueue[currentDequeueLocation], sizeof(q_element_t));
    currentSize--;
    
    return SUCCESS;
  }
  
  /**
   * @return the maximum size of our queue
   */
  command uint8_t FifoQueue.maxSize() {
    return FIFO_QUEUE_SIZE;
  }
  
  /**
   * @return the total number of elements enqueued
   */
  command uint8_t FifoQueue.size() {
    return currentSize;
  }
  
  /**
   * @return TRUE if the queue is empty
   */
  command bool FifoQueue.isEmpty() {
    return currentSize == 0;
  }
  
  /**
   * @return TRUE if the queue is full
   */
  command bool FifoQueue.isFull() {
    return currentSize == FIFO_QUEUE_SIZE;
  }
  
  /**
   * Dump all contents of this queue and reset everything
   */
  command void FifoQueue.reset() {
    nextEnqueueLocation = 0;
    currentDequeueLocation = FIFO_QUEUE_SIZE - 1;
    currentSize = 0;
  }
  
}

