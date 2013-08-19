
#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include "../lib6lowpan-includes.h"
#include "../ieee154_header.h"
#include "../lib6lowpan.h"
#include "../ip_malloc.h"

uint8_t frame[1500];
uint8_t *frame_prt = frame;
size_t frame_len = 1500;

int lowpan_extern_read_context(struct in6_addr *addr, int context) {
  memset(addr->s6_addr, 0, 0);
  addr->s6_addr16[0] = 0xaaaa;
  return 64;
}

int lowpan_extern_match_context(struct in6_addr *addr, UNUSED uint8_t *ctx_id) {
  return 0;
}

int read_packet(char *buf, int len) {
  char c;
  char *start = buf;
  int idx = 0;
  memset(buf, 0, len);
  while (len > 0 && (c = getc(stdin)) != EOF) {
    c = tolower(c);
    if (c >= 'a' && c <= 'f')
      c = c - 'a' + 10;
    else if (c >= '0' && c <= '9')
      c = c - '0';
    else if (c == '\n' || c == '\r')
      break;
    else
      continue;

    if (idx++ % 2 == 0) {
      *buf |= c << 4;
    } else {
      *buf++ |= c;
      len --;
    }
  }
  if (c == EOF) return -1;
  else return buf - start ;
}

int main(int argc, char **argv) {
  struct ieee154_frame_addr frame_address;
  struct lowpan_reconstruct recon;
  char print_buf[256];
  uint8_t *cur;
  int idx = 0, rv;
  int ret;

  ip_malloc_init();
  memset(&recon, 0, sizeof(recon));
  while ((rv = read_packet(frame, sizeof(frame))) > 0) {
    printf("packet [%i]\n", rv);
    print_buffer(frame, rv);
    printf("\n");

    frame_len = rv;

    ret = unpack_ieee154_hdr(&frame_prt, &frame_len, &frame_address);
    ieee154_print(&frame_address.ieee_src, print_buf, sizeof(print_buf));
    printf("802.15.4 source: %s\n", print_buf);
    ieee154_print(&frame_address.ieee_dst, print_buf, sizeof(print_buf));
    printf("802.15.4 dest: %s\n", print_buf);
    printf("802.15.4 destpan: 0x%x\n", letohs(frame_address.ieee_dstpan));
    printf("\n");

    if (recon.r_bytes_rcvd == 0) {
      rv = lowpan_recon_start(&frame_address, &recon,
                              frame_prt, frame_len);
    } else {
      rv = lowpan_recon_add(&recon, frame_prt, frame_len);
    }

    printf("[%i] %i %i\n", rv, recon.r_size, recon.r_bytes_rcvd);
    if (recon.r_size == recon.r_bytes_rcvd) {
      printf("reconstruction complete [%i]\n", recon.r_bytes_rcvd);
      print_buffer(recon.r_buf, recon.r_size);
      ip_free(recon.r_buf);
    }
  }
  return 0;
}
