#include <stdint.h>
#include <stdio.h>

#include "lib6lowpan.h"
#include "iovec.h"

#define MIN(X,Y) ((X) < (Y) ? (X) : (Y))
/**
 * read len bytes starting at offset into the buffer pointed to by buf
 *
 *  
 */
int iov_read(struct ip_iovec *iov, int offset, int len, uint8_t *buf) {
  int cur_offset = 0, written = 0;
  // printf("iov_read iov: %p offset: %i len: %i buf: %p\n", iov, offset, len, buf);

  while (iov != NULL && cur_offset + iov->iov_len <= offset) {
    cur_offset += iov->iov_len;
    iov = iov->iov_next;
  }
  if (!iov) goto done;

  while (len > 0) {
    int start, len_here;
    start      = offset - cur_offset;
    len_here   = MIN(iov->iov_len - start, len);

    // copy
    memcpy(buf, iov->iov_base + start, len_here);
    // printf("iov_read: %i/%i\n", len_here, len);

    cur_offset += start + len_here;
    offset     += len_here;
    written    += len_here;
    len        -= len_here;
    buf        += len_here;
    iov         = iov->iov_next;

    if (!iov) {
      goto done;
    }
  }
 done:
  return written;
}

int iov_len(struct ip_iovec *iov) {
  int rv = 0;
  while (iov) {
    rv += iov->iov_len;
    iov = iov->iov_next;
  }
  return rv;
}

void iov_prefix(struct ip_iovec *iov, struct ip_iovec *new, uint8_t *buf, size_t len) {
  new->iov_base = buf;
  new->iov_len = len;
  new->iov_next = iov;
}

int iov_update(struct ip_iovec *iov, int offset, int len, uint8_t *buf) {
  int written = 0;

  /* advance to the first block where we could write */
  while (offset >= iov->iov_len) {
    offset -= iov->iov_len;
    iov = iov->iov_next;
  }

  while (iov != NULL && written < len) {
    int writelen = MIN(iov->iov_len - offset, len);
    memcpy(iov->iov_base + offset, buf, writelen);
    buf += writelen;
    len -= writelen;
    offset = 0;
    iov = iov->iov_next;
  }
  return written;
}
