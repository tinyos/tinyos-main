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

module LinkedListC {
  provides interface LinkedList;
}
implementation {
  list_element_t* get_elementAt(linked_list_t* l, uint8_t i) {
    if(i >= (l->size)) return NULL;
    else if((l->head) == NULL) return NULL;
    else {
      list_element_t* temp = (l->head); 
      while(i-- > 0) {
        temp = temp->next;
      }
      return temp;
    }
  }
  
  list_element_t* get_element(linked_list_t* l, list_element_t* e) {
    list_element_t* temp = (l->head);
    while(temp != NULL) {
      if(temp == e) return temp;
      temp = temp->next;
    }
    return NULL;
  }
  
  list_element_t* get_element_before(linked_list_t* l, list_element_t* e) {
    list_element_t* temp = (l->head);
    if(temp == NULL) return NULL;
    while(temp->next != NULL) {
      if(temp->next == e) return temp;;
      temp = temp->next;
    }
    return NULL;
  }
  
  list_element_t* get_element_2before(linked_list_t* l, list_element_t* e) {
    list_element_t* temp = (l->head);
    if(temp == NULL) return NULL;
    if(temp->next == NULL) return NULL;
    while(temp->next->next != NULL) {
      if(temp->next->next == e) return temp;
      temp = temp->next->next;
    }
    return NULL;
  }
  
  error_t insert_element(linked_list_t* l, list_element_t** previous_next, list_element_t* e) {
    if(e == NULL) return FAIL;
    e->next = *previous_next;
    *previous_next = e;
    (l->size)++;
    return SUCCESS;
  }
  
  list_element_t* remove_element(linked_list_t* l, list_element_t** previous_next) {
    list_element_t* e = (*previous_next);
    *previous_next = (*previous_next)->next;
    e->next = NULL;
    (l->size)--;
    return e;
  }

  async command void LinkedList.init(linked_list_t* l) {
    l->head = NULL; 
    l->size = 0;
  }
  async command void LinkedList.clear(linked_list_t* l) {
    list_element_t* temp = (l->head);
    while(temp != NULL)
      remove_element(l, &temp);
    l->head = NULL;
    l->size = 0;
  }
  async command uint8_t LinkedList.size(linked_list_t* l) {
    return (l->size);
  }
  async command error_t LinkedList.addFirst(linked_list_t* l, list_element_t* e) {
    return insert_element(l, &(l->head), e);
  }
  async command list_element_t* LinkedList.getFirst(linked_list_t* l) {
    if((l->head) == NULL) return NULL;
    return (l->head);
  }
  async command list_element_t* LinkedList.removeFirst(linked_list_t* l) {
    if((l->head) == NULL) return NULL;
    else return remove_element(l, &(l->head));
  }
  async command error_t LinkedList.addLast(linked_list_t* l, list_element_t* e) {
    return call LinkedList.addAt(l, e, (l->size));
  }
  async command list_element_t* LinkedList.getLast(linked_list_t* l) {
    return get_elementAt(l, (l->size)-1);
  }
  async command list_element_t* LinkedList.removeLast(linked_list_t* l) {
    return call LinkedList.removeAt(l, (l->size)-1);
  }
  async command error_t LinkedList.addAt(linked_list_t* l, list_element_t* e, uint8_t i) {
    if(i > (l->size)) return FAIL;
    else if(i == 0)
      return insert_element(l, &(l->head), e);
    else {
      list_element_t* temp = get_elementAt(l, i-1);
      return insert_element(l, &(temp->next), e);
    }
  }
  async command list_element_t* LinkedList.getAt(linked_list_t* l, uint8_t i) {
    list_element_t* temp = get_elementAt(l, i);
    if(temp == NULL) return NULL;
    return temp;
  }
  async command list_element_t* LinkedList.removeAt(linked_list_t* l, uint8_t i) {
    if(i == 0)
      return call LinkedList.removeFirst(l);
    else {
      list_element_t* temp = get_elementAt(l, i-1);
      if(temp == NULL) return NULL;
      else return remove_element(l, &(temp->next));
    }
  }
  async command error_t LinkedList.addAfter(linked_list_t* l, list_element_t* first, list_element_t* second) {
    list_element_t* temp = get_element(l, first);
    if(temp == NULL) return FAIL;
    else return insert_element(l, &(temp->next), second);
  }
  async command error_t LinkedList.addBefore(linked_list_t* l, list_element_t* first, list_element_t* e) {
    list_element_t* temp;
    if((l->head) == NULL) return FAIL;
    if((l->head) == first) return insert_element(l, &(l->head), e);
  
    temp = get_element_before(l, first);
    if(temp == NULL) return FAIL;
    else return insert_element(l, &(temp->next), e);
  }
  async command list_element_t* LinkedList.getAfter(linked_list_t* l, list_element_t* e) {
    list_element_t* temp = get_element(l, e);
    if(temp == NULL) return NULL;
    if(temp->next == NULL) return NULL;
    return temp->next;
  }
  async command list_element_t* LinkedList.getBefore(linked_list_t* l, list_element_t* e) {
    list_element_t* temp = get_element_before(l, e);
    if(temp == NULL) return NULL;
    return temp;
  }
  async command list_element_t* LinkedList.remove(linked_list_t* l, list_element_t* e) {
    list_element_t* temp;
    if((l->head) == NULL) return NULL;
    if((l->head) == e) return remove_element(l, &(l->head));
    
    temp = get_element_before(l, e);
    if(temp == NULL) return NULL;
    else return remove_element(l, &(temp->next));
  }
  async command list_element_t* LinkedList.removeBefore(linked_list_t* l, list_element_t* e) {
    list_element_t* temp;
    if((l->head) == NULL) return NULL;
    if((l->head)->next == NULL) return NULL;
    if((l->head)->next == e) return remove_element(l, &(l->head));
    
    temp = get_element_2before(l, e);
    if(temp == NULL) return NULL;
    else return remove_element(l, &(temp->next));
  }
  async command list_element_t* LinkedList.removeAfter(linked_list_t* l, list_element_t* e) {
    list_element_t* temp = get_element(l, e);
    if(temp == NULL) return NULL;
    else return remove_element(l, &(temp->next));
  }
  async command uint8_t LinkedList.indexOf(linked_list_t* l, list_element_t* e) {
    int i = -1;
    list_element_t* temp = (l->head);
    while(temp != NULL) {
      i++;
      if(temp == e) break;
      temp = temp->next;
    }
    return i;
  }
}
