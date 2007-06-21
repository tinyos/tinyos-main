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
 * @author David Moss
 */
interface FifoQueue<t> {

  /**
   * Enqueue a single element into our queue.  The available(...) event will
   * signaled every time.
   */
  command error_t enqueue(t element);
  
  /**
   * Dequeue the next element if it exists
   * @param *location the location to put this element
   * @param maxSize the maximum size of our location so we don't overflow
   * @return SUCCESS if we dequeued something to the given location.
   *     FAIL if there was nothing to dequeue.
   *     ESIZE if the dequeue destination buffer is too small
   */
  command error_t dequeue(void *location, uint8_t maxSize);
  
  /**
   * @return the maximum size of our queue
   */
  command uint8_t maxSize();
  
  /**
   * @return the total number of elements enqueued
   */
  command uint8_t size();
  
  /**
   * @return TRUE if the queue is empty
   */
  command bool isEmpty();
  
  /**
   * @return TRUE if the queue is full
   */
  command bool isFull();
  
  /**
   * Dump all contents of this queue and reset everything
   */
  command void reset();
  
  
  /**
   * Notification that there are more elements available in the queue.
   * It is up to the consumer to know when to dequeue those elements.
   */
  event void available();
  
}

