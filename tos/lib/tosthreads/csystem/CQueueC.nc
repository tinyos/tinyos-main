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
 
#include "tosthread_linked_list.h"
#include "tosthread_queue.h"

module CQueueC {}
implementation { 
  void queue_init(queue_t* q) @C() @spontaneous() {  
    linked_list_init( &(q->l) );
  }
  void queue_clear(queue_t* q) @C() @spontaneous() { 
    linked_list_clear( &(q->l) );
  }
  error_t queue_enqueue(queue_t* q, queue_element_t* e) @C() @spontaneous() { 
    return linked_list_addLast(&(q->l), (list_element_t*)e);
  }
  queue_element_t* queue_dequeue(queue_t* q) @C() @spontaneous() { 
    return (queue_element_t*)linked_list_removeFirst( &(q->l) );
  }
  queue_element_t* queue_remove(queue_t* q, queue_element_t* e) @C() @spontaneous() { 
    return (queue_element_t*)linked_list_remove(&(q->l), (list_element_t*)e);
  }
  uint8_t queue_size(queue_t* q) @C() @spontaneous() { 
    return linked_list_size( &(q->l) );
  }
  bool queue_is_empty(queue_t* q) @C() @spontaneous() { 
    return (linked_list_size( &(q->l) ) == 0);
  }
}
