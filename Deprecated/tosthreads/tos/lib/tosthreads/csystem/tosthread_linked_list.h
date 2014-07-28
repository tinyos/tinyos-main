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
 
#ifndef TOSTHREAD_LINKED_LIST_H
#define TOSTHREAD_LINKED_LIST_H

#include "linked_list.h"

extern void linked_list_init(linked_list_t* l); 
extern void linked_list_clear(linked_list_t* l); 
extern uint8_t linked_list_size(linked_list_t* l); 
extern error_t linked_list_addFirst(linked_list_t* l, list_element_t* e);
extern list_element_t* linked_list_getFirst(linked_list_t* l); 
extern list_element_t* linked_list_removeFirst(linked_list_t* l);
extern error_t linked_list_addLast(linked_list_t* l, list_element_t* e); 
extern list_element_t* linked_list_getLast(linked_list_t* l); 
extern list_element_t* linked_list_removeLast(linked_list_t* l); 
extern error_t linked_list_addAt(linked_list_t* l, list_element_t* e, uint8_t i); 
extern list_element_t* linked_list_getAt(linked_list_t* l, uint8_t i); 
extern list_element_t* linked_list_removeAt(linked_list_t* l, uint8_t i);
extern error_t linked_list_addAfter(linked_list_t* l, list_element_t* first, list_element_t* second); 
extern error_t linked_list_addBefore(linked_list_t* l, list_element_t* first, list_element_t* e); 
extern list_element_t* linked_list_getAfter(linked_list_t* l, list_element_t* e); 
extern list_element_t* linked_list_getBefore(linked_list_t* l, list_element_t* e); 
extern list_element_t* linked_list_remove(linked_list_t* l, list_element_t* e); 
extern list_element_t* linked_list_removeBefore(linked_list_t* l, list_element_t* e); 
extern list_element_t* linked_list_removeAfter(linked_list_t* l, list_element_t* e);  
extern uint8_t linked_list_indexOf(linked_list_t* l, list_element_t* e); 

#endif //TOSTHREAD_LINKED_LIST_H
