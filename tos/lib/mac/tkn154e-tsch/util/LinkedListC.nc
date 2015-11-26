/*
 * Copyright (c) 2015, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @author Jasper Buesch <tinyos-code@tkn.tu-berlin.de>
 */

/**
 *  A general FIFO queue component, where intermediate elements can be removed.
 */


generic module LinkedListC(typedef data_t, uint8_t LIST_SIZE) {
  provides interface LinkedList<data_t>;
  provides interface Queue<data_t>;
}

implementation {

  uint8_t size = 0;

  typedef struct listElement {
    struct listElement_t* prev;
    data_t elem;
    struct listElement_t* next;
    bool inUse;
  } listElement_t;

  listElement_t ONE_NOK list[LIST_SIZE];
  listElement_t* head = NULL;
  listElement_t* tail = NULL;

  void printQueue();

  command void LinkedList.init() {
    int i;
    for (i=0; i<LIST_SIZE; i++) {
      list[i].inUse = FALSE;
    }
  }

  command bool LinkedList.remove(data_t element) {
    uint8_t i;
    listElement_t* entry;
    entry = head;

    if (call Queue.empty())
      return FALSE;

    for (i=0; i<LIST_SIZE; i++) {
      data_t elem;
      entry = (listElement_t*) entry->next;
      elem = (data_t)(entry->elem);
//      if (elem == element)
        break;
    }
    if (i == LIST_SIZE) return FALSE; // not found

    ((listElement_t*) entry->prev)->next = entry->next;
    ((listElement_t*) entry->next)->prev = entry->prev;
    entry->inUse = FALSE;
    if (entry == head) {
      ((listElement_t*) entry->next)->prev = NULL;
      head = ((listElement_t*) entry->next);
    }
    else if (entry == tail) {
      ((listElement_t*) entry->prev)->next = NULL;
      tail = ((listElement_t*) entry->prev);
    }
    size--;
    if (call Queue.empty()) {
      head = NULL;
      tail = NULL;
    }
printQueue();
  }

  command bool Queue.empty() {
    return size == 0;
  }

  command bool Queue.full() {
     return size >= LIST_SIZE;
  }

  command uint8_t Queue.size() {
    return size;
  }

  command uint8_t Queue.maxSize() {
    return LIST_SIZE;
  }

  command data_t Queue.head() {
    return head->elem;
  }

  void printQueue() {
    int i;
    printf("\n(%p, %p)\n", head, tail);
    for (i=0; i<LIST_SIZE; i++) {
      if (list[i].inUse == TRUE)
        printf("--> ");
      else
        printf("    ");
      printf("%p %u %p\n", list[i].prev, list[i].elem, list[i].next);
    }
  }


  command data_t Queue.dequeue() {
    data_t t = head->elem;
    if (!call Queue.empty()) {
      ((listElement_t*) head->next)->prev = NULL;
      head->inUse = FALSE;
      head = ((listElement_t*) head->next);
      size--;
      if (call Queue.empty()) {
        head = NULL;
        tail = NULL;
      }
printQueue();
    }
    return t;
  }

  command error_t Queue.enqueue(data_t newVal) {
    if (call Queue.size() < call Queue.maxSize()) {
      uint8_t i;
      listElement_t* newEntry;
      for (i=0; i<LIST_SIZE; i++)
        if (list[i].inUse == FALSE)
          break;
      newEntry = &list[i];
      newEntry->inUse = TRUE;
      ((listElement_t*) tail->next) = newEntry;
      ((listElement_t*) newEntry->prev) = tail;
      tail = newEntry;
      size++;
printQueue();
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command data_t Queue.element(uint8_t idx) {
    listElement_t* entry;
    uint8_t i;
    // TODO: FIX THIS if ((idx >= size) || (idx >= LIST_SIZE) || (call Queue.empty())) return NULL;
    entry = head;
    for (i=0; i<idx; i++)
      entry = ((listElement_t*) entry->next);
    return entry->elem;
  }

}
