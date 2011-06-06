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

#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include "tcplib.h"

struct circ_buf {
  uint8_t  *data_start;
  uint8_t  *data_head;
  uint16_t  data_len;
  uint32_t  head_seqno;
};

int circ_buf_init(void *data, int len, uint32_t seqno) {
  struct circ_buf *b = (struct circ_buf *)data;

  if (len < sizeof(struct circ_buf))
    return -1;

  b->data_head = b->data_start = (uint8_t *)(b + 1);
  b->data_len = len - sizeof(struct circ_buf);
  b->head_seqno = seqno;
  return 0;
}

uint32_t circ_get_seqno(void *buf) {
  struct circ_buf *b = (struct circ_buf *)buf;
  return b->head_seqno;
}

void circ_set_seqno(void *buf, uint32_t seqno) {
  struct circ_buf *b = (struct circ_buf *)buf;
  b->head_seqno = seqno;
}

static void get_ptr_off_1(struct circ_buf *b, uint32_t sseqno, int len,
                          uint8_t **writeptr, int *w_len) {
  uint8_t *endptr =  b->data_start + b->data_len;
  int offset;

  *writeptr = NULL;
  *w_len = len;

  /* write up to either the end of the buffer */
  offset = sseqno - b->head_seqno;
  if (b->data_head + offset < endptr) {
    *writeptr = b->data_head + offset;
  } else {
    offset -= (endptr - b->data_head);
    *writeptr = b->data_start + offset;
  }
  if (*writeptr + *w_len > endptr) {
    *w_len = endptr - *writeptr;
  }
}

int circ_shorten_head(void *buf, uint32_t seqno) {
  struct circ_buf *b = (struct circ_buf *)buf;
  int offset = seqno - b->head_seqno;

  b->head_seqno = seqno;
  b->data_head += offset;

  while (b->data_head > b->data_start + b->data_len)
    b->data_head -= b->data_len;

  return 0;
}

int circ_buf_read(void *buf, uint32_t sseqno,
                  uint8_t *data, int len) {
  struct circ_buf *b = (struct circ_buf *)buf;
  uint8_t *readptr;
  int r_len, rc = 0;

  get_ptr_off_1(b, sseqno, len, &readptr, &r_len);
  memcpy(data, readptr, r_len);
  data += r_len;
  rc += r_len;
  
  if (r_len != len) {
    readptr = b->data_start;
    r_len = min(len - r_len, b->data_head - b->data_start);
    memcpy(data, readptr, r_len);
    rc += r_len;
  }
  return rc;
}

int circ_buf_write(char *buf, uint32_t sseqno,
                   uint8_t *data, int len) {
  struct circ_buf *b = (struct circ_buf *)buf;
  uint8_t *writeptr;
  int w_len;
  /* we can't write any bytes since we're trying to write too far
     ahead  */
  if (sseqno > b->head_seqno + b->data_len)
    return -1;
  if (len == 0) return 0;

  get_ptr_off_1(b, sseqno, len, &writeptr, &w_len);

  memcpy(writeptr, data, w_len);
  data += w_len;

  if (w_len != len) {
    writeptr = b->data_start;
    w_len = min(len - w_len, b->data_head - b->data_start);
    memcpy(writeptr, data, w_len);
  }

  return 0;
}

#ifdef PC             
void circ_buf_dump(void *buf) {
  struct circ_buf *b = (struct circ_buf *)buf;
  uint8_t *d;
  int i;
/*   printf("circ buf: %p\n\tmap: %p\n\tmap_len: %i\n\tdata_start: %p\n\t" */
/*          "data_head: %p\n\tdata_len: %i\n\thead_seqno: %i\n",  */
/*          b, b->map, */
/*          b->map_len, b->data_start, b->data_head, b->data_len, b->head_seqno); */
  for (d = b->data_start; d < b->data_start + b->data_len; d++) {
    if (d == b->data_head) putc('|', stdout);
    printf("%2.x ", *d);
  }
  putc('\n', stdout);
}
#endif
