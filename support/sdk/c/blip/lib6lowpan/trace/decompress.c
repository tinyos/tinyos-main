
#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include "../lib6lowpan-includes.h"
#include "../ieee154_header.h"
#include "../lib6lowpan.h"

uint8_t frame[1500], *cur;

int main(int argc, char **argv) {
  struct ieee154_frame_addr frame_address;
  struct lowpan_reconstruct recon;
  char print_buf[256];
  int idx = 0, rv;
  char c, val;
  memset(frame, 0, sizeof(frame));

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

  printf("packet [%li]\n", cur - frame);
  print_buffer(frame, cur - frame);
  printf("\n");

  cur = unpack_ieee154_hdr(frame, &frame_address);
  ieee154_print(&frame_address.ieee_src, print_buf, sizeof(print_buf));
  printf("802.15.4 source: %s\n", print_buf);
  ieee154_print(&frame_address.ieee_dst, print_buf, sizeof(print_buf));
  printf("802.15.4 dest: %s\n", print_buf);
  printf("802.15.4 destpan: 0x%x\n", letohs(frame_address.ieee_dstpan));
  printf("\n");

  rv = lowpan_recon_start(&frame_address, &recon,
                          cur, frame[0] - (cur - frame) + 1);
  printf("lowpan_recon_start: %i len: %i\n", rv, recon.r_size);
  if (rv == 0) {
    print_buffer(recon.r_buf, recon.r_size);
    free(recon.r_buf);
  }
  
}
