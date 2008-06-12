/*
 * Copyright (c) 2008 Stanford University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *extern  notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *extern  notice, this list of conditions and the following disclaimer in the
 *extern  documentation and/or other materials provided with the
 *extern  distribution.
 * - Neither the name of the Stanford University nor the names of
 *extern  its contributors may be used to endorse or promote products derived
 *extern  from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.extern IN NO EVENT SHALL STANFORD
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
 * @author Kevin Klues (klueska@cs.stanford.edu)
 */
 
#ifndef TOSTHREAD_QUEUE_H
#define TOSTHREAD_QUEUE_H

#include "queue.h"

extern void queue_init(queue_t* q); 
extern void queue_clear(queue_t* q); 
extern error_t queue_enqueue(queue_t* q, queue_element_t* e);
extern queue_element_t* queue_dequeue(queue_t* q);
extern queue_element_t* queue_remove(queue_t* q, queue_element_t* e);
extern uint8_t queue_size(queue_t* q); 
extern bool queue_is_empty(queue_t* q); 

#endif //TOSTHREAD_QUEUE_H
