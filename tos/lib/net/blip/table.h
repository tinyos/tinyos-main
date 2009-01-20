#ifndef TABLE_H_
#define TABLE_H_

#include <stdint.h>

typedef struct {
  void *data;
  uint16_t elt_len;
  uint16_t n_elts;
} table_t;

void table_init(table_t *table, void *data,uint16_t elt_len, uint16_t n_elts);
void *table_search(table_t *table, int (*pred)(void *));
void table_map(table_t *table, void (*fn)(void *));

#endif
