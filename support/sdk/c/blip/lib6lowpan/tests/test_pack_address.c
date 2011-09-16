
#include <stdint.h>
#include <stdio.h>

#include "Ieee154.h"
#include "ip.h"
#include "lib6lowpan.h"
#include "nwbyte.h"
#include "6lowpan.h"

char *pack_address(uint8_t *buf, struct in6_addr *addr, int context_match_len,
                   ieee154_addr_t *l2addr, ieee154_panid_t pan, uint8_t *flags);

struct {
  char *in6_addr;
  int   context_match_len;
  char *l2addr;
  ieee154_panid_t   panid;

  /*  the result of executing the test case */
  int      result_len;
  uint8_t  result[32];
  uint8_t      result_rv;
} test_cases[] = {
  // test the link-local address packing

  // non-RFC4944 address, never packed to less then 16 bits
  {"fe80::1", 0, "25", 0, 2, {0, 1}, LOWPAN_IPHC_AM_16},

  // LL address padded with zeroes, matching L2 address.  Not
  // compressed to zero because not RFC4944 style address
  {"fe80::1", 0, "1", 0, 2, {0, 1}, LOWPAN_IPHC_AM_16},

  // RFC4944 address, matching 16-bit id
  {"fe80::1:00ff:fe00:1", 0, "1", 1, 0, {0, 0}, LOWPAN_IPHC_AM_0},

  // RFC4944 address, matching 16-bit id
  {"fe80::fdff:00ff:fe00:1", 0, "1", 0xffff, 0, {0, 0}, LOWPAN_IPHC_AM_0},

  // RFC4944 address, different 16-bit ID
  {"fe80::1:00ff:fe00:2", 0, "1", 8, 8, {0, 1, 0, 0xff, 0xfe, 0x0, 0, 02}, LOWPAN_IPHC_AM_64},

  // matching with the L2 addr
  {"fe80::aabb:ccdd:eeff:0011", 0, "a8:bb:cc:dd:ee:ff:00:11", 
   8, 0, {}, LOWPAN_IPHC_AM_0},

  // matching 64-bit L2 addr, but prefix isn't all zero
  {"fe80::1:aabb:ccdd:eeff:0011", 0, "aa:bb:cc:dd:ee:ff:00:11", 
   8, 16, 
   {0xfe, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff, 0x00, 0x11}
   , LOWPAN_IPHC_AM_128},

  {"fe80::226:bbff:fe11:478b", 0, "00:26:bb:ff:fe:11:47:8c", 0,
   8, {0x2, 0x26, 0xbb, 0xff, 0xfe, 0x11, 0x47, 0x8b}, LOWPAN_IPHC_AM_64},
  // unspecified address
  {"::", 0, "12", 0, 0, {}, LOWPAN_IPHC_AM_128 | LOWPAN_IPHC_AC_CONTEXT},

  // context-based address compression

  // 64-bit prefix, short id
  {"2002::1", 64, "12", 1, 2, {0, 1}, LOWPAN_IPHC_AM_16 | LOWPAN_IPHC_AC_CONTEXT},

  {"2002::1:1", 64, "12", 1, 8, {0, 0,0,0,0,1,0,1}, LOWPAN_IPHC_AM_64 | LOWPAN_IPHC_AC_CONTEXT},

  {"2002::1:1", 112, "12", 1, 2, {0,1}, LOWPAN_IPHC_AM_16 | LOWPAN_IPHC_AC_CONTEXT},

  {"2002:1::1:1", 8, "12", 1, 16,
   {0x20, 0x02, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01},
   LOWPAN_IPHC_AM_128},

  {"2002::1:1", 128, "12", 1, 0, {0}, LOWPAN_IPHC_AM_0 | LOWPAN_IPHC_AC_CONTEXT},

  // global addresses, derived from L2.  
  // contiki packs this to zero bytes using the L2 info; however hc-06
  // is a little vague on this point so I don't do this.  We will win fact
  // decompress that right now.
  {"2002::226:bbff:fe11:478b", 64, "00:26:bb:ff:fe:11:47:8b", 1,
   8, {0x2, 0x26, 0xbb, 0xff, 0xfe, 0x11, 0x47, 0x8b}, LOWPAN_IPHC_AM_64 | LOWPAN_IPHC_AC_CONTEXT},
};

 int run_tests() {
  int i;
  int success = 0, total = 0;
  for (i = 0; i < (sizeof(test_cases) / sizeof(test_cases[0])); i++) {
    uint8_t flags;
    struct in6_addr addr;
    uint8_t buf[512], *rv;
    ieee154_addr_t l2addr;
    total++;

    inet_pton6(test_cases[i].in6_addr, &addr);
    ieee154_parse(test_cases[i].l2addr, &l2addr);
    ieee154_print(&l2addr, buf, 512);
    printf("%s\n", buf);
    printf("in6_addr: %s\n", test_cases[i].in6_addr);
    rv = pack_address(buf, &addr, test_cases[i].context_match_len, &l2addr, 
                      test_cases[i].panid, &flags);

    printf("flags: 0x%x(0x%x) len: %li\n", flags, test_cases[i].result_rv, rv - buf );
    print_buffer(buf, rv - buf);
    if (test_cases[i].result_len != (rv - buf)) {
      printf("case %u: result len failed expected: %i got: %li\n",
             i, test_cases[i].result_len, (rv - buf));
      continue;
    }
    if (test_cases[i].result_rv != flags) {
      printf("case %u: desired rv: 0x%x flags: %x\n",
             i, test_cases[i].result_rv, flags);
      continue;
    }
    if (memcmp(test_cases[i].result, buf, test_cases[i].result_len) != 0) {
      printf("case %u: buffers did not match\n", i);
      print_buffer(test_cases[i].result, test_cases[i].result_len);
      print_buffer(buf, test_cases[i].result_len);
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
