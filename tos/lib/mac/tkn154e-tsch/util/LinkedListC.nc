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


generic module LinkedListC(typedef data_t, uint8_t LIST_SIZE) {
  provides interface LinkedList<data_t>;
  provides interface Queue<data_t>;
  uses interface Compare<data_t>;
}

implementation {

  uint8_t size = 0;

  typedef struct listElement {
    struct listElement_t* prev;
    data_t ONE_NOK elem;
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

  command bool LinkedList.remove(data_t ONE element) {
    uint8_t i;
    listElement_t* entry;
    listElement_t* newHead;
    listElement_t* newTail;

    atomic {
      newHead = head;
      newTail = tail;
      entry = head;
      if (call Queue.empty())
        return FALSE;

      for (i=0; i<size; i++) {
        data_t ONE elem;
        elem = (data_t ONE) (entry->elem);
        if (call Compare.equal(elem, element)) {
          break;
        }
        entry = (listElement_t*) entry->next;
      }
      if (i == size)
        return FALSE; // element not found

      entry->inUse = FALSE;
      if (entry == head) {
        newHead = ((listElement_t*) entry->next);
      } else { //(entry != head)
        ((listElement_t*) entry->prev)->next = entry->next;
      }
      if (entry == tail) {
        newTail = ((listElement_t*) entry->prev);
      } else { //(entry != tail)
        ((listElement_t*) entry->next)->prev = entry->prev;
      }
      head = newHead;
      tail = newTail;
      size--;
      if (call Queue.empty()) {
        head = NULL;
        tail = NULL;
      }
      printQueue();
    }
    return TRUE;
  }

  command bool Queue.empty() {
    atomic return size == 0;
  }

  command bool Queue.full() {
     atomic return size >= LIST_SIZE;
  }

  command uint8_t Queue.size() {
    atomic return size;
  }

  command uint8_t Queue.maxSize() {
    atomic return LIST_SIZE;
  }

  command data_t Queue.head() {
    atomic return head->elem;
  }

//#define DTSCH_LINKED_LIST_DEBUG_PRINTF
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

  command data_t Queue.dequeue() {
    data_t t = head->elem;
    atomic {
      if (!call Queue.empty()) {
        ((listElement_t*) head->next)->prev = NULL;
        head->inUse = FALSE;
        head = ((listElement_t*) head->next);
        size--;
        if (call Queue.empty()) {
          head = NULL;
          tail = NULL;
        }
      }
      printQueue();
    }
    return t;
  }

  command error_t Queue.enqueue(data_t ONE newVal) {
    if (call Queue.size() < call Queue.maxSize()) {
      uint8_t i;
      listElement_t* newEntry;
      atomic {
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
      }
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command data_t Queue.element(uint8_t idx) {
    listElement_t* entry;
    uint8_t i;
    //if ((idx >= size) || (idx >= LIST_SIZE) || (call Queue.empty())) return NULL;
    atomic {
      entry = head;
      for (i=0; i<idx; i++)
        entry = ((listElement_t*) entry->next);
    }
    return entry->elem;
  }

}
