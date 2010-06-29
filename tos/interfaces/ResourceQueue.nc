/*
 * Copyright (c) 2006 Washington University in St. Louis.
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
 *  A queue interface for managing client ids when performing resource 
 *  arbitration. A single slot in the queue is guaranteed to each resource
 *  client, with the actual queing policy determined by the implementation
 *  of the interface.
 *
 *  @author Kevin Klues <klueska@cs.wustl.edu>
 *  @date   $Date: 2010-06-29 22:07:46 $
 */
 
#include "Resource.h"
   
interface ResourceQueue {
	
  /**
   * Check to see if the queue is empty.
   *
   * @return TRUE  if the queue is empty. <br>
   *         FALSE if there is at least one entry in the queue
   */
  async command bool isEmpty();
  
  /**
   * Check to see if a given client id has already been enqueued
   * and is waiting to be processed.
   *
   * @return TRUE  if the client id is in the queue. <br>
   *         FALSE if it does not
   */
  async command bool isEnqueued(resource_client_id_t id);
  
  /**
   * Retreive the client id of the next resource in the queue. 
   * If the queue is empty, the return value is undefined.
   *
   * @return The client id at the head of the queue.
   */
  async command resource_client_id_t dequeue();

  /**
   * Enqueue a client id
   *
   * @param clientId - the client id to enqueue
   * @return SUCCESS if the client id was enqueued successfully <br>
   *         EBUSY   if it has already been enqueued.
   */
  async command error_t enqueue(resource_client_id_t id);
}
