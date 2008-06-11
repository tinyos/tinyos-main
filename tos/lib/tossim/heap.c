// $Id: heap.c,v 1.5 2008-06-11 00:46:26 razvanm Exp $

/*
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/* Authors:             Philip Levis
 *
 */

/*
 *   FILE: heap.h
 * AUTHOR: Philip Levis <pal@cs.berkeley.edu>
 *   DESC: Simple array-based priority heap for discrete event simulation.
 */

#include <heap.h>
#include <string.h> // For memcpy(3)
#include <stdlib.h> // for rand(3)
#include <stdio.h>  // For printf(3)

const int STARTING_SIZE = 511;

#define HEAP_NODE(heap, index) (((node_t*)(heap->data))[index])

typedef struct node {
  void* data;
  long long int key;
} node_t;

void down_heap(heap_t* heap, int findex);
void up_heap(heap_t* heap, int findex);
void swap(node_t* first, node_t* second);
node_t* prev(node_t* node);
node_t* next(node_t* next);

void init_node(node_t* node) {
  node->data = NULL;
  node->key = -1;
}

void init_heap(heap_t* heap) {
  heap->size = 0;
  heap->private_size = STARTING_SIZE;
  heap->data = malloc(sizeof(node_t) * heap->private_size);
}

int heap_size(heap_t* heap) {
  return heap->size;
}

int is_empty(heap_t* heap) {
  return heap->size == 0;
}

int heap_is_empty(heap_t* heap) {
  return is_empty(heap);
}

long long int heap_get_min_key(heap_t* heap) {
  if (is_empty(heap)) {
    return -1;
  }
  else {
    return HEAP_NODE(heap, 0).key;
  }
}

void* heap_peek_min_data(heap_t* heap) {
  if (is_empty(heap)) {
    return NULL;
  }
  else {
    return HEAP_NODE(heap, 0).data;
  }
}

void* heap_pop_min_data(heap_t* heap, long long int* key) {
  int last_index = heap->size - 1;
  void* data = HEAP_NODE(heap, 0).data;
  if (key != NULL) {
    *key = HEAP_NODE(heap, 0).key;
  }
  HEAP_NODE(heap, 0).data = HEAP_NODE(heap, last_index).data;
  HEAP_NODE(heap, 0).key = HEAP_NODE(heap, last_index).key;

  heap->size--;

  down_heap(heap, 0);

  return data;
}

void expand_heap(heap_t* heap) {
  int new_size = (heap->private_size * 2) + 1;
  void* new_data = malloc(sizeof(node_t) * new_size);

  //dbg(DBG_SIM, "Resized heap from %i to %i.\n", heap->private_size, new_size);
  
  memcpy(new_data, heap->data, (sizeof(node_t) * heap->private_size));
  free(heap->data);

  heap->data = new_data;
  heap->private_size = new_size;
  
}

void heap_insert(heap_t* heap, void* data, long long int key) {
  int findex = heap->size;
  if (findex == heap->private_size) {
    expand_heap(heap);
  }
  
  findex = heap->size;
  HEAP_NODE(heap, findex).key = key;
  HEAP_NODE(heap, findex).data = data;
  up_heap(heap, findex);

  heap->size++;
}

void swap(node_t* first, node_t* second) {
  long long int key;
  void* data;

  key = first->key;
  first->key = second->key;
  second->key = key;

  data = first->data;
  first->data = second->data;
  second->data = data;
}

void down_heap(heap_t* heap, int findex) {
  int right_index =  ((findex + 1) * 2);
  int left_index = (findex * 2) + 1;

  if (right_index < heap->size) { // Two children
    long long int left_key = HEAP_NODE(heap, left_index).key;
    long long int right_key = HEAP_NODE(heap, right_index).key;
    int min_key_index = (left_key < right_key)? left_index : right_index;

    if (HEAP_NODE(heap, min_key_index).key < HEAP_NODE(heap, findex).key) {
      swap(&(HEAP_NODE(heap, findex)), &(HEAP_NODE(heap, min_key_index)));
      down_heap(heap, min_key_index);
    }
  }
  else if (left_index >= heap->size) { // No children
    return;
  }
  else { // Only left child
    long long int left_key = HEAP_NODE(heap, left_index).key;
    if (left_key < HEAP_NODE(heap, findex).key) {
      swap(&(HEAP_NODE(heap, findex)), &(HEAP_NODE(heap, left_index)));
      return;
    }
  }
}

void up_heap(heap_t* heap, int findex) {
  int parent_index;
  if (findex == 0) {
    return;
  }

  parent_index = (findex - 1) / 2;

  if (HEAP_NODE(heap, parent_index).key > HEAP_NODE(heap, findex).key) {
    swap(&(HEAP_NODE(heap, findex)), &(HEAP_NODE(heap, parent_index)));
    up_heap(heap, parent_index);
  }
}

