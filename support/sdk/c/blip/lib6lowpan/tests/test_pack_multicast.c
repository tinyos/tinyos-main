
#include <stdint.h>
#include <stdio.h>

#include "Ieee154.h"
#include "ip.h"
#include "lib6lowpan.h"
#include "nwbyte.h"
#include "6lowpan.h"

char *pack_multicast(char *buf, struct in6_addr *addr, uint8_t *flags);

struct {
  char *addr;

  /*  the result of executing the test case */
  int      result_len;
  uint8_t  result[16];
  int      result_dispatch;
} test_cases[] = {
  {"ff02::1", 1, {1}, LOWPAN_IPHC_AM_M_8},
  {"ff02::1:1111", 4, {0x02, 0x1, 0x11, 0x11}, LOWPAN_IPHC_AM_M_32},
  {"fff2::1:1111", 4, {0xf2, 0x1, 0x11, 0x11}, LOWPAN_IPHC_AM_M_32},
  {"fff2::1:fff1:1111", 6, {0xf2, 0x1, 0xff, 0xf1, 0x11, 0x11}, LOWPAN_IPHC_AM_M_48},
  {"fff2::1:fff1:1111", 6, {0xf2, 0x1, 0xff, 0xf1, 0x11, 0x11}, LOWPAN_IPHC_AM_M_48},
  {"fff2::f001:fff1:1111", 16, 
   {0xff, 0xf2, 0,0,0,0,0,0,0,0, 0xf0, 0x1, 0xff, 0xf1, 0x11, 0x11}, 
   LOWPAN_IPHC_AM_M_128},
};

 int run_tests() {
  int i;
  int success = 0, total = 0;
  for (i = 0; i < (sizeof(test_cases) / sizeof(test_cases[0])); i++) {
    uint8_t buf[512], *rb;
    struct in6_addr addr;
    uint8_t dispatch = 0;
    total ++;

    scribble(buf, 512);

    inet_pton6(test_cases[i].addr, &addr);
    printf("addr: %s\n", test_cases[i].addr);
    rb = pack_multicast(buf, &addr, &dispatch);
    print_buffer(buf, rb - buf);

    if (test_cases[i].result_len != (rb - buf)) 
      continue;

    if (memcmp(test_cases[i].result, buf, rb - buf) != 0)
      continue;

    if (test_cases[i].result_dispatch != dispatch)
      continue;
    
    printf("SUCCESS!\n");
    success++;    
  }
  printf("%s: %i/%i tests succeeded\n", __FILE__, success, total);
  if (success == total) return 0;
  return 1;
}

int main() {
  return run_tests();
}
