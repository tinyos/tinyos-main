
#include <stdint.h>
#include <stdio.h>

#include "Ieee154.h"
#include "ip.h"
#include "lib6lowpan.h"
#include "nwbyte.h"
#include "6lowpan.h"
#include "internal.h"



struct {
  uint32_t result;
  /*  the result of executing the test case */
  uint8_t  test_dispatch;
  int      test_len;
  uint8_t  test[4];
} test_cases[] = {
  {0x60000000, LOWPAN_IPHC_TF_NONE, 0, {}},
  {0x60000000, LOWPAN_IPHC_TF_NONE | ~LOWPAN_IPHC_TF_MASK, 0, {}},

  // ECN bit
  {0x60100000, LOWPAN_IPHC_TF_ECN_DSCP, 1, {0x40}},

  // ecn and DSCP
  {0x6ab00000, LOWPAN_IPHC_TF_ECN_DSCP, 1, {0xea}},

  // ECN + FL
  {0x60301234, LOWPAN_IPHC_TF_ECN_FL, 3, {0xc0, 0x12, 0x34}},

  // full
  {0x6f012345, LOWPAN_IPHC_TF_ECN_DSCP_FL, 4, {0x3c, 0x01, 0x23, 0x45}},
};

int run_tests() {
  int i;
  int success = 0, total = 0;
  for (i = 0; i < (sizeof(test_cases) / sizeof(test_cases[0])); i++) {
    struct ip6_hdr hdr;
    int rb;
    uint8_t *bptr = test_cases[i].test;
    size_t len = 4;;

    total ++;

    rb = unpack_tcfl(&hdr,
                     test_cases[i].test_dispatch,
                     &bptr,
                     &len);
    printf("result: 0x%x correct: 0x%x\n", ntohl(hdr.ip6_flow), test_cases[i].result);

    printf("length: %li\n", 4-len);

    if (test_cases[i].test_len !=  4-len)
      continue;

    if (test_cases[i].result != ntohl(hdr.ip6_flow))
      continue;

    success ++;
  }
  printf("%s: %i/%i tests succeeded\n", __FILE__, success, total);
  if (success == total) return 0;
  return 1;
}

int main() {
  return run_tests();
}
