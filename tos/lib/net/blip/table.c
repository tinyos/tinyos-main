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

#include <stdlib.h>
#include "table.h"

void table_init(table_t *table, void *data,
                uint16_t elt_len, uint16_t n_elts) {
  table->data    = data;
  table->elt_len = elt_len;
  table->n_elts  = n_elts;
}

void *table_search(table_t *table, int (*pred)(void *)) {
  int i;
  void *cur;
  for (i = 0; i < table->n_elts; i++) {
    cur = table->data + (i * table->elt_len);
    switch (pred(cur)) {
    case 1: return cur;
    case -1: return NULL;
    default: continue;
    }
  }
  return NULL;
}

void table_map(table_t *table, void(*fn)(void *)) {
  int i;
  for (i = 0; i < table->n_elts; i++)
    fn(table->data + (i * table->elt_len));
}
