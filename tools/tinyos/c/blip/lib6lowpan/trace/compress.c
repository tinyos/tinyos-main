
#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include "../lib6lowpan-includes.h"
#include "../ieee154_header.h"
#include "../lib6lowpan.h"
#include "../ip_malloc.h"

uint8_t *cur;
uint8_t fragment[100];

int lowpan_extern_read_context(struct in6_addr *addr, int context) {
  memset(addr->s6_addr, 0, 0);
  addr->s6_addr16[0] = 0xaaaa;
  return 64;
}

int lowpan_extern_match_context(struct in6_addr *addr, UNUSED uint8_t *ctx_id) {
  return 0;
}

struct ip_iovec *iov_shorten(struct ip_iovec *v, int off) {
  int cur_off = 0;
  struct ip_iovec *rv = malloc(sizeof(struct ip_iovec));
  while (v != NULL && cur_off + v->iov_len <= off) {
    cur_off += v->iov_len;
    v = v->iov_next;
  }
  if (v == NULL) return NULL;
  if (off == cur_off) return v;

  rv->iov_base = &((uint8_t *)v->iov_base)[off - cur_off];
  rv->iov_len = v->iov_len - (off - cur_off);
  rv->iov_next = v->iov_next;
  return rv;
}

int main(int argc, char **argv) {
  struct ieee154_frame_addr frame_address;
  struct lowpan_reconstruct recon;
  struct lowpan_ctx ctx;
  struct ip6_packet pkt;
  char print_buf[256];
  int idx = 0, rv;
  char c, val;
  struct ip_iovec *v, *tail;
  //memset(frame, 0, sizeof(frame));

  ip_malloc_init();

  /* read destination */
  cur = print_buf;
  while ((c = getc(stdin)) != '\n')
    *cur++ = c;
  *cur++ = '\0';
  ieee154_parse(print_buf, &frame_address.ieee_src);

  /* read source */
  cur = print_buf;
  while ((c = getc(stdin)) != '\n')
    *cur++ = c;
  *cur++ = '\0';
  ieee154_parse(print_buf, &frame_address.ieee_dst);
  frame_address.ieee_dstpan = 0x22;

  v = malloc(sizeof(struct ip_iovec));
  v->iov_base = malloc(1500);
  v->iov_len = 0;
  v->iov_next = NULL;
  tail = v;
  cur = v->iov_base;
  while ((c = getc(stdin)) != EOF) {
    c = tolower(c);
    if (c >= 'a' && c <= 'f'){
      c = c - 'a' + 10;
    } else if (c >= '0' && c <= '9') {
      c = c - '0';
    } else if (c == '\n' || c == '\r') {
      if (v->iov_len > 0) {
        fprintf(stderr, "Making new (%i)\n", (int) v->iov_len);
        struct ip_iovec *v2 = malloc(sizeof(struct ip_iovec));
        v2->iov_next = NULL;
        v2->iov_len = 0;
        v2->iov_base = malloc(1500);
        tail->iov_next = v2;
        tail = tail->iov_next;
        cur = tail->iov_base;
      }
      continue;
    } else
      continue;

    if (idx++ % 2 == 0) {
      *cur |= c << 4;
    } else {
      *cur++ |= c;
      tail->iov_len ++;
    }
  }

  ieee154_print(&frame_address.ieee_src, print_buf, sizeof(print_buf));
  fprintf(stderr, "src: %s", print_buf);
  ieee154_print(&frame_address.ieee_dst, print_buf, sizeof(print_buf));
  fprintf(stderr, " dest: %s\n", print_buf);
  //fprintf(stderr, "packet [%li]\n", cur - frame);
  //fprint_buffer(stderr, frame, cur - frame);
  fprintf(stderr, "\n");

  if (iov_len(v) < sizeof(struct ip6_hdr))
    return 1;

  memset(&ctx, 0, sizeof(ctx));
  iov_read(v, 0, sizeof(struct ip6_hdr), (void*) &pkt.ip6_hdr);
  pkt.ip6_data = iov_shorten(v, sizeof(struct ip6_hdr));
  pkt.ip6_hdr.ip6_plen = htons(iov_len(pkt.ip6_data));
  // iov_print(v);

  while ((rv = lowpan_frag_get(fragment, sizeof(fragment),
                               &pkt, &frame_address, &ctx)) > 0) {
    fragment[0] = rv - 1;       /* set the 802.15.4 length */
    print_buffer_bare(fragment, rv);
    fprintf(stderr, "fragment [%i]\n", rv);
    fprint_buffer(stderr, fragment, rv);
    printf("\n");
  }
}
