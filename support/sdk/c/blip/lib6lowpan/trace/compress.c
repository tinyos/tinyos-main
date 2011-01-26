
#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include "../lib6lowpan-includes.h"
#include "../ieee154_header.h"
#include "../lib6lowpan.h"

uint8_t frame[1500], *cur;
uint8_t fragment[128];

int main(int argc, char **argv) {
  struct ieee154_frame_addr frame_address;
  struct lowpan_reconstruct recon;
  struct lowpan_ctx ctx;
  struct ip6_packet pkt;
  struct ip_iovec iov;
  char print_buf[256];
  int idx = 0, rv;
  char c, val;
  memset(frame, 0, sizeof(frame));

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

  cur = frame;
  while ((c = getc(stdin)) != EOF) {
    c = tolower(c);
    if (c >= 'a' && c <= 'f')
      c = c - 'a' + 10;
    else if (c >= '0' && c <= '9')
      c = c - '0';
    else if (c == '\n' || c == '\r')
      break;
    else
      continue;

    if (idx++ % 2 == 0) 
      *cur |= c << 4;
    else 
      *cur++ |= c;
  }

  ieee154_print(&frame_address.ieee_src, print_buf, sizeof(print_buf));
  fprintf(stderr, "src: %s", print_buf);
  ieee154_print(&frame_address.ieee_dst, print_buf, sizeof(print_buf));
  fprintf(stderr, " dest: %s\n", print_buf);
  fprintf(stderr, "packet [%li]\n", cur - frame);
  fprint_buffer(stderr, frame, cur - frame);
  fprintf(stderr, "\n");

  if (cur - frame < sizeof(struct ip6_hdr))
    return -1;

  memset(&ctx, 0, sizeof(ctx));
  memcpy(&pkt.ip6_hdr, frame, sizeof(struct ip6_hdr));
  iov.iov_base = frame + sizeof(struct ip6_hdr);
  iov.iov_len = cur - frame - sizeof(struct ip6_hdr);
  iov.iov_next = NULL;
  pkt.ip6_data = &iov;

  while ((rv = lowpan_frag_get(fragment, sizeof(fragment),
                               &pkt, &frame_address, &ctx)) > 0) {
    fragment[0] = rv - 1;       /* set the 802.15.4 length */
    print_buffer_bare(fragment, rv);
    fprintf(stderr, "fragment [%i]\n", rv);
    fprint_buffer(stderr, fragment, rv);
    printf("\n");
  }  
}
