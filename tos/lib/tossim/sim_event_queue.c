// $Id: sim_event_queue.c,v 1.3 2006-11-07 19:31:21 scipio Exp $

/*									tab:4
* "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 *
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 *
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 */
/**
 * The simple TOSSIM wrapper around the underlying heap.
 *
 * @author Phil Levis
 * @date   November 22 2005
 */


#include <heap.h>
#include <sim_event_queue.h>

static heap_t eventHeap;

void sim_queue_init() __attribute__ ((C, spontaneous)) {
  init_heap(&eventHeap);
}

void sim_queue_insert(sim_event_t* event) __attribute__ ((C, spontaneous)) {
  dbg("Queue", "Inserting 0x%p\n", event);
  heap_insert(&eventHeap, event, event->time);
}

sim_event_t* sim_queue_pop() __attribute__ ((C, spontaneous)) {
  long long int key;
  return (sim_event_t*)(heap_pop_min_data(&eventHeap, &key));
}

bool sim_queue_is_empty() __attribute__ ((C, spontaneous)) {
  return heap_is_empty(&eventHeap);
}

long long int sim_queue_peek_time() __attribute__ ((C, spontaneous)) {
  if (heap_is_empty(&eventHeap)) {
    return -1;
  }
  else {
    return heap_get_min_key(&eventHeap);
  }
}


void sim_queue_cleanup_none(sim_event_t* event) __attribute__ ((C, spontaneous)) {
  dbg("Queue", "cleanup_none: 0x%p\n", event);
  // Do nothing. Useful for statically allocated events.
}

void sim_queue_cleanup_event(sim_event_t* event) __attribute__ ((C, spontaneous)) {
  dbg("Queue", "cleanup_event: 0x%p\n", event);
  free(event);
}

void sim_queue_cleanup_data(sim_event_t* event) __attribute__ ((C, spontaneous)) {
  dbg("Queue", "cleanup_data: 0x%p\n", event);
  free (event->data);
  event->data = NULL;
}
    
void sim_queue_cleanup_total(sim_event_t* event) __attribute__ ((C, spontaneous)) {
  dbg("Queue", "cleanup_total: 0x%p\n", event);
  free (event->data);
  event->data = NULL;
  free (event);
}

sim_event_t* sim_queue_allocate_event() {
  sim_event_t* evt = (sim_event_t*)malloc(sizeof(sim_event_t));
  memset(evt, 0, sizeof(sim_event_t));
  evt->mote = sim_node();
  return evt;
}
