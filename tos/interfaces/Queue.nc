/* $Id: Queue.nc,v 1.3 2006-11-07 19:31:17 scipio Exp $ */
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
 *  Interface to a FIFO list (queue) that contains items
 *  of a specific type. The queue has a maximum size.
 *
 *  @author Philip Levis
 *  @author Kyle Jamieson
 *  @date   $Date: 2006-11-07 19:31:17 $
 */

   
interface Queue<t> {

  /**
   * Returns if the queue is empty.
   *
   * @return Whether the queue is empty.
   */
  command bool empty();

  /**
   * The number of elements currently in the queue.
   * Always less than or equal to maxSize().
   *
   * @return The number of elements in the queue.
   */
  command uint8_t size();

  /**
   * The maximum number of elements the queue can hold.
   *
   * @return The maximum queue size.
   */
  command uint8_t maxSize();

  /**
   * Get the head of the queue without removing it. If the queue
   * is empty, the return value is undefined.
   *
   * @return The head of the queue.
   */
  command t head();
  
  /**
   * Remove the head of the queue. If the queue is empty, the return
   * value is undefined.
   *
   * @return The head of the queue.
   */
  command t dequeue();

  /**
   * Enqueue an element to the tail of the queue.
   *
   * @param newVal - the element to enqueue
   * @return SUCCESS if the element was enqueued successfully, FAIL
   *                 if it was not enqueued.
   */
  command error_t enqueue(t newVal);

  /**
   * Return the nth element of the queue without dequeueing it, 
   * where 0 is the head of the queue and (size - 1) is the tail. 
   * If the element requested is larger than the current queue size,
   * the return value is undefined.
   *
   * @param index - the index of the element to return
   * @return the requested element in the queue.
   */
  command t element(uint8_t idx);
}
