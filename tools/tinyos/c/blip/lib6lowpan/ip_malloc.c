/*
 * "Copyright (c) 2008, 2009 The Regents of the University  of California.
 * All rights reserved."
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
 */
#ifndef NO_IP_MALLOC
#include <stdint.h>
#include <stdio.h>
#include "ip_malloc.h"

uint8_t heap[IP_MALLOC_HEAP_SIZE];

void ip_malloc_init() {
  bndrt_t *b = (bndrt_t *)heap;
  *b = IP_MALLOC_HEAP_SIZE  & IP_MALLOC_LEN;
}

void *ip_malloc(uint16_t sz) {
  bndrt_t *cur = (bndrt_t *)heap;

  sz += sizeof(bndrt_t) * 2;
  sz += (sz % IP_MALLOC_ALIGN);

  while (((*cur & IP_MALLOC_LEN) < sz || (*cur & IP_MALLOC_INUSE) != 0)
         && (uint8_t *)cur - heap < IP_MALLOC_HEAP_SIZE) {
    cur = (bndrt_t *)(((uint8_t *)cur) + ((*cur) & IP_MALLOC_LEN));
  }

  if ((uint8_t *)cur < heap + IP_MALLOC_HEAP_SIZE) {
    uint16_t oldsize = *cur & IP_MALLOC_LEN;
    bndrt_t *next;
    sz -= sizeof(bndrt_t);
    next = ((bndrt_t *)(((uint8_t *)cur) + sz));

    *cur = (sz & IP_MALLOC_LEN) | IP_MALLOC_INUSE;
    *next = (oldsize - sz) & IP_MALLOC_LEN;

    return cur + 1;
  } else return NULL;
}

void ip_free(void *ptr) {
  bndrt_t *prev = NULL, *cur, *next = NULL;
  cur = (bndrt_t *)heap;

  while (cur + 1 != ptr && (uint8_t *)cur - heap < IP_MALLOC_HEAP_SIZE) {
    prev = cur;
    cur = (bndrt_t *)(((uint8_t *)cur) + ((*cur) & IP_MALLOC_LEN));
  }
  if (cur + 1 == ptr) {
    next = (bndrt_t *)((*cur & IP_MALLOC_LEN) + ((uint8_t *)cur));

    *cur &= ~IP_MALLOC_INUSE;
    if ((((uint8_t *)next) - heap) < IP_MALLOC_HEAP_SIZE &&
        (*next & IP_MALLOC_INUSE) == 0) {
      *cur = (*cur & IP_MALLOC_LEN) + (*next & IP_MALLOC_LEN);
    }
    if (prev != NULL && (*prev & IP_MALLOC_INUSE) == 0) {
      *prev = (*prev & IP_MALLOC_LEN) + (*cur & IP_MALLOC_LEN);
    }
  }
}

uint16_t ip_malloc_freespace() {
  uint16_t ret = 0;
  bndrt_t *cur = (bndrt_t *)heap;

  while ((uint8_t *)cur - heap < IP_MALLOC_HEAP_SIZE) {
    if ((*cur & IP_MALLOC_INUSE) == 0)
      ret += *cur & IP_MALLOC_LEN;
    cur = (bndrt_t *)(((uint8_t *)cur) + ((*cur) & IP_MALLOC_LEN));
  }
  return ret;
}

#ifdef PC
#include <stdlib.h>
void dump_heap() {
  int i;
  for (i = 0; i < IP_MALLOC_HEAP_SIZE; i++) {
    printf("0x%hx ", heap[i]);
    if (i % 8 == 7) printf("  ");
    if (i % 16 == 15) printf ("\n");
    if (i > 64) break;
  }
  printf("\n");
}

void ip_print_heap() {
  bndrt_t *cur = (bndrt_t *)heap;
  while (((uint8_t *)cur)  - heap < IP_MALLOC_HEAP_SIZE) {
    printf ("heap region start: %p length: %i used: %i\n",
            cur, (*cur & IP_MALLOC_LEN), (*cur & IP_MALLOC_INUSE) >> 15);
    if ((*cur & IP_MALLOC_LEN) == 0) {
      printf("ERROR: zero length cell detected!\n");
      dump_heap();
      exit(1);
    }
    cur = (bndrt_t *)(((uint8_t *)cur) + ((*cur) & IP_MALLOC_LEN));

  }
}
#endif
#endif
