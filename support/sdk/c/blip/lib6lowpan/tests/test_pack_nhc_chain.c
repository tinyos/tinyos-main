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
  {IPV6_DEST, 15,  0x1F,4,2,3,4,5},
  {IANA_UDP,  15, 0x03,1,2, 0x04,2,5,6, 0x0E,7,1,2,3,4,5,6,7},
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
  uint8_t *bptr2 = buf;
  uint8_t *rptr = result;
  size_t rlen = 512;
  int i, len;
  size_t blen = 512;
  size_t blen2 = 0;
  struct lowpan_reconstruct recon;
  int ret;
  struct ip_iovec v[1];
  struct ip6_packet pkt2;
  uint8_t outbuf[512];
  uint8_t *outbufptr = outbuf;
  size_t outbuflen = 512;
  uint8_t success = 0;
  uint8_t total = 0;

  bufp = buf;
  packet.ip6_hdr.ip6_nxt = IPV6_HOP;

  iov_prefix(NULL, &vec[2], (uint8_t *)&udppkt, sizeof(udppkt));
  iov_prefix(&vec[2], &vec[1], ip_hdrs[1].hdr, 128);
  iov_prefix(&vec[1], &vec[0], ip_hdrs[0].hdr, 128);

  packet.ip6_data = vec;

  for (i=0; i<128; i++) {
    printf("%02x", vec[0].iov_base[i]);
  }
  printf("\n");

  len = pack_nhc_chain(&bufp, &blen, &packet);
  printf("used %i bytes from source\n", len);
  printf("[%i] ", 512-blen);
  if (len < 0) {
    printf("ERROR: packing chain failed\n");
    return 1;
  }
  printf("packed: 0x");
  for (i = 0; i < 512-blen; i++) {
    printf("%02x", buf[i]);
  }
  printf("\n\n");

  blen2 = 512-blen;
  unpack_nhc_chain(&recon, &rptr, &rlen, &nxt, &bptr2, &blen2);
  printf("unpacked: 0x");
  for (i = 0; i < 512-rlen; i++)
    printf("%02x", result[i]);
  printf("\n");

  v->iov_base = result;
  v->iov_len = 512-rlen;
  v->iov_next = NULL;

  pkt2.ip6_data = v;
  pkt2.ip6_hdr.ip6_nxt = IPV6_HOP;
  len = pack_nhc_chain(&outbufptr, &outbuflen, &pkt2);
  printf("[xx] packed: 0x");
  for (i = 0; i < 512-outbuflen; i++) {
    printf("%02x", outbuf[i]);
  }
  printf("\n");

  total++;

  ret = memcmp(outbuf, buf, 512-outbuflen);
  if (ret != 0) {
    printf("ERROR: did not unpack what we packed.\n");
    return 1;
  } else {
    success++;
  }

  printf("%s: %i/%i tests succeeded\n", __FILE__, success, total);
}
