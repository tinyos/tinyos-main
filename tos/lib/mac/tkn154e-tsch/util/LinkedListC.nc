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
 *  A message_t* FIFO queue component, where intermediate elements can be removed.
 */


generic module LinkedListC(uint8_t LIST_SIZE) {
  provides interface LinkedList<message_t*>;
  provides interface Queue<message_t*>;
}

implementation {

  uint8_t size = 0;

  typedef struct listElement {
    struct listElement_t* prev;
    message_t* ONE_NOK elem;
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

  command bool LinkedList.remove(message_t* ONE element) {
    uint8_t i;
    listElement_t* entry;
    listElement_t* newHead = head;
    listElement_t* newTail = tail;
    entry = head;

    if (call Queue.empty())
      return FALSE;

    for (i=0; i<size; i++) {
      message_t* ONE elem;
      elem = (message_t* ONE) (entry->elem);
      if (elem == element)
        break;
      entry = (listElement_t*) entry->next;
    }
    if (i == LIST_SIZE)
      return FALSE; // element not found

    if (entry != head)
      ((listElement_t*) entry->prev)->next = entry->next;
    if (entry != tail)
      ((listElement_t*) entry->next)->prev = entry->prev;
    entry->inUse = FALSE;
    if (entry == head) {
      newHead = ((listElement_t*) entry->next);
      //if (entry != tail)((listElement_t*) entry->next)->prev = NULL;
    }
    if (entry == tail) {
      newTail = ((listElement_t*) entry->prev);
      //if (entry != head) ((listElement_t*) entry->prev)->next = NULL;
    }
    head = newHead;
    tail = newTail;
    size--;
    if (call Queue.empty()) {
      head = NULL;
      tail = NULL;
    }
  printQueue();
  return TRUE;
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

  command message_t* Queue.head() {
    return head->elem;
  }

#ifdef DTSCH_LINKED_LIST_DEBUG_PRINTF
  void printQueue() {
    int i;
    printf("(head: %p, tail: %p. size: %u)\n", head, tail, size);
    for (i=0; i<LIST_SIZE; i++) {
      if (list[i].inUse == TRUE)
        printf("--> ");
      else
        printf("    ");
      printf("%p: %p %p %p\n",&list[i], list[i].prev, list[i].elem, list[i].next);
    }
    printfflush();
  }
#else
  void inline printQueue() {}
#endif

  command message_t* Queue.dequeue() {
    message_t* t = head->elem;
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

  command error_t Queue.enqueue(message_t* ONE newVal) {
    if (call Queue.size() < call Queue.maxSize()) {
      uint8_t i;
      listElement_t* newEntry;
      for (i=0; i<LIST_SIZE; i++)
        if (list[i].inUse == FALSE)
          break;
      newEntry = &list[i];
      if (head == NULL)
        head = newEntry;
      newEntry->inUse = TRUE;
      newEntry->elem = newVal;
      tail->next = (struct listElement_t*) newEntry;
      newEntry->prev = (struct listElement_t*) tail;
      newEntry->next = (struct listElement_t*) NULL;
      tail = newEntry;
      size++;
      printQueue();
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command message_t* Queue.element(uint8_t idx) {
    listElement_t* entry;
    uint8_t i;
    if ((idx >= size) || (idx >= LIST_SIZE) || (call Queue.empty())) return NULL;
    entry = head;
    for (i=0; i<idx; i++)
      entry = ((listElement_t*) entry->next);
    return entry->elem;
  }

}
