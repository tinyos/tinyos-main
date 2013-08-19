
#include <stdint.h>
#include <stdio.h>

#include "Ieee154.h"
#include "ip.h"
#include "lib6lowpan.h"
#include "nwbyte.h"
#include "6lowpan.h"


uint8_t *unpack_udp(uint8_t *dest, uint8_t *nxt_hdr, uint8_t *buf);

struct {
  struct udp_hdr result;
  uint8_t pack_len;
  uint8_t pack[10];
} test_cases[] = {
  { {0xcdab, 0x3412, 0, 0}, 5,
    {LOWPAN_NHC_UDP_PATTERN | LOWPAN_NHC_UDP_CKSUM | LOWPAN_NHC_UDP_PORT_FULL, 0xab, 0xcd, 0x12, 0x34}},

  { {0xcdab, 0x3412, 0, 0xdead}, 7,
    {LOWPAN_NHC_UDP_PATTERN | LOWPAN_NHC_UDP_PORT_FULL, 0xab, 0xcd, 0x12, 0x34, 0xad, 0xde}},

  { {0xabcd, 0x12f0, 0, 0}, 4,
    {LOWPAN_NHC_UDP_PATTERN | LOWPAN_NHC_UDP_CKSUM | LOWPAN_NHC_UDP_PORT_SRC_FULL, 0xcd, 0xab, 0x12}},

  { {0xabf0, 0x3412, 0, 0}, 4,
    {LOWPAN_NHC_UDP_PATTERN | LOWPAN_NHC_UDP_CKSUM | LOWPAN_NHC_UDP_PORT_DST_FULL, 0xab, 0x12, 0x34}},

  { {0xbff0, 0xbaf0, 0, 0}, 2,
    {LOWPAN_NHC_UDP_PATTERN | LOWPAN_NHC_UDP_CKSUM | LOWPAN_NHC_UDP_PORT_SHORT, 0xfa}},

  { {0xbff0, 0xbaf0, 0, 0xdead}, 4,
    {LOWPAN_NHC_UDP_PATTERN | LOWPAN_NHC_UDP_PORT_SHORT, 0xfa, 0xad, 0xde}},

  { {0xabcd, 0x12f0, 0, 0xdead}, 6,
    {LOWPAN_NHC_UDP_PATTERN | LOWPAN_NHC_UDP_PORT_SRC_FULL, 0xcd, 0xab, 0x12, 0xad, 0xde}},

};


int run_tests() {
  int i, j;
  int success = 0, total = 0;
  for (i = 0; i < (sizeof(test_cases) / sizeof(test_cases[0])); i++) {
    uint8_t nxt_hdr = 0;
    uint8_t result[512];
    uint8_t *rptr = result;
    uint8_t *bptr = test_cases[i].pack+1;
    size_t dlen = 512;
    uint8_t pack_len = test_cases[i].pack_len;
    int rv;
    struct lowpan_reconstruct recon;
    struct udp_hdr *udp = (struct udp_hdr *)result;
    total++;

    rv = unpack_nhc_udp(&recon,
                    &rptr,
                    &dlen,
                    &nxt_hdr,
                    test_cases[i].pack[0],
                    &bptr,
                    &test_cases[i].pack_len);

    if (test_cases[i].pack_len != 1) {
      printf("ERROR: wrong unpack length: %p %i\n", test_cases[i].pack,
        test_cases[i].pack_len);
      continue;
    }

    if (test_cases[i].result.srcport != udp->srcport) {
      printf("ERROR: wrong srcport\n");
      continue;
    }

    if (test_cases[i].result.dstport != udp->dstport) {
      printf("ERROR: wrong dstport\n");
      continue;
    }

    if (test_cases[i].result.len != udp->len) {
      printf("ERROR: wrong length\n");
      continue;
    }

    if (test_cases[i].result.chksum != udp->chksum) {
      printf("ERROR: wrong chksum: 0x%x 0x%x\n", test_cases[i].result.chksum, udp->chksum);
      continue;
    }

    if (nxt_hdr != IANA_UDP) {
      printf("ERROR: nxt_hdr should be UDP! was 0x%02x\n", nxt_hdr);
      continue;
    }

    if (recon.r_app_len != &udp->len) {
      printf("ERROR: recon app len should point to udp len!\n");
      continue;
    }

    if (dlen != 512 - sizeof(struct udp_hdr)) {
      printf("ERROR: dest len not decremented properly. %i\n", (int) dlen);
      continue;
    }

    success++;
  }
  printf("%s: %i/%i tests succeeded\n", __FILE__, success, total);
  if (success == total) return 0;
  return 1;
}

int main() {
  return run_tests();
}
