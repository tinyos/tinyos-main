#ifndef __CIRC_H_
#define __CIRC_H_

#include <stdint.h>

int circ_buf_init(void *data, int len, uint32_t seqno, int inc_map);


int circ_buf_write(void *buf, uint32_t sseqno,
                   uint8_t *data, int len);


int circ_buf_read(void *buf, uint32_t sseqno,
                  uint8_t *data, int len);


int circ_shorten_head(void *buf, uint32_t seqno);

/* read from the head of the buffer, moving the data pointer forward */
int circ_buf_read_head(void *buf, char **data);

void circ_buf_dump(void *buf);

void circ_set_seqno(void *buf, uint32_t seqno);

#endif
