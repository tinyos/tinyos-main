#ifndef IOVEC_H_
#define IOVEC_H_

#include <stdint.h>
#include <stddef.h>

struct ip_iovec {
  uint8_t         *iov_base;
  size_t           iov_len;
  struct ip_iovec *iov_next;
};

int iov_read(struct ip_iovec *iov, int offset, int len, uint8_t *buf);
int iov_len(struct ip_iovec *iov);
void iov_prefix(struct ip_iovec *iov, struct ip_iovec *new_iov, uint8_t *buf, size_t len);
int iov_update(struct ip_iovec *iov, int offset, int len, uint8_t *buf);
void iov_print(struct ip_iovec *iov);

#endif
