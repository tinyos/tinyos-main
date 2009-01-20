
#include <stdlib.h>
#include "table.h"

void table_init(table_t *table, void *data,
                uint16_t elt_len, uint16_t n_elts) {
  table->data = data;
  table->elt_len  = elt_len;
  table->n_elts   = n_elts;
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

