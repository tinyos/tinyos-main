
#include <stdint.h>
#include <stdio.h>

#include "Ieee154.h"
#include "ip.h"
#include "lib6lowpan.h"
#include "nwbyte.h"
#include "6lowpan.h"
#include "internal.h"


struct {
  char   *prefix;
  uint8_t pfx_len;
} prefix_options[] = {
  {"2002::", 64},
  {"2002:1:2:3:4:5:6:7", 128},
};

int lowpan_extern_read_context(struct in6_addr *addr, int context) {
  struct in6_addr ctx;
  inet_pton6(prefix_options[context].prefix, &ctx);
  memcpy(addr->s6_addr, ctx.s6_addr, prefix_options[context].pfx_len / 8);
}
int lowpan_extern_match_context(struct in6_addr *addr, UNUSED uint8_t *ctx_id) {
}

struct {
  char *address;
  int   dispatch;
  int   context;
  int   len;
  uint8_t  buf[32];
} test_cases[] = {
  {"ff02::1", LOWPAN_IPHC_AM_M | LOWPAN_IPHC_AM_M_8, 0, 1, {1}},
  {"ff18::ab:cdef:1234", LOWPAN_IPHC_AM_M | LOWPAN_IPHC_AM_M_48, 0, 6, {0x18, 0xab, 0xcd, 0xef, 0x12, 0x34}},
  {"ffff::ef:1234", LOWPAN_IPHC_AM_M | LOWPAN_IPHC_AM_M_32, 0, 4, {0xff, 0xef, 0x12, 0x34}},
  {"2002:1:2:3:4:5:6:7", LOWPAN_IPHC_AM_M | LOWPAN_IPHC_AM_M_128, 0, 16, {0x20, 0x02, 0,1,0,2,0,3,0,4,0,5,0,6,0,7}},
};

 int run_tests() {
  int i;
  int success = 0, total = 0;
  for (i = 0; i < (sizeof(test_cases) / sizeof(test_cases[0])); i++) {
    struct in6_addr addr, correct;
    uint8_t buf[512];
    uint8_t *bptr = test_cases[i].buf;
    size_t len = 32;
    int rv;
    total++;

    inet_pton6(test_cases[i].address, &correct);

    printf("in6_addr: %s\n", test_cases[i].address);
    rv = unpack_multicast(&addr,
                          test_cases[i].dispatch,
                          test_cases[i].context,
                          &bptr,
                          &len);

    inet_ntop6(&addr, buf, 512);
    printf("result: %s length: %li\n", buf, 32 - len);

    if (test_cases[i].len != 32 - len)
      continue;

    if (memcmp(&addr, &correct, 16) != 0)
      continue;

    success++;
  }
  printf("%s: %i/%i tests succeeded\n", __FILE__, success, total);
  if (success == total) return 0;
  return 1;
}

int main() {
  return run_tests();
}
