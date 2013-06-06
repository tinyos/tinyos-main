
#include <stdint.h>
#include <stdio.h>

#include "Ieee154.h"
#include "ip.h"
#include "lib6lowpan.h"
#include "nwbyte.h"
#include "6lowpan.h"

char *pack_tcfl(uint8_t *buf, struct ip6_hdr *hdr, uint8_t *dispatch) ;

struct {
  uint8_t  tc;
  uint32_t fl;

  /*  the result of executing the test case */
  int      result_len;
  uint8_t  result[4];
  int      result_dispatch;
} test_cases[] = {
  // no nothing
  {0, 0, 0, {}, LOWPAN_IPHC_TF_NONE},

  // one ecn bit
  {0x1, 0, 1, {0x40}, LOWPAN_IPHC_TF_ECN_DSCP},

  // both ecn bits
  {0x3, 0, 1, {0xc0}, LOWPAN_IPHC_TF_ECN_DSCP},

  // just DSCP
  {0xfc, 0, 1, {0x3f}, LOWPAN_IPHC_TF_ECN_DSCP},

  // flow label of one
  {0, 1, 3, {0, 0, 1}, LOWPAN_IPHC_TF_ECN_FL},

  // flow label + ECN tests
  {0, 0xfffff, 3, {0xf, 0xff, 0xff}, LOWPAN_IPHC_TF_ECN_FL},

  {3, 0xfffff, 3, {0xcf, 0xff, 0xff}, LOWPAN_IPHC_TF_ECN_FL},

  {1, 0xabcde, 3, {0x4a, 0xbc, 0xde}, LOWPAN_IPHC_TF_ECN_FL},

  // full thingie
  {0x4, 0x1, 4, {0x01, 0, 0, 1}, LOWPAN_IPHC_TF_ECN_DSCP_FL},

  {0x5, 0x1, 4, {0x41, 0, 0, 1}, LOWPAN_IPHC_TF_ECN_DSCP_FL},

  {0xab, 0xcdef6, 4, {0xea, 0xc, 0xde, 0xf6}, LOWPAN_IPHC_TF_ECN_DSCP_FL},

};

 int run_tests() {
  int i;
  int success = 0, total = 0;
  for (i = 0; i < (sizeof(test_cases) / sizeof(test_cases[0])); i++) {
    uint8_t buf[512], *rb;
    struct ip6_hdr hdr;
    uint8_t dispatch = 0;
    uint32_t val;
    total ++;
    scribble(buf, 512);

    val = htonl(0x6 << 28 | ((test_cases[i].tc & 0xff) << 20) | (test_cases[i].fl & 0x000fffff));
    hdr.ip6_flow = val;
    printf("input: 0x%x\n", ntohl(val));

    rb = pack_tcfl(buf, &hdr, &dispatch);
    printf("output length: %li dispatch: 0x%x\n", (rb -buf), dispatch);
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
