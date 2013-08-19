#include <stdint.h>
#include <string.h>
#ifdef UNIT_TESTING
#include <stdio.h>
#endif

#include "6lowpan.h"
#include "Ieee154.h"
#include "ip.h"
#include "lib6lowpan.h"
#include "nwbyte.h"
#include "internal.h"



struct {
  uint8_t hdr[128];
} ip_hdrs[] = {
  {IPV6_DEST, 8,  0,1,2,3,4,5},
  {IANA_UDP,  10, 0,1,2,3,4,5,6,7},
};


struct ip6_packet packet;
struct ip_iovec vec[3];

struct {
  struct udp_hdr udp;
  uint8_t data[5];
} udppkt = {
  {0xabcd, 0x1234, 13, 0xdead},
  {0x55, 0x66, 0x77, 0x88, 0x99}
};

int main() {
  uint8_t nxt;
  uint8_t buf[512], result[512], *bufp;
  uint8_t *bptr = buf;
  uint8_t *rptr = result;
  size_t rlen = 512;
  int i, len;
  size_t blen = 128;
  struct lowpan_reconstruct recon;
  int ret;

  bufp = buf;
  packet.ip6_hdr.ip6_nxt = IPV6_HOP;

  iov_prefix(NULL, &vec[2], (uint8_t *)&udppkt, sizeof(udppkt));
  iov_prefix(&vec[2], &vec[1], ip_hdrs[1].hdr, 10);
  iov_prefix(&vec[1], &vec[0], ip_hdrs[0].hdr, 8);

  packet.ip6_data = vec;

  for (i=0; i<128; i++) {
    printf("%02x", ip_hdrs[0].hdr[i]);
  }
  printf("\n");

  len = pack_nhc_chain(&bufp, 512, &packet);
  printf("[%i] ", len);
  if (len < 0) {
    printf("ERROR: packing chain failed\n");
    return 1;
  }
  for (i = 0; i < len; i++) {
    printf("0x%hhx ", buf[i]);
  }
  printf("\n\n");

  unpack_nhc_chain(&recon, &rptr, &rlen, &nxt, &bptr, &blen);
  for (i = 0; i < 26; i++)
    printf("0x%hhx ", result[i]);
  printf("\n");

  ret = memcmp(packet.ip6_data, rptr, 18 + sizeof(udppkt));
  if (ret != 0) {
    printf("ERROR: did not unpack what we packed.\n");
    return 1;
  }

  printf("Done!\n");
}
