
#include <stdio.h>
#include <stdint.h>
// #include <assert.h>
#include <string.h>

#include "tcplib.h"

struct circ_buf {
  uint8_t  *map;
  uint16_t  map_len;
  uint8_t  *data_start;
  uint8_t  *data_head;
  uint16_t  data_len;
  uint32_t  head_seqno;
};

int circ_buf_init(void *data, int len, uint32_t seqno, int incl_map) {
  struct circ_buf *b = (struct circ_buf *)data;
  int bitmap_len = ((len - sizeof(struct circ_buf)) / 9);
  // int data_len   = bitmap_len * 8;

  // printf("circ_buf_init: len: %i data_len: %i bitmap_len: %i\n", len, data_len, bitmap_len);
  // assert(bitmap_len + data_len + sizeof(struct circ_buf) <= len);

  if (len < sizeof(struct circ_buf))
    return -1;

  if (incl_map) {
    b->map     = (uint8_t *)(b + 1);
    b->map_len = bitmap_len;
    b->data_start  = b->map + bitmap_len;
    b->data_len= bitmap_len * 8;
    memset(b->map, 0, bitmap_len * 9);
  } else {
    b->map = NULL;
    b->map_len = 0;
    b->data_start = (uint8_t *)(b + 1);
    b->data_len = len - sizeof(struct circ_buf);
    memset(b->data_start, 0, b->data_len);
  }
  b->data_head   = b->data_start;
  b->head_seqno = seqno;

  // printf("circ_buf_init: buf: %p data_start: %p data_head: %p data_len: %i\n",
  // b, b->data_start, b->data_head, b->data_len);

  return 0;
}

#define BIT_SET(off,map)       map[(off)/8] |= (1 << (7 - ((off) % 8)))
#define BIT_UNSET(off,map)     map[(off)/8] &= ~(1 << (7 - ((off) % 8)))
#define BIT_ISSET(off, map)    map[(off)/8] & 1 << (7 - (off) % 8)

static void bitmap_mark(struct circ_buf *b, uint8_t *data, int len) {
  int offset = data - b->data_start;
  if (b->map_len == 0) return;
  while (len-- > 0) {
    BIT_SET(offset, b->map);
    offset = (offset + 1) % b->data_len;
  }
}

/* return the sequence number of the first byte of data in the buffer;
   this is what the stack can ACK. */
uint32_t circ_get_seqno(void *buf) {
  struct circ_buf *b = (struct circ_buf *)buf;
  return b->head_seqno;
}

void circ_set_seqno(void *buf, uint32_t seqno) {
  struct circ_buf *b = (struct circ_buf *)buf;
  b->head_seqno = seqno;
}

uint16_t circ_get_window(void *buf) {
  struct circ_buf *b = (struct circ_buf *)buf;
  return b->data_len;
}

/* read as many contiguous bytes from the head of the buffer as
 *   possible, and update the internal data structures to shorten the
 *  buffer 
 * 
 * buf:  the circular buffer
 * data: a pointer which will be updated with the location of the data
 * return: the number of bytes available
 */
int circ_buf_read_head(void *buf, char **data) {
  struct circ_buf *b = (struct circ_buf *)buf;
  int off = b->data_head - b->data_start;
  int rlen = 0;
  *data = b->data_head;
  while (BIT_ISSET(off, b->map) && off < b->data_len) {
    BIT_UNSET(off, b->map);
    rlen++;
    b->head_seqno++;
    b->data_head ++;
    if (b->data_head == b->data_start + b->data_len)
      b->data_head = b->data_start;
    off++;
  }
  return rlen;
}


static void get_ptr_off_1(struct circ_buf *b, uint32_t sseqno, int len,
                          uint8_t **writeptr, int *w_len) {
  uint8_t *endptr =  b->data_start + b->data_len;
  int offset;

  *writeptr = NULL;
  *w_len = 0;

  /* write up to either the end of the buffer */
  offset = sseqno - b->head_seqno;
  if (b->data_head + offset < endptr) {
    *w_len = len;
    *writeptr = b->data_head + offset;
    if (*writeptr + *w_len > endptr) {
      *w_len = endptr - *writeptr;
    }
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

int circ_buf_write(void *buf, uint32_t sseqno,
                   uint8_t *data, int len) {
  struct circ_buf *b = (struct circ_buf *)buf;
  uint8_t *writeptr;
  int w_len;
  
  /* we can't write any bytes since we're trying to write too far
     ahead  */
  // printf("circ_buf_write: sseqno: %i head_seqno: %i len: %i\n",
  // sseqno, b->head_seqno, len);

  if (sseqno > b->head_seqno + b->data_len)
    return -1;

  if (sseqno < b->head_seqno) {
    /* old data, but already received */
    if (sseqno < b->head_seqno - len) return -1;
    /* a segment which overlaps with data we've already received */
    data += (b->head_seqno - sseqno);
    len  -= (b->head_seqno - sseqno);
    sseqno = b->head_seqno;
  }
  if (len == 0) return 0;

  // printf("circ_buf_write: buf: %p data_start: %p data_head: %p data_len: %i\n",
  // b, b->data_start, b->data_head, b->data_len);
  get_ptr_off_1(b, sseqno, len, &writeptr, &w_len);
  memcpy(writeptr, data, w_len);
  data += w_len;
  bitmap_mark(b, writeptr, w_len);

  if (w_len != len) {
    writeptr = b->data_start;
    w_len = min(len - w_len, b->data_head - b->data_start);
    memcpy(writeptr, data, w_len);
    bitmap_mark(b, writeptr, w_len);
    // printf("circ_buf_write (2): write: %p len: %i\n", writeptr, w_len);
  }
  return 0;
}

#ifdef PC             
void circ_buf_dump(void *buf) {
  struct circ_buf *b = (struct circ_buf *)buf;
  int i;
/*   printf("circ buf: %p\n\tmap: %p\n\tmap_len: %i\n\tdata_start: %p\n\t" */
/*          "data_head: %p\n\tdata_len: %i\n\thead_seqno: %i\n",  */
/*          b, b->map, */
/*          b->map_len, b->data_start, b->data_head, b->data_len, b->head_seqno); */

  for (i = 1; i <= b->data_len; i++) {
    if (BIT_ISSET(i-1, b->map))
      putc('x',stdout);
    else
      putc('_',stdout);
    if (i % 80 == 0 || i == b->data_len) {
      putc('\n',stdout);
    }
  }
}
#endif
