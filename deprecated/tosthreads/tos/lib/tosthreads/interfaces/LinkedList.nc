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
 
#include "linked_list.h"

interface LinkedList {
  async command void init(linked_list_t* l);
  async command void clear(linked_list_t* l);
  async command uint8_t size(linked_list_t* l);
  async command error_t addAt(linked_list_t* l, list_element_t* e, uint8_t i);
  async command error_t addFirst(linked_list_t* l, list_element_t* e);
  async command error_t addLast(linked_list_t* l, list_element_t* e);
  async command error_t addAfter(linked_list_t* l, list_element_t* first, list_element_t* second);
  async command error_t addBefore(linked_list_t* l, list_element_t* first, list_element_t* second);
  async command list_element_t* getAt(linked_list_t* l, uint8_t i);
  async command list_element_t* getFirst(linked_list_t* l);
  async command list_element_t* getLast(linked_list_t* l);
  async command list_element_t* getAfter(linked_list_t* l, list_element_t* e);
  async command list_element_t* getBefore(linked_list_t* l, list_element_t* e);
  async command uint8_t indexOf(linked_list_t* l, list_element_t* e);
  async command list_element_t* remove(linked_list_t* l, list_element_t* e);
  async command list_element_t* removeAt(linked_list_t* l, uint8_t i);
  async command list_element_t* removeFirst(linked_list_t* l);
  async command list_element_t* removeLast(linked_list_t* l);
  async command list_element_t* removeBefore(linked_list_t* l, list_element_t* e);
  async command list_element_t* removeAfter(linked_list_t* l, list_element_t* e);
}
