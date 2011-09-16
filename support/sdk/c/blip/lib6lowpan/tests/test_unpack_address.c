
#include <stdint.h>
#include <stdio.h>

#include "Ieee154.h"
#include "ip.h"
#include "lib6lowpan.h"
#include "nwbyte.h"
#include "6lowpan.h"

uint8_t *unpack_address(struct in6_addr *addr, uint8_t dispatch, 
                        int context, uint8_t *buf,
                        ieee154_addr_t *frame, ieee154_panid_t pan);

struct {
  char   *prefix;
  uint8_t pfx_len;
} prefix_options[] = {
  {"2002::", 64},
  {"2002:1:2:3:4:5:6:7", 128},
};

int lowpan_extern_read_context(struct in6_addr *addr, int context) {
  struct in6_addr ctx;
  printf("read context: %i (%i)\n", context,
         prefix_options[context].pfx_len);
  inet_pton6(prefix_options[context].prefix, &ctx);
  print_buffer(ctx.s6_addr, 16);
  memcpy(addr->s6_addr, ctx.s6_addr, prefix_options[context].pfx_len / 8);
  return prefix_options[context].pfx_len;
}
int lowpan_extern_match_context(struct in6_addr *addr, UNUSED uint8_t *ctx_id) {
}

struct {
  char *address;
  int   dispatch;
  int   context;
  int   len;
  char  buf[32];
  char *l2addr;
  ieee154_panid_t   panid;
  
} test_cases[] = {
  // context-free tests
  {"fe80::1", LOWPAN_IPHC_AM_16, 0, 2, {0, 1}, "1", 1},
  {"fe80::ffff", LOWPAN_IPHC_AM_16, 0, 2, {0xff, 0xff}, "1", 1},
  {"fe80::abde:f012", LOWPAN_IPHC_AM_64, 0, 8, {0, 0, 0, 0, 0xab, 0xde, 0xf0, 0x12}, "1", 1},
  {"fe80::1234:8765:abde:f012", LOWPAN_IPHC_AM_64, 0, 8, {0x12, 0x34, 0x87, 0x65, 0xab, 0xde, 0xf0, 0x12}, "1", 1},
  {"fe80:1234:8765:abde:1234:8765:abde:f012", LOWPAN_IPHC_AM_128, 0, 16, 
   {0xfe, 0x80, 0x12, 0x34, 0x87, 0x65, 0xab, 0xde, 0x12, 0x34, 0x87, 0x65, 0xab, 0xde, 0xf0, 0x12}, "1", 1},

  // derived from the MAC address
  {"fe80::1234:8765:abde:f012", LOWPAN_IPHC_AM_0, 0, 0, {}, "10:34:87:65:ab:de:f0:12", 1},

  // RFC4944-style addresses
  {"fe80::1:00ff:fe00:25", LOWPAN_IPHC_AM_0, 0, 0, {}, "25", 1},

  {"fe80::fdff:00ff:fe00:25", LOWPAN_IPHC_AM_0, 0, 0, {}, "25", 0xffff},

  {"fe80::fdff:00ff:fe00:abcd", LOWPAN_IPHC_AM_0, 0, 0, {}, "abcd", 0xffff},

  // tests using context
  {"2002::12", LOWPAN_IPHC_AC_CONTEXT |  LOWPAN_IPHC_AM_16, 0, 2, {0, 0x12}, "1", 1},

  {"2002:1:2:3:4:5:6:7", LOWPAN_IPHC_AC_CONTEXT |  LOWPAN_IPHC_AM_0, 1, 0, {}, "1", 1},

  {"2002::4:5:6:7", LOWPAN_IPHC_AC_CONTEXT |  LOWPAN_IPHC_AM_64, 0, 8, {0,4,0,5,0,6,0,7}, "1", 1},

  {"::", LOWPAN_IPHC_AC_CONTEXT | LOWPAN_IPHC_AM_128, 0, 0, {}, "1", 1},
};

 int run_tests() {
  int i;
  int success = 0, total = 0;
  for (i = 0; i < (sizeof(test_cases) / sizeof(test_cases[0])); i++) {
    struct in6_addr addr, correct;
    uint8_t buf[512];
    char *rv;
    ieee154_addr_t l2addr;
    total++;

    inet_pton6(test_cases[i].address, &correct);

    ieee154_parse(test_cases[i].l2addr, &l2addr);
    ieee154_print(&l2addr, buf, 512);
    printf("%s\n", buf);
    printf("in6_addr: %s\n", test_cases[i].address);
    rv = unpack_address(&addr, test_cases[i].dispatch, test_cases[i].context,
                        test_cases[i].buf, &l2addr, test_cases[i].panid);

    inet_ntop6(&addr, buf, 512);
    printf("result: %s length: %li\n", buf, rv - test_cases[i].buf);

    if (test_cases[i].len != rv - test_cases[i].buf) {
      printf("case %u: result len: %li expected: %i\n",
             i, rv - test_cases[i].buf, test_cases[i].len);
      continue;
    }

    if (memcmp(&addr, &correct, 16) != 0) {
      printf("case %u: unexpected result\n", i);
      print_buffer(correct.s6_addr, 16);
      print_buffer(addr.s6_addr, 16);
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
