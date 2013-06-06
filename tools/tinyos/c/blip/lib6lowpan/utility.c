
#include <stdint.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>

#include "lib6lowpan-includes.h"
#include "ip.h"

#define TO_CHAR(X) (((X) < 10) ? ('0' + (X)) : ('a' + ((X) - 10)))
#define CHAR_VAL(X)  (((X) >= '0' && (X) <= '9') ? ((X) - '0') : \
                      (((X) >= 'A' && (X) <= 'F') ? ((X) - 'A' + 10) : ((X) - 'a' + 10)))

void inet_pton6(char *addr, struct in6_addr *dest) {
  uint16_t cur = 0;
  char *p = addr;
  uint8_t block = 0, shift = 0;
  if (addr == NULL || dest == NULL) return;
  memset(dest->s6_addr, 0, 16);

  // first fill in from the front
  while (*p != '\0') {
    if (*p != ':') {
      cur <<= 4;
      cur |= CHAR_VAL(*p);
    } else {
      dest->s6_addr16[block++] = htons(cur);
      cur = 0;
    }
    p++;
    if (*p == '\0') {
      dest->s6_addr16[block++] = htons(cur);      
      return;
    }
    if (*(p - 1) == ':' && *p == ':') {
      break;
    }
  }
  // we must have hit a "::" which means we need to start filling in from the end.
  block = 7;
  cur = 0;
  while (*p != '\0') p++;
  p--;
  // now pointing at the end of the address string
  while (p > addr) {
    if (*p != ':') {
      cur |= (CHAR_VAL(*p) << shift);
      shift += 4;
    } else {
      dest->s6_addr16[block--] = htons(cur);
      cur = 0; shift = 0;
    }
    p --;
    if (*(p + 1) == ':' && *p == ':') break;
  }
}



int inet_ntop6(struct in6_addr *addr, char *buf, int cnt) {
  uint16_t block;
  char *end = buf + cnt;
  int i, j, compressed = 0;

  for (j = 0; j < 8; j++) {
    if (buf > end - 8)
      goto done;

    block = ntohs(addr->s6_addr16[j]);
    for (i = 4; i <= 16; i+=4) {
      if (block > (0xffff >> i) || (compressed == 2 && i == 16)) {
        *buf++ = TO_CHAR((block >> (16 - i)) & 0xf);
      }
    }
    if (addr->s6_addr16[j] == 0 && compressed == 0) {
      *buf++ = ':';
      compressed++;
    }
    if (addr->s6_addr16[j] != 0 && compressed == 1) compressed++;

    if (j < 7 && compressed != 1) *buf++ = ':';
  }
  if (compressed == 1)
    *buf++ = ':';
 done:
  *buf++ = '\0';
  return buf - (end - cnt);
}

uint16_t ieee154_hashaddr(ieee154_addr_t *addr) {
  if (addr->ieee_mode == IEEE154_ADDR_SHORT) {
    return addr->i_saddr;
  } else if (addr->ieee_mode == IEEE154_ADDR_EXT) {
    uint16_t i, hash = 0, *current = (uint16_t *)addr->i_laddr.data;
    for (i = 0; i < 4; i++) 
      hash += *current ++;
    return hash;
  } else {
    return 0;
  }
}

#ifndef PC

uint32_t ntohl(uint32_t i) {
  uint16_t lo = (uint16_t)i;
  uint16_t hi = (uint16_t)(i >> 16);
  lo = (lo << 8) | (lo >> 8);
  hi = (hi << 8) | (hi >> 8);
  return (((uint32_t)lo) << 16) | ((uint32_t)hi);
}

uint8_t *ip_memcpy(uint8_t *dst0, const uint8_t *src0, uint16_t len) {
  uint8_t *dst = (uint8_t *) dst0;
  uint8_t *src = (uint8_t *) src0;
  uint8_t *ret = dst0;
  
  for (; len > 0; len--)
    *dst++ = *src++;
  
  return ret;
}

#endif

#ifdef PC
char *strip(char *buf) {
  char *rv;
  while (isspace(*buf))
    buf++;
  rv = buf;

  buf += strlen(buf) - 1;
  while (isspace(*buf)) {
    *buf = '\0';
    buf--;
  }
  return rv;
}

int ieee154_parse(char *in, ieee154_addr_t *out) {
  int i;
  long val;
  char *endp = in;
  long saddr = strtol(in,  &endp, 16);
  // fprintf(stderr, "ieee154_parse: %s, %c\n", in, *endp);

  if (*endp == ':') {
    endp = in;
    // must be a long address
    for (i = 0; i < 8; i++) {
      val = strtol(endp, &endp, 16);
      out->i_laddr.data[7-i] = val;
      endp++;
    }
    out->ieee_mode = IEEE154_ADDR_EXT;
  } else {
    out->i_saddr = htole16(saddr);
    out->ieee_mode = IEEE154_ADDR_SHORT;
  }

  return 0;
}

int ieee154_print(ieee154_addr_t *in, char *out, size_t cnt) {
  int i;
  char *cur = out;
  switch (in->ieee_mode) {
  case IEEE154_ADDR_SHORT:
    snprintf(out, cnt, "IEEE154_ADDR_SHORT: 0x%x", in->i_saddr);
    break;
  case IEEE154_ADDR_EXT:
    cur += snprintf(out, cnt, "IEEE154_ADDR_EXT: ");

    for (i = 0; i < 8; i++) {
      cur += snprintf(cur, cnt - (cur - out), "%02x", in->i_laddr.data[i]);
      if (i < 7)
        *cur++ = ':';
    }
    break;
  }
  return 0;
}

void fprint_buffer(FILE *fp, uint8_t *buf, int len) {
  int i;
  for (i = 0; i < len; i++) {
    if ((i % 16) == 0 && i > 0) 
      fprintf(fp, "\n");
    if (i % 16 == 0) {
      fprintf(fp, "%i:\t", i);
    }
    fprintf(fp, "%02x ", buf[i]);
  }
  fprintf(fp, "\n");
}

void print_buffer(uint8_t *buf, int len) {
  fprint_buffer(stdout, buf, len);
}

void print_buffer_bare(uint8_t *buf, int len) {
  while (len--) {
    printf("%02x ", *buf++);
  }
}

void scribble(uint8_t *buf, int len) {
  int i;
  for (i = 0; i < len; i++) {
    buf[i] = rand();
  }
}

void iov_print(struct ip_iovec *iov) {
  struct ip_iovec *cur = iov;
  while (cur != NULL) {
    int i;
    printf("iovec (%p, %i) ", cur, (int)cur->iov_len);
    for (i = 0; i < cur->iov_len; i++) {
      printf("%02hhx ", cur->iov_base[i]);
    }
    printf("\n");
    cur = cur->iov_next;
  }
}

#endif
